import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
import { AuthContext } from "./auth/use-auth-client";
import { serializeItemRef } from "../data/Data";
import ItemType from "./misc/ItemType";

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

export default function ShowItem() {
    return (
        <>
            <AuthContext.Consumer>
                {({defaultAgent}) => {
                    return <ShowItemContent defaultAgent={defaultAgent}/>
                }}
            </AuthContext.Consumer>
        </>
    );
}

function ShowItemContent(props: {defaultAgent}) {
    const { id } = useParams();
    const [locale, setLocale] = useState("");
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [postText, setPostText] = useState("");
    const [type, setType] = useState<string | undefined>(undefined);
    const [creator, setCreator] = useState("");
    const [subcategories, setSubcategories] = useState(undefined as Item[] | undefined);
    const [supercategories, setSupercategories] = useState(undefined as Item[] | undefined);
    const [items, setItems] = useState(undefined as Item[] | undefined);
    const [data, setData] = useState<any>(undefined); // TODO: hack
    const [xdata, setXData] = useState<any>(undefined); // TODO: hack
    const [subCategoriesLast, setSubCategoriesLast] = useState("");
    const [superCategoriesLast, setSuperCategoriesLast] = useState("");
    const [itemsLast, setItemsLast] = useState("");
    useEffect(() => {
        setSubcategories(undefined);
        setSupercategories(undefined);
        setItems(undefined);
    }, [id]);
    useEffect(() => { // TODO
        if (id !== undefined) {
            AppData.create(props.defaultAgent, id).then(data => {
                setXData(data);
                setData(data.item);
                data.locale().then(x => setLocale(x));
                data.title().then(x => setTitle(x));
                data.description().then(x => setDescription(x));
                data.postText().then(x => setPostText(x));
                data.creator().then(x => setCreator(x));
                data.subCategories().then(x => {
                    setSubcategories(x);
                    if (x.length !== 0) {
                        setSubCategoriesLast(x[x.length - 1].order); // duplicate code
                    }
                })
                data.superCategories().then(x => {
                    setSupercategories(x);
                    if (x.length !== 0) {
                        setSuperCategoriesLast(x[x.length - 1].order); // duplicate code
                    }
                });
                data.items().then(x => {
                    setItems(x);
                    if (x.length !== 0) {
                        setItemsLast(x[x.length - 1].order); // duplicate code
                    }
                });
                data.details().then((x) => {
                    setType(Object.keys(x)[0]);
                });
            });
        }
    }, [id, props.defaultAgent]); // TODO: more tight choice
    function moreSubcategories(event: any) {
        event.preventDefault();
        if (subcategories?.length === 0) {
            return;
        }
        const lowerBound = subCategoriesLast + 'x';
        xdata.subCategories({lowerBound, limit: 10}).then(x => {
            setSubcategories(subcategories?.concat(x))
            if (x.length !== 0) {
                setSubCategoriesLast(x[x.length - 1].order); // duplicate code
            }
        });
    }
    function moreSupercategories(event: any) {
        event.preventDefault();
        if (supercategories?.length === 0) {
            return;
        }
        const lowerBound = superCategoriesLast + 'x';
        xdata.superCategories({lowerBound, limit: 10}).then(x => {
            setSupercategories(supercategories?.concat(x))
            if (x.length !== 0) {
                setSubCategoriesLast(x[x.length - 1].order); // duplicate code
            }
        });
    }
    function moreItems(event: any) {
        event.preventDefault();
        if (items?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        xdata.items({lowerBound, limit: 10}).then(x => {
            setItems(items?.concat(x))
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            }
        });
    }
    return <>
        <h2><ItemType item={data}/>{type === 'ownedCategory' || type === 'communalCategory' ? "Folder: " : " "}<span lang={locale}>{title}</span></h2>
        <p>Creator: <small>{creator.toString()}</small></p>
        {description !== null ? <p lang={locale}>{description}</p> : ""}
        {postText !== "" ? <p lang={locale}>{postText}</p> : ""}
        <p>Sort by:{" "}
            <label><input type="radio" defaultChecked={true}/> time</label>
            <label title="Not implemented yet"><input type="radio" disabled={true}/> votes</label>
            <label title="Not implemented yet"><input type="radio" disabled={true}/> amount paid</label>
        </p>
        <h3>Sub-folders</h3>
        {subcategories === undefined ? <p>Loading...</p> :
        <ul>
            {subcategories.map((x: any) => <li lang={x.locale} key={serializeItemRef(x.id as any)}>
                <ItemType item={x}/>
                <a href={`#/item/${serializeItemRef(x.id)}`}>{x.title}</a>
            </li>)}
        </ul>}
        <p><a href="#" onClick={e => moreSubcategories(e)}>More...</a> <a href={`#/create-subcategory/for-category/${id}`}>Create subfolder</a></p>
        <h3>Super-folders</h3>
        {supercategories === undefined ? <p>Loading...</p> :
        <ul>
            {supercategories.map((x: any) => <li lang={x.locale} key={serializeItemRef(x.id as any)}>
                <ItemType item={x}/>
                <a href={`#/item/${serializeItemRef(x.id)}`}>{x.title}</a>
            </li>)}
        </ul>}
        {/* TODO: Create super-category */}
        <p><a href="#" onClick={e => moreSupercategories(e)}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
        <h3>{type === 'ownedCategory' || type === 'communalCategory' ? "Items" : "Comments"}</h3>
        {items === undefined ? <p>Loading...</p> : items.map(item => 
            <div key={serializeItemRef(item.id as any)}>
                <p lang={item.locale} key={item.id}>
                    {item.price ? <>({item.price} ICP) </> : ""}
                    {item.link ? <a href={item.link}>{item.title}</a> : item.title}
                    {" "}<a href={`#/item/${serializeItemRef(item.id as any)}`} title="Homepage">[H]</a>
                </p>
                <p lang={item.locale} key={serializeItemRef(item.id as any)} style={{marginLeft: '1em'}}>{item.description}</p>
            </div>
        )}
        <p><a href="#" onClick={e => moreItems(e)}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
    </>

}