import fetch from 'node-fetch';
global.fetch = fetch;

require("dotenv").config();
import { loadWasm } from "candb-client-typescript/dist/ClientUtil";
import { idlFactory as canDBIndexIdl } from "../src/declarations/CanDBIndex";
import { Actor, HttpAgent } from '@dfinity/agent';
import { decodeFile } from './lib/key';

const isLocal = process.env.DFX_NETWORK !== "ic";

async function upgradePartitions() {
    const serviceWasmModulePath = `CanDBPartition.wasm`
    const serviceWasm = loadWasm(serviceWasmModulePath);

    const identity = decodeFile(process.env.HOME+"/.config/dfx/identity/default/identity.pem");

    const agent = new HttpAgent({host: isLocal ? "http://localhost:8000" : "https://icp-api.io", identity});
    if (isLocal) {
      agent.fetchRootKey();
    }
    const CanDBIndex = Actor.createActor(canDBIndexIdl, {agent, canisterId: process.env.CANISTER_ID_CANDBINDEX!});
    try {
      const upgradeResult = await CanDBIndex.upgradeAllPartitionCanisters(serviceWasm);
      console.log("result", JSON.stringify(upgradeResult));
    } catch (e) {
      console.log("Error upgrading: " + e);
      process.exit(1);
    }

    console.log("upgrade complete")
};

upgradePartitions();