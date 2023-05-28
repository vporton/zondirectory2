import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
// import { zon_backend } from "../../../declarations/zon_backend";

export default function SubFolders() {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>Subfolders of: {data.folderName()}</h2>
            <ul>
                {data.subCategories().map(x =>
                    <li key={x.id}>
                        <p><a href={`#/folder/${x.id}`}>{x.name}</a></p>
                        {x.description ? <p><small>{x.description}</small></p> : ""}
                    </li>)}
            </ul>
        </>
    );
}