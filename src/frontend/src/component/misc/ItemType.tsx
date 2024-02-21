import * as React from "react";
import { Item } from "../../../../declarations/CanDBPartition/CanDBPartition.did";

export default function ItemType(props: {item: Item}) { // TODO: Is it the right type of argument?
    const type = props.item && props.item.item.details ? Object.keys(props.item.item.details)[0] : undefined; // TODO: hack
    return <>
        {type == 'communalFolder' && <span title="Communal folder">&#x1f465;</span>}
        {type == 'ownedFolder' && <span title="Owned folder">&#x1f464;</span>}
    </>
}