import * as React from "react";
import { useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
// import { backend } from "../../../declarations/backend";

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
    useEffect(() => {
        if (id !== undefined) {
            console.log("A2", id);
            AppData.create(id).then(data => {
                data.title().then(x => setTitle(x));
                data.subCategories().then(x => setSubcategories(x));
                data.superCategories().then(x => setSupercategories(x));
            });
        }
    }, [id]);

    return (
        <>
            <h2>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: {title}</h2>
            <ul>
                {(props['data-dir'] == 'super' ? supercategories : subcategories).map(x =>
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