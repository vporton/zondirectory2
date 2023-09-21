import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";
import { initializeCanDBPartitionClient, initializeMainClient, intializeCanDBIndexClient } from "./client";
import { Principal } from "@dfinity/principal";
import { AuthClient } from "@dfinity/auth-client";

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

    const canDBIndexClient = intializeCanDBIndexClient();
    const canDBPartitionClient = initializeCanDBPartitionClient(canDBIndexClient);
    const authClient = await AuthClient.create();
    const principal = authClient.getIdentity().getPrincipal().toText();
    for(;;) {
        let sybilResults = await canDBPartitionClient.query<CanDBPartition["get"]>(
            "sybil", // pk,
            actor => actor.get({sk: "s/" + principal}),
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
            const canisters = await canDBIndexClient.getCanistersForPK("sybil");
            const lastCanister = canisters[canisters.length - 1];
            const backend = initializeMainClient();
            await backend.verifyUser(Principal.fromText(lastCanister));
        } else {
            const date = new Date(2147483647 * 1000).toUTCString();
            document.cookie = `sybilCanister=${sybilResult.pk}; expires=${date}; path=/`;
            break;
        }
    }
}