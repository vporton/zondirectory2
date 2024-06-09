import { idlFactory as itemsIdlFactory } from "../../../declarations/items";
import { _SERVICE as Orders } from "../../../declarations/order/order.did";
import { Actor, Agent } from "@dfinity/agent";
import { getIsLocal } from "./client";
import { ItemId } from './types';
import { Principal } from "@dfinity/principal";
import { ItemRef, parseItemRef } from "../data/Data";

export async function addToFolder(agent: Agent, catId: ItemRef, itemId: ItemRef, comment: boolean, side: 'beginning' | 'end') {
    const itemsClient: Orders = Actor.createActor(itemsIdlFactory, {canisterId: process.env.CANISTER_ID_ITEMS!, agent});
    const side2 = side === 'beginning' ? {beginning: null} : {end: null};
    await itemsClient.addItemToFolder(
        [catId.canister, BigInt(catId.id)],
        [itemId.canister, BigInt(itemId.id)],
        comment,
        side2,
    );
}

// TODO: Change `string[]` argument type
export async function addToMultipleFolders(agent: Agent, cats: [string, 'beginning' | 'end'][], itemId: ItemRef, comment: boolean) {
    for (const folder of cats) {
        await addToFolder(agent, parseItemRef(folder[0]), itemId, comment, folder[1]); // TODO: It may fail to parse.
    }
}