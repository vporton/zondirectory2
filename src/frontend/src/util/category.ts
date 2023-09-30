import { initializeOrderClient } from "./client";
// import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition/index";
import { Actor, HttpAgent } from "@dfinity/agent";
import { getIsLocal } from "./client";
import { ItemId } from './types';
import { Principal } from "@dfinity/principal";
import { ItemRef, parseItemRef } from "../data/Data";

export async function addToCategory(catId: ItemRef, itemId: ItemRef) {
    const orderClient = initializeOrderClient();
    await orderClient.addItemToCategory(
        [catId.canister, BigInt(catId.id)],
        [itemId.canister, BigInt(itemId.id)],
    );
}

// TODO: Change argument type
export async function addToMultipleCategories(cats: string[], itemId: ItemRef) {
    for (const catStr of cats) {
        await addToCategory(parseItemRef(catStr), itemId); // TODO: It may fail to parse.
    }
}