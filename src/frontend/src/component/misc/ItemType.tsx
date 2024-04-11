import * as React from "react";
// import { ItemData } from "../../../../../out/src/storage/CanDBPartition";
import { ItemDB } from "../../data/Data";

export default function ItemType(props: {item: ItemDB}) { // TODO: Is it the right type of argument?
    // FIXME
    return <>
        {props.item && (props.item.communal ?
            <span title="Communal folder">&#x1f465;</span> :
            <span title="Owned folder">&#x1f464;</span>)}
    </>
    // return <>
    // {props.item && (
    //     <span title="Owned item">&#x1f464;</span>)}
    // </>
}