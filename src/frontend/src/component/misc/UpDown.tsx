import React, { useContext, useState } from "react";
import { Item } from "../../../../declarations/CanDBPartition/CanDBPartition.did";
import { AuthContext } from "../auth/use-auth-client";
import { ItemRef, loadTotalVotes, loadUserVote, parseItemRef, serializeItemRef } from "../../data/Data";
import { createActor as orderActor } from "../../../../declarations/order";
import { AppData } from "../../DataDispatcher";
import { Agent } from "@dfinity/agent";
import Button from "react-bootstrap/esm/Button";

export default function UpDown(props: {
    streamKind: 't' | 'v' | 'p',
    item: {order: string, id: ItemRef, item: Item},
    agent: Agent,
    defaultUserVote: number, // -1, 0, or 1
    defaultTotalVotes: { up: number, down: number },
}) {
    const { principal, agent } = useContext(AuthContext) as any;
    const [userVote, setUserVote] = useState(props.defaultUserVote);
    const [totalVotes, setTotalVotes] = useState(props.defaultTotalVotes);

    async function vote(child: ItemRef, value: number, clicked: 'up' | 'down') {
        if (principal === undefined || principal.toString() === "2vxsx-fae") { // TODO: hack
            alert("Login to vote!"); // TODO: a better dialog
            return;
        }
        const order = orderActor(process.env.CANISTER_ID_ORDER!, {agent})
        await order.vote(props.item.id.canister, BigInt(props.item.id.id), child.canister, BigInt(child.id), BigInt(value), false);
        // AppData.create(props.agent, serializeItemRef(props.item.id), props.streamKind).then(data => { // duplicate code
        //     data.subCategories().then(x => updateSubCategories(x));
        // });

        // FIXME
        if (clicked === 'up') {
            setUserVote(1);
            const diff = totalVotes[child.id].up > 0 ? -1 : 1;
            setTotalVotes({
                up: totalVotes[child.id].up + diff,
                down: 0,
            });
        };
        if (clicked === 'down') {
            setUserVote(-1);
            const diff = totalVotes[child.id].down > 0 ? -1 : 1;
            setTotalVotes({
                up: 0,
                down: totalVotes[child.id].down + diff,
            });
        };
    
    }
    function votesTitle(id) {
        return totalVotes ? `Up: ${totalVotes.up} Down: ${totalVotes.down}` : "";
    }

    return props.streamKind === 'v' &&
        <span title={votesTitle(props.item.id)}>
            <Button
                onClick={async e => await vote(props.item.id, (e.target as Element).classList.contains('active') ? 0 : +1, 'up')}
                className={userVote > 0 ? 'thumbs active' : 'thumbs'}>👍</Button>
            <Button
                onClick={async e => await vote(props.item.id, (e.target as Element).classList.contains('active') ? 0 : -1, 'down')}
                className={userVote < 0 ? 'thumbs active' : 'thumbs'}>👎</Button>
        </span>;
}