import React, { useContext, useEffect, useState } from "react";
import { Item } from "../../../../declarations/CanDBPartition/CanDBPartition.did";
import { AuthContext } from "../auth/use-auth-client";
import { ItemRef, loadTotalVotes, loadUserVote, parseItemRef, serializeItemRef } from "../../data/Data";
import { createActor as orderActor } from "../../../../declarations/order";
import { AppData } from "../../DataDispatcher";
import { Agent } from "@dfinity/agent";
import Button from "react-bootstrap/esm/Button";

export default function UpDown(props: {
    streamKind: 't' | 'v' | 'p',
    parent: {id: ItemRef},
    item: {order: string, id: ItemRef, item: Item},
    agent: Agent,
    defaultUserVote: number, // -1, 0, or 1
    defaultTotalVotes: { up: number, down: number },
}) {
    const { principal, agent } = useContext(AuthContext) as any;
    const [userVote, setUserVote] = useState(props.defaultUserVote);
    const [totalVotes, setTotalVotes] = useState(props.defaultTotalVotes);

    // hack
    useEffect(() => {
        console.log("QQQ", props.defaultUserVote)
        if (userVote === undefined) {
            setUserVote(props.defaultUserVote);
        }
    }, [props.defaultUserVote]);
    useEffect(() => {
        console.log(props.defaultTotalVotes);
        if (totalVotes === undefined) {
            setTotalVotes(props.defaultTotalVotes);
        }
    }, [props.defaultTotalVotes]);

    async function vote(value: number, clicked: 'up' | 'down') {
        if (principal === undefined || principal.toString() === "2vxsx-fae") { // TODO: hack
            alert("Login to vote!"); // TODO: a better dialog
            return;
        }

        let changeUp = (value == 1 && userVote != 1) || (userVote == 1 && value != 1);
        let changeDown = (value == -1 && userVote != -1) || (userVote == -1 && value != -1);

        let up = totalVotes ? Number(totalVotes.up) : 0;
        let down = totalVotes ? Number(totalVotes.down) : 0;
        if (changeUp || changeDown) {
            if (changeUp) {
              up += value - Number(userVote) > 0 ? 1 : -1;
            }
            if (changeDown) {
              down += value - Number(userVote) > 0 ? -1 : 1;
            }
        }      

        if (clicked === 'up') {
            setUserVote(userVote === 1 ? 0 : 1);
        };
        if (clicked === 'down') {
            setUserVote(userVote === -1 ? 0 : -1);
        };
        setTotalVotes({up, down});

        const order = orderActor(process.env.CANISTER_ID_ORDER!, {agent});
        await order.vote(props.parent.id.canister, BigInt(props.parent.id.id), props.item.id.canister, BigInt(props.item.id.id), BigInt(value), false);
        // alert("VOTED!" + value);
    }
    function votesTitle(id) {
        return totalVotes ? `Up: ${totalVotes.up} Down: ${totalVotes.down}` : "";
    }

    return props.streamKind === 'v' &&
        <span title={votesTitle(props.item.id)}>
            <Button
                onClick={async e => await vote((e.target as Element).classList.contains('active') ? 0 : +1, 'up')}
                className={userVote > 0 ? 'thumbs active' : 'thumbs'}>👍</Button>
            <Button
                onClick={async e => await vote((e.target as Element).classList.contains('active') ? 0 : -1, 'down')}
                className={userVote < 0 ? 'thumbs active' : 'thumbs'}>👎</Button>
        </span>;
}