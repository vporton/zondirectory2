import { initializeOrderClient } from "./client";
// import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition/index";
import { Actor, HttpAgent } from "@dfinity/agent";
import { getIsLocal } from "./client";
import { ItemId } from './types';
import { Principal } from "@dfinity/principal";

export async function addToCategory(catId: ItemId, itemId: ItemId) {
    const orderClient = initializeOrderClient();
    await orderClient.addItemToCategory(
        [Principal.fromText(catId.partition), BigInt(catId.id)],
        [Principal.fromText(itemId.partition), BigInt(itemId.id)],
    );
}