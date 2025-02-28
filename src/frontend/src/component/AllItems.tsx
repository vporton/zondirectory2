import * as React from "react";
import { Link } from "react-router-dom";
import { idlFactory as canDBPartitionIdl } from "../../../declarations/CanDBPartition";
import { _SERVICE as CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { idlFactory as nacDBPartitionIdl } from "../../../declarations/NacDBPartition";
// import { SERVICE as NacDBPartition } from "../../../declarations/NacDBPartition/NacDBPartition.did";
import { idlFactory as nacDBIndexIdl } from "../../../declarations/NacDBIndex";
import { _SERVICE as NacDBIndex } from "../../../declarations/NacDBIndex/NacDBIndex.did";
import { Actor, Agent } from "@dfinity/agent";
import { ItemRef, serializeItemRef } from "../data/Data";
import { ItemTransfer } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { Principal } from "@dfinity/principal";
import { useEffect, useState } from "react";
import { Helmet } from "react-helmet";
import ItemType from "./misc/ItemType";
import Nav from "react-bootstrap/esm/Nav";
import Button from "react-bootstrap/Button";
import { useAuth } from "./auth/use-auth-client";

export function AllItems(props: {defaultAgent: Agent | undefined}) {
    const [items, setItems] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);

    const { principal } = useAuth();

    // TODO: duplicate code
    async function aList(opts?: {lowerBound?: string, limit?: number})
        : Promise<{order: string, id: ItemRef, item: ItemTransfer}[]>
    {
        const nacDBIndex: NacDBIndex = Actor.createActor(nacDBIndexIdl, {canisterId: process.env.CANISTER_ID_NACDBINDEX!, agent: props.defaultAgent });
        const order = await nacDBIndex.getAllItemsStream();

        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 500};
        // const client: NacDBPartition = Actor.createActor(nacDBPartitionIdl, {canisterId: outerCanister, agent: this.agent });
        // const {canister: innerPart, key: innerKey} = (await client.getInner({outerKey}) as any)[0]; // TODO: error handling
        const client2 = Actor.createActor(nacDBPartitionIdl, {canisterId: Principal.from(order.order[0]).toText(), agent: props.defaultAgent });
        const items = ((await client2.scanLimitOuterComposite({outerKey: order.order[1], lowerBound, upperBound: "x", dir: {fwd: null}, limit: BigInt(limit)})) as any).results as
            [[string, {text: string}]] | [];
        const items1aa = items.length === 0 ? [] : items.map(x => ({key: x[0], text: x[1].text}));
        const items1a: {order: string, principal: string, id: number}[] = items1aa.map(x => {
            const m = x.text.match(/^([0-9]*)@(.*)$/);
            return {order: x.key, principal: m![2], id: Number(m![1])};
        });
        const items2 = items1a.map(({order, principal, id}) => { return {canister: Principal.from(principal), id, order} });
        const items3 = items2.map(id => (async () => {
            const part: CanDBPartition = Actor.createActor(canDBPartitionIdl, {canisterId: id.canister, agent: props.defaultAgent });
            return {order: id.order, id, item: await part.getItemComposite(BigInt(id.id))};
        })());
        const items4 = await Promise.all(items3);
        return items4.map(({order, id, item}) => ({
            order,
            id,
            item,
        }));
    }

    async function getItems(opts?: {lowerBound?: string, limit?: number}): Promise<{order: string, id: ItemRef, item: ItemTransfer}[]> {
        const {lowerBound, limit} = opts !== undefined ? opts : {lowerBound: "", limit: 5};
        if (props.defaultAgent === undefined) {
            return undefined;
        }
        return await aList({lowerBound, limit})
    }
    useEffect(() => {
        getItems().then(items => setItems(items));
    }, []);
    
    return <>
        <Helmet>
            <link rel="canonical" href="https://zoncircle.com/latest"/>
            <title>Latest Added Items - Zon</title>
            <meta name="description" content="Latest added items - Zon Social Media: a fusion of social network, web directory, and marketplace"/>
            <meta name="robots" content="noindex,follow"/>
        </Helmet>
        <h1>Latest Added Items - Zon</h1>
        {items === undefined ? <p>Loading...</p> :
        <ul>
            {items.map((x: {order: string, id: ItemRef, item: ItemTransfer}) =>
                <li lang={x.item.data.item.locale} key={serializeItemRef(x.id as any)}>
                    <ItemType item={x.item}/>
                    <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>
                    {x.item.data.creator.compareTo(principal) === 'eq' &&
                        <>
                            {" "}
                            <Button href={`/edit/${(x.item.data.item.details as any).folder !== undefined ? 'folder' : 'item'}/${serializeItemRef(x.id)}`}>Edit</Button>
                        </>
                    }
                </li>)}
        </ul>}
        {/* TODO: Load More button */}
    </>;
}


function _unwrap<T>(v: T[]): T | undefined {
    // TODO: simplify for greater performance
    return v === undefined || v.length === 0 ? undefined : v[0];
}
