import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
// import { zon_backend } from "../../../declarations/zon_backend";

export default function SubFolders(props) {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>Subfolders of: {data.folderName()}</h2>
            <ul>
                {(props['data-dir'] == 'super' ? data.superCategories() : data.subCategories()).map(x =>
                    <li key={x.id}>
                        <p>
                            {x.type == 'public' ? <>&#x1f465;</> : <>&#x1f464;</>}
                            <a lang={x.locale} href={`#/folder/${x.id}`}>{x.title}</a>
                        </p>
                        {x.description ? <p lang={x.locale}><small>{x.description}</small></p> : ""}
                    </li>)}
            </ul>
        </>
    );
}