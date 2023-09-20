import { initializeCanDBPartitionClient, intializeCanDBIndexClient } from "./client";
import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition/index";
import { Actor, HttpAgent } from "@dfinity/agent";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { obtainSybilCanister } from "./sybil";
import { getIsLocal } from "./client";

export async function addToCategory() {
    const host = getIsLocal() ? "http://127.0.0.1:8000" : "https://ic0.app";
    const agent = new HttpAgent({ host });

    const canDBIndexClient = intializeCanDBIndexClient();
    // const canDBPartitionClient = initializeCanDBPartitionClient(canDBIndexClient);

    const canistersResult = (await canDBIndexClient.indexCanisterActor.getCanistersByPK("main"));
    const canisterId = canistersResult[canistersResult.length - 1];
    // const partition = Actor.createActor(CanDBPartitionIDL, { agent, canisterId });
    
    const sybilCanister = obtainSybilCanister();

    main.
}