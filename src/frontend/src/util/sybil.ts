import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";
import { initializeCanDBPartitionClient, initializeMainClient, intializeCanDBIndexClient } from "./client";
import { Principal } from "@dfinity/principal";

// FIXME: correct?
function getCookie(name: string): string | undefined {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
}

// TODO: Updating the cookie if it is from a previous alpha/beta.
// Obtain Sybil canister, possibly creating a new user identity.
// FIXME: Check that this is not in an infinite loop, if user has no phone.
export async function obtainSybilCanister() {
    const cookie = getCookie('sybilCanister');
    if (cookie !== undefined) {
        return cookie;
    }

    const isLocal = true; // TODO
    const canDBIndexClient = intializeCanDBIndexClient(isLocal);
    const canDBPartitionClient = initializeCanDBPartitionClient(isLocal, canDBIndexClient);
    for(;;) {
        let sybilResults = await canDBPartitionClient.query<CanDBPartition["get"]>( // FIXME
            "", // pk, // FIXME
            (actor) => actor.get({sk: "s/username"}), // FIXME
        );
        let search = () => {
            for (let settledResult of sybilResults) {
                // handle settled result if fulfilled
                if (settledResult.status === "fulfilled" && settledResult.value.length > 0) {
                    return settledResult.value[0]; // opt ...
                } 
            }
        };
        let sybilResult = search();
        if (sybilResults === undefined) {
            const isLocal = true; // FIXME
            const canisters = await canDBIndexClient.getCanistersForPK("x"); // FIXME: PK
            const lastCanister = canisters[canisters.length - 1];
            const backend = initializeMainClient(isLocal);
            await backend.verifyUser(Principal.fromText(lastCanister));
        } else {
            const date = new Date(2147483647 * 1000).toUTCString();
            document.cookie = `sybilCanister=${sybilResult.pk}; expires=${date}; path=/`;
            break;
        }
    }
}