import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
// import { backend } from "../../../declarations/backend";

export default function SubFolders(props) {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: {data.folderName()}</h2>
            <ul>
                {(props['data-dir'] == 'super' ? data.superCategories() : data.subCategories()).map(x =>
                    <li key={x.id}>
                        <p>
                            {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                            <a lang={x.locale} href={`#/item/${x.id}`}>{x.title}</a>
                        </p>
                        {x.description ? <p lang={x.locale}><small>{x.description}</small></p> : ""}
                    </li>)}
            </ul>
        </>
    );
}