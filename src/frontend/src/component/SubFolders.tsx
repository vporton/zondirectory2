import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useNavigate, useParams } from "react-router-dom";
import { ItemRef, serializeItemRef } from "../data/Data";
import { Item } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import ItemType from "./misc/ItemType";

export default function SubFolders(props) {
    const { id } = useParams();
    const [xdata, setXData] = useState<any>(undefined);
    const [title, setTitle] = useState("");
    const [categories, setCategories] = useState<{order: string, id: ItemRef, item: Item}[] | undefined>([]);
    const [itemsLast, setItemsLast] = useState("");
    const [itemsReachedEnd, setItemsReachedEnd] = useState(false);
    const [streamKind, setStreamKind] = useState<"t" | "v" | "p">("v"); // time, votes, or paid
    function updateStreamKind(e) {
        setStreamKind(e.currentTarget.value);
    }

    const navigate = useNavigate();
    useEffect(() => {
        if (id !== undefined) {
            AppData.create(props.defaultAgent, id, streamKind).then(data => {
                data.title().then(x => setTitle(x));
                if (props['data-dir'] == 'super') {
                    data.superCategories().then(x => {
                        setCategories(x); // FIXME: SUPER-categories
                        // TODO: duplicate code
                        if (x.length !== 0) {
                            setItemsLast(x[x.length - 1].order);
                        }
                    });
                } else {
                    data.subCategories().then(x => {
                        setCategories(x);
                        // TODO: duplicate code
                        if (x.length !== 0) {
                            setItemsLast(x[x.length - 1].order);
                        }
                    });
                }
                setXData(data);
            });
        }
    }, [id, props.defaultAgent, streamKind]);

    function moreItems(event: any) {
        event.preventDefault();
        if (categories?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        console.log('lowerBound', lowerBound)
        const promise = props['data-dir'] == 'super'
            ? xdata.superCategories({lowerBound, limit: 10}) : xdata.subCategories({lowerBound, limit: 10});
        promise.then(x => {
            console.log('X', x)
            setCategories(categories?.concat(x)); // FIXME: `?`
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            } else {
                setItemsReachedEnd(true);
            }
        });
    }

    return (
        <>
            <h2>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: <a href='#' onClick={() => navigate(`/item/`+id)}>{title}</a></h2>
            <p>Sort by:{" "}
                <label><input type="radio" name="stream" value="t" onChange={updateStreamKind} checked={streamKind == "t"}/> time</label>{" "}
                <label><input type="radio" name="stream" value="v" onChange={updateStreamKind} checked={streamKind == "v"}/> votes</label>{" "}
                <label><input type="radio" name="stream" value="p" onChange={updateStreamKind} checked={streamKind == "p"}/> amount paid</label>
            </p>
           <ul>
                {categories !== undefined && categories.map(x =>
                    <li key={serializeItemRef(x.id as any)}>
                        <p>
                            <ItemType item={x.item}/>
                            <a lang={x.item.item.locale} href={`#/item/${serializeItemRef(x.id as any)}`}>{x.item.item.title}</a>
                        </p>
                        {x.item.item.description ? <p lang={x.item.item.locale}><small>{x.item.item.description}</small></p> : ""}
                    </li>)}
            </ul>
            <p><a href="#" onClick={e => moreItems(e)} style={{visibility: itemsReachedEnd ? 'hidden' : 'visible'}}>More...</a>{" "}
                <a href={`#/create/for-category/${id}`}>Create</a></p>
        </>
    );
}
