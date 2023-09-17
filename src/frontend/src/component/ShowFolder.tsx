import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
import { take } from "../util/iterators";
// import { backend } from "../../../declarations/backend";

export default function ShowFolder() {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>Folder: <span lang={data.locale()}>{data.folderName()}</span></h2>
            {data.folderDescription() ? <p lang={data.locale()}>{data.folderDescription()}</p> : ""}
            <h3>Sub-categories</h3>
            <ul>
                {take(data.subCategories(), 3).map(x => <li lang={x.locale} key={x.id}>
                    {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                    <a href={`#/folder/${x.id}`}>{x.title}</a>
                </li>)}
            </ul>
            <p><a href={`#/subfolders-of/${id}`}>More...</a> <a href={`#/create-subcategory/for-category/${id}`}>Create subfolder</a></p>
            <h3>Super-categories</h3>
            <ul>
                {take(data.superCategories(), 3).map(x => <li lang={x.locale} key={x.id}>
                    {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                    <a href={`#/folder/${x.id}`}>{x.title}</a>
                </li>)}
            </ul>
            {/* TODO: Create super-category */}
            <p><a href={`#/superfolders-of/${id}`}>More...</a> <a href={`#/create/for-category/${id}`}>Create</a></p>
            {data.items().map(item => 
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