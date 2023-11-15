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
    const [xdata, setXData] = useState<any>(undefined);
    const [title, setTitle] = useState("");
    const [categories, setCategories] = useState([] as any[]); // TODO: `as Item[]`
    const [itemsLast, setItemsLast] = useState("");
    const [itemsReachedEnd, setItemsReachedEnd] = useState(false);

    const navigate = useNavigate();
    useEffect(() => {
        if (id !== undefined) {
            AppData.create(props.defaultAgent, id).then(data => {
                data.title().then(x => setTitle(x));
                let categories;
                if (props['data-dir'] == 'super') {
                    data.superCategories().then(x => {
                        setCategories(x);
                        // TODO: duplicate code
                        if (x.length !== 0) {
                            console.log('categories', x)
                            setItemsLast(x[x.length - 1].order); // duplicate code
                        }
                    });
                } else {
                    data.subCategories().then(x => {
                        setCategories(x);
                        // TODO: duplicate code
                        if (x.length !== 0) {
                            console.log('categories', x)
                            setItemsLast(x[x.length - 1].order); // duplicate code
                        }
                    });
                }
                setXData(data);
            });
        }
    }, [id, props.defaultAgent]);

    function moreItems(event: any) {
        event.preventDefault();
        if (categories?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        console.log('lowerBound', lowerBound)
        const promise = props['data-dir'] == 'super'
            ? xdata.superCategories({lowerBound, limit: 10}) : xdata.subCategories({lowerBound, limit: 10});
        promise.then(x => {
            console.log('X', x)
            setCategories(categories?.concat(x)); // FIXME: `?`
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            } else {
                setItemsReachedEnd(true);
            }
        });
    }

    return (
        <>
            <h2>{props['data-dir'] == 'super' ? "Super-folders" : "Subfolders"} of: <a href='#' onClick={() => navigate(`/item/`+id)}>{title}</a></h2>
            <ul>
                {categories.map(x =>
                    <li key={serializeItemRef(x.id as any)}>
                        <p>
                            {x.type == 'public' ? <span title="Communal folder">&#x1f465;</span> : <span title="Owned folder">&#x1f464;</span>}
                            <a lang={x.locale} href={`#/item/${serializeItemRef(x.id as any)}`}>{x.title}</a>
                        </p>
                        {x.description ? <p lang={x.locale}><small>{x.description}</small></p> : ""}
                    </li>)}
            </ul>
            <p><a href="#" onClick={e => moreItems(e)} style={{visibility: itemsReachedEnd ? 'hidden' : 'visible'}}>More...</a>{" "}
                <a href={`#/create/for-category/${id}`}>Create</a></p>
        </>
    );
}