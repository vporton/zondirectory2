import * as React from "react";
import { ItemInfo } from "../../../../declarations/CanDBPartition/CanDBPartition.did";

export default function ItemType(props: {item: ItemInfo}) { // TODO: Is it the right type of argument?
    const type = props.item && props.item.item.details ? Object.keys(props.item.item.details)[0] : undefined; // TODO: hack
    return <>
        {type == 'communalCategory' && <span title="Communal folder">&#x1f465;</span>}
        {type == 'ownedCategory' && <span title="Owned folder">&#x1f464;</span>}
    </>
}