import React, { useContext, useEffect, useState } from "react";
import { Item } from "../../../../declarations/CanDBPartition/CanDBPartition.did";
import { AuthContext } from "../auth/use-auth-client";
import { ItemRef, loadTotalVotes, loadUserVote, parseItemRef, serializeItemRef } from "../../data/Data";
import { createActor as orderActor } from "../../../../declarations/order";
import { AppData } from "../../DataDispatcher";
import { Agent } from "@dfinity/agent";
import Button from "react-bootstrap/esm/Button";

export default function UpDown(props: {
    parent: {id: ItemRef},
    item: {order: string, id: ItemRef, item: Item},
    agent: Agent,
    // onUpdateList: (() => void) | undefined,
    userVote: number, // -1, 0, or 1
    onSetUserVote: (id: ItemRef, v: number) => void,
    totalVotes: { up: number, down: number },
    onSetTotalVotes: (id: ItemRef, v: { up: number, down: number }) => void,
}) {
    const { principal, agent } = useContext(AuthContext) as any;

    // hack
    async function vote(value: number, clicked: 'up' | 'down') {
        if (principal === undefined || principal.toString() === "2vxsx-fae") { // TODO: hack
            alert("Login to vote!"); // TODO: a better dialog
            return;
        }

        let changeUp = (value == 1 && props.userVote != 1) || (props.userVote == 1 && value != 1);
        let changeDown = (value == -1 && props.userVote != -1) || (props.userVote == -1 && value != -1);

        let up = props.totalVotes ? Number(props.totalVotes.up) : 0;
        let down = props.totalVotes ? Number(props.totalVotes.down) : 0;
        if (changeUp || changeDown) {
            if (changeUp) {
              up += value - Number(props.userVote) > 0 ? 1 : -1;
            }
            if (changeDown) {
              down += value - Number(props.userVote) > 0 ? -1 : 1;
            }
        }      

        if (clicked === 'up') {
            props.onSetUserVote(props.item.id, props.userVote === 1 ? 0 : 1);
        };
        if (clicked === 'down') {
            props.onSetUserVote(props.item.id, props.userVote === -1 ? 0 : -1);
        };
        props.onSetTotalVotes(props.item.id, {up, down});

        const order = orderActor(process.env.CANISTER_ID_ORDER!, {agent});
        await order.vote(props.parent.id.canister, BigInt(props.parent.id.id), props.item.id.canister, BigInt(props.item.id.id), BigInt(value), false);
    }
    function votesTitle() {
        return props.totalVotes ? `Up: ${props.totalVotes.up} Down: ${props.totalVotes.down}` : "";
    }

    return (
        <span title={votesTitle()}>
            <Button
                onClick={async e => await vote((e.target as Element).classList.contains('active') ? 0 : +1, 'up')}
                className={props.userVote > 0 ? 'thumbs active' : 'thumbs'}>👍</Button>
            <Button
                onClick={async e => await vote((e.target as Element).classList.contains('active') ? 0 : -1, 'down')}
                className={props.userVote < 0 ? 'thumbs active' : 'thumbs'}>👎</Button>
        </span>
    );
}