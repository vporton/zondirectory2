import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";
import { initializeCanDBPartitionClient, initializeMainClient, intializeCanDBIndexClient } from "./client";
import { Principal } from "@dfinity/principal";
import { AuthClient } from "@dfinity/auth-client";
