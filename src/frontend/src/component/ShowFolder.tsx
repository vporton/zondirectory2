import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
import { take } from "../util/iterators";
import { AuthContext } from "./auth/use-auth-client";
import { Agent, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { getIsLocal } from "../util/client";
import { serializeItemRef } from "../data/Data";
// import { backend } from "../../../declarations/backend";
// import { Item } from "../../../declarations/CanDBPartition/CanDBPartition.did"

// TODO: a stricter type
type Item = {
    id: string;
    locale: string;
    title: string;
    description?: string;
    type?: string; // TODO: `'private' | 'public'`
    price?: string; // TODO: `number`
    link?: string; // TODO: URL type
};

export default function ShowFolder() {
    return (
        <>
            <AuthContext.Consumer>
                {({authClient}) => {
                    return <ShowFolderContent authClient={authClient}/>
                }}
            </AuthContext.Consumer>
        </>
    );
}

function ShowFolderContent(props: {authClient}) {
    const { id } = useParams();
    const [locale, setLocale] = useState("");
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [type, setType] = useState<string | undefined>(undefined);
    const [subcategories, setSubcategories] = useState([] as Item[]);
    const [supercategories, setSupercategories] = useState([] as Item[]);
    const [items, setItems] = useState([] as Item[]);
    useEffect(() => { // TODO
        if (id !== undefined) {
            const agent = new HttpAgent({identity: props.authClient?.getIdentity()});
            if (getIsLocal()) {
                agent.fetchRootKey(); // TODO: For all other agents.
            }
            AppData.create(id).then(data => {
                // TODO: Passing `agent` here is a hack!
                data.locale().then(x => setLocale(x));
                data.title().then(x => setTitle(x));
                data.description().then(x => setDescription(x));
                data.subCategories(agent).then(x => setSubcategories(x));
                data.superCategories().then(x => setSupercategories(x));
                data.items(agent).then(x => setItems(x));
                data.details().then((x) => {
                    console.log('XX', x)
                    setType(Object.keys(x)[0])
                })
            });
        }
    }, [id, props.authClient]); // TODO: more tight choice
    return <>
        <h2>{type === 'ownedFolder' || type === 'communalFolder' ? "Folder: " : " "}<span lang={locale}>{title}</span></h2>
        {description !== null ? <p lang={locale}>{description}</p> : ""}
        <h3>Sub-categories</h3>
        <ul>
            {take(subcategories, 3).map((x: any) => <li lang={x.locale} key={serializeItemRef(x.id as any)}>
                {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                <a href={`#/item/${serializeItemRef(x.id)}`}>{x.title}</a>
            </li>)}
        </ul>
        <p><a href={`#/subfolders-of/${id}`}>More...</a> <a href={`#/create-subcategory/for-category/${id}`}>Create subfolder</a></p>
        <h3>Super-categories</h3>
        <ul>
            {take(supercategories, 3).map(x => <li lang={x.locale} key={x.id}>
                {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                <a href={`#/item/${x.id}`}>{x.title}</a>
            </li>)}
        </ul>
        {/* TODO: Create super-category */}
        <p><a href={`#/superfolders-of/${id}`}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
        {items.map(item => 
            <div key={item.id}>
                <p lang={item.locale} key={item.id}>
                    {item.price ? <>({item.price} ICP) </> : ""}
                    {item.link ? <a href={item.link}>{item.title}</a> : item.title}
                    {" "}<a href={`#/item/${serializeItemRef(item.id as any)}`} title="Homepage">[H]</a>
                </p>
                <p lang={item.locale} key={serializeItemRef(item.id as any)} style={{marginLeft: '1em'}}>{item.description}</p>
            </div>
        )}
        <p><a href={`#`}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
    </>

}