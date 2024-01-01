import { Principal } from "@dfinity/principal";
import { Item, Streams } from "../../../declarations/CanDBPartition/CanDBPartition.did"
import { Actor, Agent, HttpAgent } from "@dfinity/agent";
import { createActor as nacDBPartitionActor } from "../../../declarations/NacDBPartition";
import { createActor as canDBPartitionActor } from "../../../declarations/CanDBPartition";

const STREAM_LINK_SUBITEMS = 0; // category <-> sub-items
const STREAM_LINK_SUBCATEGORIES = 1; // category <-> sub-categories
const STREAM_LINK_COMMENTS = 2; // item <-> comments
// const STREAM_LINK_MAX = STREAM_LINK_COMMENTS;

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

function _unwrap(v) {
    // TODO: simplify for greater performance
    return v === undefined || v.length === 0 ? undefined : v[0];
}

export class ItemData {
    agent?: Agent; // should be `defaultAgent`
    itemRef: ItemRef;
    item: Item;
    streams: Streams | undefined;
    streamsRev: Streams | undefined;
    protected constructor(agent: Agent, itemId: string) {
        this.agent = agent;
        this.itemRef = parseItemRef(itemId);
    }
    /// `"t" | "v" | "p"` - time, votes, or paid.
    static async create(agent: Agent, itemId: string, kind: "t" | "v" | "p"): Promise<ItemData> {
        const obj = new ItemData(agent, itemId);
        const client = canDBPartitionActor(obj.itemRef.canister);
        // TODO: Retrieve both by one call?
        const [item, streams, streamsRev] = await Promise.all([
            client.getItem(BigInt(obj.itemRef.id)),
            client.getStreams(BigInt(obj.itemRef.id), kind),
            client.getStreams(BigInt(obj.itemRef.id), "r" + kind),
        ]) as [Item[] | [], Streams[] | [], Streams[] | []];
        console.log("ITEM", item)
        // const item = await client.getItem(BigInt(obj.itemRef.id)) as any;
        // const streams = await client.getStreams(BigInt(obj.itemRef.id)) as any;
        obj.item = item[0]; // TODO: if no such item
        obj.streams = _unwrap(streams);
        obj.streamsRev = _unwrap(streamsRev);
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
            [[string, {text: string}]] | [];
        const items1aa = items.length === 0 ? [] : items.map(x => [x[0], x[1].text]);
        const items1a: [string, string, bigint][] = items1aa.map(x => ((s) => {
            const m = s[1].match(/^([0-9]*)@(.*)$/);
            return [s[0], m[2], BigInt(m[1])];
        })(x));
        const items2 = items1a.map(([order, principalStr, id]) => { return {canister: Principal.from(principalStr), id, order} });
        const items3 = items2.map(id => (async () => {
            const part = canDBPartitionActor(id.canister, { agent: this.agent });
            return [id.order, id, await part.getItem(id.id)];
        })());
        const items4: any = await Promise.all(items3);
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
        if (this.streams === undefined || _unwrap(this.streams[STREAM_LINK_SUBCATEGORIES]) === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = _unwrap(this.streams[STREAM_LINK_SUBCATEGORIES]).order;
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async superCategories(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streamsRev === undefined) {
            return [];
        }
        const stream = (this.item.item.details as any).ownedCategory !== undefined || (this.item.item.details as any).communalCategory !== undefined
            ? _unwrap(this.streamsRev[STREAM_LINK_SUBCATEGORIES]) : _unwrap(this.streamsRev[STREAM_LINK_SUBITEMS]);
        if (stream === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = stream.order;
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async items(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streams === undefined || _unwrap(this.streams[STREAM_LINK_SUBITEMS]) === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = _unwrap(this.streams[STREAM_LINK_SUBITEMS]).order;
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async comments(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streams === undefined || _unwrap(this.streams[STREAM_LINK_COMMENTS]) === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = _unwrap(this.streams[STREAM_LINK_COMMENTS]).order
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
    async antiComments(opts?: {lowerBound?: string, limit?: number}) {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (this.agent === undefined) {
            return undefined;
        }
        if (this.streamsRev === undefined || _unwrap(this.streamsRev[STREAM_LINK_COMMENTS]) === undefined) {
            return [];
        }
        const [outerCanister, outerKey] = _unwrap(this.streamsRev[STREAM_LINK_COMMENTS]).order
        return await this.aList(outerCanister, outerKey, {lowerBound, limit})
    }
}
