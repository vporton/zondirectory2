import { initializeCanDBPartitionClient, intializeCanDBIndexClient, initializeMainClient, initializeOrderClient } from "./client";
import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition/index";
import { Actor, HttpAgent } from "@dfinity/agent";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { getIsLocal } from "./client";
import { ItemId } from './types';

export async function addToCategory(catId: ItemId, itemId: ItemId) {
    const orderClient = initializeOrderClient();
    await orderClient.addToCategory([catId.partition, catId.id], [itemId.partition, itemId.id]);
}