import * as React from "react";
import { useState } from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
import { take } from "../util/iterators";
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
    const { id } = useParams();
    const [locale, setLocale] = useState("");
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [subcategories, setSubcategories] = useState([] as Item[]);
    const [supercategories, setSupercategories] = useState([] as Item[]);
    const [items, setItems] = useState([] as Item[]);
    if (id !== undefined) {
        AppData.create(id).then(data => {
            data.locale().then(x => setLocale(x));
            data.title().then(x => setTitle(x));
            data.description().then(x => setDescription(x));
            data.subCategories().then(x => setSubcategories(x));
            data.superCategories().then(x => setSupercategories(x));
            data.items().then(x => setItems(x));
        });
    }
    return (
        <>
            <h2>Folder: <span lang={locale}>{title}</span></h2>
            {description !== null ? <p lang={locale}>{description}</p> : ""}
            <h3>Sub-categories</h3>
            <ul>
                {take(subcategories, 3).map(x => <li lang={x.locale} key={x.id}>
                    {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                    <a href={`#/item/${x.id}`}>{x.title}</a>
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
                        {item.link ? <a href={item.link}>{item.title}</a> : item.title}</p>
                    <p lang={item.locale} key={item.id+'a'} style={{marginLeft: '1em'}}>{item.description}</p>
                </div>
            )}
            <p><a href={`#`}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
        </>
    );
}