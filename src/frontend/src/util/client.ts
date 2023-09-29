import { IndexClient } from "candb-client-typescript/dist/IndexClient";
import { ActorClient } from "candb-client-typescript/dist/ActorClient";

import { idlFactory as CanDBIndexIDL } from "../../../declarations/CanDBIndex";
import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition";
import { idlFactory as NacDBPartitionIDL } from "../../../declarations/NacDBPartition";
import { main as MainCanister } from "../../../declarations/main";
import { order as OrderCanister } from "../../../declarations/order";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBPartition as CanDBPartitionCanister } from "../../../declarations/CanDBPartition";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";
// import { CanDBIndex as CanDBIndexCanister } from "../../../declarations/CanDBIndex";
import { Actor, HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";

export function getIsLocal() {
  return process.env.REACT_APP_IS_LOCAL === "1";
}

const isLocal = getIsLocal();

export function intializeCanDBIndexClient(): IndexClient<CanDBIndex> {
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  const canisterId = isLocal ? process.env.INDEX_CANISTER_ID : "<prod_canister_id>"; // TODO
  return new IndexClient<CanDBIndex>({
    IDL: CanDBIndexIDL,
    canisterId, 
    agentOptions: {
      host,
    },
  });
};

// TODO: Also partition client for a single canister.
export function initializeCanDBPartitionClient(indexClient: IndexClient<CanDBIndex>)
    : ActorClient<CanDBIndex, CanDBPartition>
{
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  return new ActorClient<CanDBIndex, CanDBPartition>({
    actorOptions: {
      IDL: CanDBPartitionIDL,
      agentOptions: {
        host,
      }
    },
    indexClient, 
  });
};

export function initializeDirectCanDBPartitionClient(canisterId: Principal)
{
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  const agent = new HttpAgent({ host });
  return Actor.createActor(CanDBPartitionIDL, { agent, canisterId });
};

export function initializeDirectNacDBPartitionClient(canisterId: Principal)
{
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  const agent = new HttpAgent({ host });
  return Actor.createActor(NacDBPartitionIDL, { agent, canisterId });
};

export function initializeMainClient()
{
  // const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  // const agent = new HttpAgent({ host });
  // const canisterId = process.env.CANISTER_ID_MAIN;
  // return Actor.createActor(MainPartitionIDL, { agent, canisterId });
  return MainCanister; // FIXME: Use this instead.
};

export function initializeOrderClient()
{
  return OrderCanister;
};