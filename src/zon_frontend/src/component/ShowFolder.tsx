import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
import { take } from "../util/iterators";
// import { zon_backend } from "../../../declarations/zon_backend";

export default function ShowFolder() {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>Folder: {data.folderName()}</h2>
            {data.folderDescription() ? <p>{data.folderDescription()}</p> : ""}
            <h3>Sub-categories</h3>
            <ul>
                {take(data.subCategories(), 3).map(x => <li key={x.id}><a href={`#/folder/${x.id}`}>{x.name}</a></li>)}
            </ul>
            <p><a href="#">More...</a></p>
            <h3>Super-categories</h3>
        </>
    );
}