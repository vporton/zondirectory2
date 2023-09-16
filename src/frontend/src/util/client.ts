import { IndexClient } from "candb-client-typescript/dist/IndexClient";
import { ActorClient } from "candb-client-typescript/dist/ActorClient";

import { idlFactory as CanDBIndexIDL } from "../../../declarations/CanDBIndex/index";
import { idlFactory as CanDBPartitionIDL } from "../../../declarations/CanDBPartition/index";
import { idlFactory as MainIDL } from "../../../declarations/backend/index";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";
import { ZonBackend } from "../../../declarations/backend/backend.did";
import { Actor, HttpAgent } from "@dfinity/agent";

export function intializeCanDBIndexClient(isLocal: boolean): IndexClient<CanDBIndex> {
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

export function initializeCanDBPartitionClient(isLocal: boolean, indexClient: IndexClient<CanDBIndex>)
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

export function initializeMainClient(isLocal: boolean)
{
  const host = isLocal ? "http://127.0.0.1:8000" : "https://ic0.app";
  const agent = new HttpAgent({ host });
  const canisterId = isLocal ? process.env.MAIN_CANISTER_ID : "<prod_canister_id>"; // TODO
  return Actor.createActor(MainIDL, { agent, canisterId });
};