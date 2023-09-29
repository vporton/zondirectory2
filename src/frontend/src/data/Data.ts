import { Principal } from "@dfinity/principal";
import { Item, Streams } from "../../../declarations/CanDBPartition/CanDBPartition.did"
import { initializeDirectCanDBPartitionClient, initializeDirectNacDBPartitionClient } from "../util/client";
import { Actor } from "@dfinity/agent";

type ItemRef = {
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
    itemRef: ItemRef;
    item: Item;
    streams: Streams | undefined;
    protected constructor(itemId: string) {
        this.itemRef = parseItemRef(itemId);
    }
    static async create(itemId: string): Promise<ItemData> {
        const obj = new ItemData(itemId);
        const client = initializeDirectCanDBPartitionClient(obj.itemRef.canister);
        // TODO: Retrieve both by one call?
        // FIXME: Use this:
        // [obj.item, obj.streams] = await Promise.all([
        //     client.getItem(obj.itemRef.id),
        //     client.getStreams(obj.itemRef.id),
        // ]) as [Item, Streams] | undefined;
        const item = await client.getItem(BigInt(obj.itemRef.id)) as any;
        console.log('QQ', item);
        obj.item = item
        obj.streams = await client.getStreams(BigInt(obj.itemRef.id)) as any;
        return obj;
    }
    locale() {
        return this.item.item.locale;
    }
    title() {
        return this.item.item.title;
    }
    description() {
        return this.item.item.description;
    }
    // FIXME below
    // FIXME: For non-folders, no distinction between `subCategories` and `items` (or better no subcategories?)
    async subCategories() {
        // TODO: duplicate code
        if (this.streams === null) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.categoriesTimeOrderSubDB;
        const client = initializeDirectNacDBPartitionClient(Actor.canisterIdOf(outerCanister as unknown as Actor)); // FIXME: https://github.com/dfinity/agent-js/issues/775
        const items = await client.scanLimitOuter({outerKey, lowerBound: "", upperBound: "x", dir: 'fwd', limit: 10}) as // TODO: limit
            Array<[string, number]>; // FIXME: correct type?
        const items2 = items.map(([principalStr, id]) => { return {canister: Principal.from(principalStr), id: id} });
        const items3 = items2.map(id => async () => [id, await client.getItem(id)]);
        const items4 = (await Promise.all(items3)) as unknown as [number, Item][]; // TODO: correct?
        return items4.map(([id, item]) => {
            return {
                id,
                locale: item.item.locale,
                title: item.item.title,
                description: item.item.description,
                type: 'public', // FIXME
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
        if (this.streams === null) {
            return [];
        }
        const [outerCanister, outerKey] = this.streams.categoriesTimeOrderSubDB
        const client = initializeDirectNacDBPartitionClient(Actor.canisterIdOf(outerCanister as unknown as Actor)); // FIXME: https://github.com/dfinity/agent-js/issues/775
        const items = await client.scanLimitOuter({outerKey, lowerBound: "", upperBound: "x", dir: 'fwd', limit: 10}) as // TODO: limit
            Array<[string, number]>; // FIXME: correct type?
        const items2 = items.map(([principalStr, id]) => { return {canister: Principal.from(principalStr), id: id} });
        const items3 = items2.map(id => async () => [id, await client.getItem(id)]);
        const items4 = (await Promise.all(items3)) as unknown as [number, Item][]; // TODO: correct?
        return items4.map(([id, item]) => {
            return {
                id,
                locale: item.item.locale,
                title: item.item.title,
                description: item.item.description,
            }
        })
    }
}
