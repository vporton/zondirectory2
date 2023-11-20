import { Principal } from "@dfinity/principal";
import { Item, Streams } from "../../../declarations/CanDBPartition/CanDBPartition.did"
import { Actor, Agent, HttpAgent } from "@dfinity/agent";
import { createActor as nacDBPartitionActor } from "../../../declarations/NacDBPartition";
import { createActor as canDBPartitionActor } from "../../../declarations/CanDBPartition";

export type ItemRef = {
    canister: Principal;
    id: number;
};

// TODO: This and the following functions probably should be not here.
export function parseItemRef(itemId: string): ItemRef {
    const a = itemId.split('@', 2);
    return {canister: Principal.fromText(a[1]), id: parseInt(a[0])};
}

export function serializeItemRef(item: ItemRef): string {
    return item.id + "@" + item.canister;
}

export class ItemData {
    agent?: Agent; // should be `defaultAgent`
    itemRef: ItemRef;
    item: Item;
    streams: Streams | undefined;
    protected constructor(agent: Agent, itemId: string) {
        this.agent = agent;
        this.itemRef = parseItemRef(itemId);
    }
    static async create(agent: Agent, itemId: string): Promise<ItemData> {
        const obj = new ItemData(agent, itemId);
        // console.log(obj)
        const client = canDBPartitionActor(obj.itemRef.canister);
        // TODO: Retrieve both by one call?
        const [item, streams] = await Promise.all([
            client.getItem(BigInt(obj.itemRef.id)),
            client.getStreams(BigInt(obj.itemRef.id)),
        ]) as [Item[] | [], Streams[] | []];
        // const item = await client.getItem(BigInt(obj.itemRef.id)) as any;
        // const streams = await client.getStreams(BigInt(obj.itemRef.id)) as any;
        obj.item = item[0]; // TODO: if no such item
        obj.streams = streams.length !== 0 ? streams[0] : undefined;
        return obj;
    }
    async locale() {
        return this.item.item.locale;
    }
    async title() {
        return this.item.item.title;
    }
    async description() {
        return this.item.item.description;
    }
    async details() {
        return this.item.item.details;
    }
    async creator() {
        return this.item.creator;
    }
    async postText() {
        const client = canDBPartitionActor(this.itemRef.canister);
        const t = (await client.getAttribute({sk: "i/" + this.itemRef.id}, "t") as any)[0]; // TODO: error handling
        return t === undefined ? undefined : Object.values(t)[0];
    }
    private async aList(outerCanister, outerKey, opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        const client = nacDBPartitionActor(outerCanister, { agent: this.agent });
        const [innerPart, innerKey] = (await client.getInner(outerKey) as any)[0]; // TODO: error handling
        const client2 = nacDBPartitionActor(innerPart, { agent: this.agent });
        const items = ((await client2.scanLimitInner({innerKey, lowerBound, upperBound: "x", dir: {fwd: null}, limit: BigInt(limit)})) as any).results as // TODO: limit
            Array<[any, number]>; // TODO: correct type?
        const items1a = items.map((x: any) => [x[0], x[1].tuple[0].text, x[1].tuple[1].int]);
        const items2 = items1a.map(([order, principalStr, id]) => { return {canister: Principal.from(principalStr), id, order} });
        const items3 = items2.map(id => (async () => {
            const part = canDBPartitionActor(id.canister, { agent: this.agent });
            return [id.order, id, await part.getItem(id.id)];
        })());
        const items4: any = (await Promise.all(items3));
        return items4.map(([order, id, item]) => {
            return {
                order,
                id,
                locale: item[0].item.locale,
                title: item[0].item.title,
                description: item[0].item.description,
                item: { // TODO: BAD hack
                    details: item[0].item.details,
                },
            }
        });
    }
    async subCategories(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streams === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.categoriesTimeOrder;
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async superCategories(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streams === undefined) {
            return [];
        }
        const [outerCanister, outerKey] =
            (this.item.item.details as any).ownedCategory !== null || (this.item.item.details as any).communalCategory !== null
            ? this.streams.categoriesInvTimeOrder : this.streams.itemsInvTimeOrder;
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async items(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streams === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.itemsTimeOrder
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
}
