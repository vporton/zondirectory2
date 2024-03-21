import * as React from "react";
import { ItemData } from "../../../../declarations/CanDBPartition/CanDBPartition.did";

export default function ItemType(props: {item: ItemData | undefined}) { // TODO: Is it the right type of argument?
    return <>
        {props.item && (props.item.item.communal ?
            <span title="Communal folder">&#x1f465;</span> :
            <span title="Owned folder">&#x1f464;</span>)}
    </>
}