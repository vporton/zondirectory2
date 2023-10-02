import { createActor as orderActor } from "../../../declarations/order";
import { Actor, Agent } from "@dfinity/agent";
import { getIsLocal } from "./client";
import { ItemId } from './types';
import { Principal } from "@dfinity/principal";
import { ItemRef, parseItemRef } from "../data/Data";

export async function addToCategory(agent: Agent, catId: ItemRef, itemId: ItemRef) {
    const orderClient = orderActor(process.env.CANISTER_ID_ORDER, {agent});
    await orderClient.addItemToCategory(
        [catId.canister, BigInt(catId.id)],
        [itemId.canister, BigInt(itemId.id)],
    );
}

// TODO: Change `string[]` argument type
export async function addToMultipleCategories(agent: Agent, cats: string[], itemId: ItemRef) {
    for (const catStr of cats) {
        await addToCategory(agent, parseItemRef(catStr), itemId); // TODO: It may fail to parse.
    }
}