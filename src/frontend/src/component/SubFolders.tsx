import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ItemRef, serializeItemRef } from "../data/Data";
import { ItemData, ItemTransfer } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import ItemType from "./misc/ItemType";
import { Agent } from "@dfinity/agent";
import { Helmet } from "react-helmet";
import { OnpageNavigation } from "./OnpageNavigation";

export default function SubFolders(props: {defaultAgent: Agent | undefined, 'data-dir': 'sub' | 'super'}) {
    const { id } = useParams();
    const [xdata, setXData] = useState<any>(undefined);
    const [title, setTitle] = useState("");
    const [folders, setFolders] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>([]);
    const [itemsLast, setItemsLast] = useState("");
    const [itemsReachedEnd, setItemsReachedEnd] = useState(false);
    const [streamKind, setStreamKind] = useState<"t" | "v">("v"); // time, votes
    const [startFoldersPage, setStartFoldersPage] = useState(new Map([
        ["nfolders", 5],
    ]));
    const [foldersPage, setFoldersPage] = useState(new Map());
    function updateStreamKind(e) {
        setStreamKind(e.currentTarget.value);
    }

    useEffect(() => {
        if (id !== undefined && props.defaultAgent !== undefined) {
            AppData.create(props.defaultAgent, id, streamKind).then(data => {
                data.title().then(x => setTitle(x));
                if (props['data-dir'] == 'super') {
                    data.superFolders().then(x => {
                        setFolders(x); // TODO: SUPER-folders
                        // TODO: duplicate code
                        if (x.length !== 0) {
                            setItemsLast(x[x.length - 1].order);
                        }
                    });
                } else {
                    data.subFolders({limit: startFoldersPage.get("nfolders")}).then(x => {
                        setFolders(x);
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
        if (folders?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        console.log('lowerBound', lowerBound)
        const promise = props['data-dir'] == 'super'
            ? xdata.superFolders({lowerBound, limit: 10}) : xdata.subFolders({lowerBound, limit: 10});
        promise.then(x => {
            const newFolders = folders?.concat(x);
            if (!newFolders) {
                return;
            }
            setFolders(newFolders); // TODO: ?
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            } else {
                setItemsReachedEnd(true);
            }
            setFoldersPage((old) => old.set("nfolders", newFolders.length));
        });
    }

    return (
        <>
            <Helmet>
                <link rel="canonical" href={`https://zoncircle.com${props['data-dir'] == 'super' ? "/superfolders-of/" : "/subfolders-of/"}` + id}/>
                <title>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: {title}</title>
                <meta name="robots" content="noindex"/>
            </Helmet>
            <OnpageNavigation startPage={startFoldersPage} page={foldersPage}/>
            <h1>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: <Link className="nav-item" to={`/item/`+id}>{title}</Link></h1>
            <div data-nosnippet="true">
                <p>Sort by:{" "}
                    <label><input type="radio" name="stream" value="t" onChange={updateStreamKind} checked={streamKind == "t"}/> time</label>{" "}
                    <label><input type="radio" name="stream" value="v" onChange={updateStreamKind} checked={streamKind == "v"}/> votes</label>{" "}
                </p>
            </div>
           <ul>
                {folders !== undefined && folders.map(x =>
                    <li key={serializeItemRef(x.id as any)}>
                        <p>
                            <ItemType item={x.item}/>
                            <Link lang={x.item.data.item.locale} to={`/item/${serializeItemRef(x.id as any)}`}>{x.item.data.item.title}</Link>
                        </p>
                        {x.item.data.item.description ? <p lang={x.item.data.item.locale}><small>{x.item.data.item.description}</small></p> : ""}
                    </li>)}
            </ul>
            <nav>
                <p><Link to="#" onClick={e => moreItems(e)} style={{visibility: itemsReachedEnd ? 'hidden' : 'visible'}}>More...</Link>{" "}
                    <Link to={`/create/for-folder/${id}`}>Create</Link></p>
            </nav>
        </>
    );
}
