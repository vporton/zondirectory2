import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useNavigate, useParams } from "react-router-dom";
import { serializeItemRef } from "../data/Data";

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

export default function SubFolders(props) {
    const { id } = useParams();
    const [data, setData] = useState<any>(undefined);
    const [title, setTitle] = useState("");
    const [subcategories, setSubcategories] = useState([] as Item[]);
    const [supercategories, setSupercategories] = useState([] as Item[]);

    const navigate = useNavigate();
    useEffect(() => {
        if (id !== undefined) {
            AppData.create(props.defaultAgent, id).then(data => {
                data.title().then(x => setTitle(x));
                data.subCategories().then(x => setSubcategories(x));
                data.superCategories().then(x => setSupercategories(x));
            });
        }
    }, [id, props.defaultAgent]);

    return (
        <>
            <h2>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: <a href='#' onClick={() => navigate(`/item/`+id)}>{title}</a></h2>
            <ul>
                {(props['data-dir'] == 'super' ? supercategories : subcategories).map(x =>
                    <li key={serializeItemRef(x.id as any)}>
                        <p>
                            {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                            <a lang={x.locale} href={`#/item/${serializeItemRef(x.id as any)}`}>{x.title}</a>
                        </p>
                        {x.description ? <p lang={x.locale}><small>{x.description}</small></p> : ""}
                    </li>)}
            </ul>
        </>
    );
}