import fetch from 'node-fetch';
global.fetch = fetch;

require("dotenv").config();
import { loadWasm } from "candb-client-typescript/dist/ClientUtil";
import { idlFactory as canDBIndexIdl } from '../src/declarations/CanDBIndex';
import { Actor, HttpAgent } from '@dfinity/agent';
import { decodeFile } from './lib/key';
import { exec } from 'child_process';

const isLocal = process.env.DFX_NETWORK !== "ic";

function commandOutput(command): Promise<string> {
    return new Promise((resolve) => exec(command, function(error, stdout, stderr){ resolve(stdout); }));
}

async function upgradePartitions() {
    const net = process.argv[2];
    const serviceWasmModulePath = `.dfx/${net}/canisters/CanDBPartition/CanDBPartition.wasm`;
    const serviceWasm = loadWasm(serviceWasmModulePath);

    const key = await commandOutput("dfx identity export Zon");
    const identity = decodeFile(key);

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