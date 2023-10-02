import { Principal } from "@dfinity/principal";
import { Item, Streams } from "../../../declarations/CanDBPartition/CanDBPartition.did"
import { initializeDirectCanDBPartitionClient, initializeDirectNacDBPartitionClient } from "../util/client";
import { Actor, Agent, HttpAgent } from "@dfinity/agent";
import { idlFactory as NacDBPartitionIDL } from "../../../declarations/NacDBPartition";
import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition";
import { AuthClient } from "@dfinity/auth-client";

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
    agent: Agent; // should be `defaultAgent`
    itemRef: ItemRef;
    item: Item;
    streams: Streams | undefined;
    protected constructor(agent: Agent, itemId: string) {
        this.agent = agent;
        this.itemRef = parseItemRef(itemId);
    }
    static async create(agent: Agent, itemId: string): Promise<ItemData> {
        const obj = new ItemData(agent, itemId);
        const client = initializeDirectCanDBPartitionClient(obj.itemRef.canister);
        // TODO: Retrieve both by one call?
        const [item, streams] = await Promise.all([
            client.getItem(obj.itemRef.id),
            client.getStreams(obj.itemRef.id),
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
    // FIXME below
    // FIXME: For non-folders, no distinction between `subCategories` and `items` (or better no subcategories?)
    async subCategories() {
        if (!this.agent) { // FIXME
            return [];
        }
        // TODO: duplicate code
        if (this.streams === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.categoriesTimeOrderSubDB;
        
        const client = Actor.createActor(NacDBPartitionIDL, { // TODO
            agent: this.agent,
            canisterId: outerCanister,
        });

        const items = ((await client.scanLimitOuter({outerKey, lowerBound: "", upperBound: "x", dir: {fwd: null}, limit: BigInt(10)})) as any).results as // TODO: limit
            Array<[any, number]>; // FIXME: correct type?
        const items1a = items.map((x: any) => [x[1].tuple[0].text, x[1].tuple[1].int]);
        const items2 = items1a.map(([principalStr, id]) => { return {canister: Principal.from(principalStr), id: id} });
        const items3 = items2.map(id => (async () => {
            const part = Actor.createActor(CanDBPartitionIDL, { // TODO
                agent: this.agent,
                canisterId: id.canister,
            });
            return [id, await part.getItem(id.id)];
        })());
        const items4: any = (await Promise.all(items3)); // TODO: correct?
        return items4.map(([id, item]) => {
            return {
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
    async superCategories() { // TODO
        return [
            {id: 1, locale: "en", title: "All the World", type: 'public'},
            {id: 4, locale: "en", title: "John's notes", type: 'private', description: "John writes about everything, including the content of The Homepage."},
        ];
    }
    async items() {
        // TODO: duplicate code
        if (this.streams === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.itemsTimeOrderSubDB
        const client = Actor.createActor(NacDBPartitionIDL, { // TODO
            agent: this.agent,
            canisterId: outerCanister,
        });
        const items = ((await client.scanLimitOuter({outerKey, lowerBound: "", upperBound: "x", dir: {fwd: null}, limit: BigInt(10)})) as any).results as // TODO: limit
            Array<[any, number]>; // FIXME: correct type?
        const items1a = items.map((x: any) => [x[1].tuple[0].text, x[1].tuple[1].int]);
        const items2 = items1a.map(([principalStr, id]) => { return {canister: Principal.from(principalStr), id: id} });
        const items3 = items2.map(id => (async () => {
            const part = Actor.createActor(CanDBPartitionIDL, { // TODO
                agent: this.agent,
                canisterId: id.canister,
            });
            return [id, await part.getItem(id.id)];
        })());
        const items4: any = (await Promise.all(items3)); // TODO: correct?
        return items4.map(([id, item]) => {
            return {
                id,
                locale: item[0].item.locale,
                title: item[0].item.title,
                description: item[0].item.description,
                type: 'public', // FIXME
            }
        });
    }
}
