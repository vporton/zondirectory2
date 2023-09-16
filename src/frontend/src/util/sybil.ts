import { ActorClient } from "candb-client-typescript/dist/ActorClient";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { CanDBIndex } from "../../../declarations/CanDBIndex/CanDBIndex.did";

// FIXME: correct?
function getCookie(name: string): string | undefined {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
}

// TODO: Updating the cookie if it is from a previous alpha/beta.
export async function sybilCanister() {
    const cookie = getCookie('sybilCanister');
    if (cookie !== undefined) {
        return cookie;
    }

    // TODO
    const canDBPartitionClient: ActorClient<CanDBIndex, CanDBPartition> = TODO;
    let sybilResults = await canDBPartitionClient.query<CanDBPartition["greetUser"]>( // FIXME
        pk,
        (actor) => actor.greetUser(name)
      );
    
}