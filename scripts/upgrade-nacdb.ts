global.fetch = require('node-fetch');
global.fetch = fetch;

require("dotenv").config();
import { loadWasm } from "candb-client-typescript/dist/ClientUtil";
import { idlFactory as nacDBIndexIdl } from '../src/declarations/NacDBIndex';
import { _SERVICE as NacDBIndex } from "../src/declarations/NacDBIndex/NacDBIndex.did";
import { Actor, HttpAgent } from "@dfinity/agent";
import { decodeFile } from "./lib/key";
import { exec } from 'child_process';

const isLocal = process.env.DFX_NETWORK !== "ic";

// const MANAGEMENT_CANISTER_ID = Principal.fromText('aaaaa-aa');

function commandOutput(command): Promise<string> {
  return new Promise((resolve) => exec(command, function(error, stdout, stderr){ resolve(stdout); }));
}

async function upgradePartitions() {
    const net = process.argv[2];
    const serviceWasmModulePath = `.dfx/${net}/canisters/NacDBPartition/NacDBPartition.wasm`;
    const serviceWasm = loadWasm(serviceWasmModulePath);

    const key = await commandOutput("dfx identity export Zon");
    const identity = decodeFile(key);

    const agent = new HttpAgent({host: isLocal ? "http://localhost:8000" : "https://icp-api.io", identity});
    if (isLocal) {
      agent.fetchRootKey();
    }
    const nacDBIndex: NacDBIndex = Actor.createActor(nacDBIndexIdl, {agent, canisterId: process.env.CANISTER_ID_NACDBINDEX!});
    // await nacDBIndex.upgradeAllPartitionCanisters(serviceWasm);
    const partitions = await nacDBIndex.getCanisters();
    // const MANAGEMENT_CANISTER_ID = 'aaaaa-aa';
    // const ic = Actor.createActor(icIdlFactory, {agent, canisterId: MANAGEMENT_CANISTER_ID});
    const BATCH_SIZE = 5;
    try {
      for (let i = 0; i < partitions.length; i += BATCH_SIZE) {
          await nacDBIndex.upgradeCanistersInRange(serviceWasm, BigInt(i), BigInt(Math.min(i+BATCH_SIZE, partitions.length)));
      }
    } catch (e) {
      console.log("Error upgrading: " + e);
      process.exit(1);
    }
    // for (const part of partitions) {
    //     await ic.install_code({
    //         arg: [],
    //         wasm_module: serviceWasm,
    //         mode: { upgrade: null },
    //         canister_id: part,
    //     });
    // }

    console.log("upgrade complete")
};

upgradePartitions();