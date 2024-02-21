import { createActor as orderActor } from "../../../declarations/order";
import { Actor, Agent } from "@dfinity/agent";
import { getIsLocal } from "./client";
import { ItemId } from './types';
import { Principal } from "@dfinity/principal";
import { ItemRef, parseItemRef } from "../data/Data";

export async function addToFolder(agent: Agent, catId: ItemRef, itemId: ItemRef, comment: boolean, side: {beginning: null} | {end: null}) {
    const orderClient = orderActor(process.env.CANISTER_ID_ORDER, {agent});
    await orderClient.addItemToFolder(
        [catId.canister, BigInt(catId.id)],
        [itemId.canister, BigInt(itemId.id)],
        comment,
        side,
    );
}

// TODO: Change `string[]` argument type
export async function addToMultipleFolders(agent: Agent, cats: [string, {beginning: null} | {end: null}][], itemId: ItemRef, comment: boolean) {
    for (const cat of cats) {
        await addToFolder(agent, parseItemRef(cat[0]), itemId, comment, cat[1]); // TODO: It may fail to parse.
    }
}