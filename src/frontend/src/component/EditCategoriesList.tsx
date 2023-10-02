import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";

export default function EditCategoriesList(props: { defaultCategories?: string[], onChange?: (categories: string[]) => void }) {
    const [categories, setCategories] = useState<string[] | undefined>(undefined);
    useEffect(() => {
        if (categories === undefined && props.defaultCategories?.length !== 0) {
            setCategories(props.defaultCategories ?? []);
        }
    }, [props.defaultCategories])
    function updateCategories() {
        if (props.onChange !== undefined && categories !== undefined) {
            props.onChange(categories);
        }
    }
    useEffect(updateCategories, [categories]);
    function updateCategoriesList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#categoriesList input') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        setCategories(list);
    }

    return (
        <>
            <h2>Post to categories (TODO: Limited to ?? posts per day)</h2>
            <p>TODO: Visual editor of categories</p>
            <ul id="categoriesList">
                {(categories ?? []).map((cat, i) => {
                    return (
                        <li key={i}>
                            <input value={cat} onChange={updateCategoriesList}/>
                            <Button onClick={() => setCategories(categories.filter((item) => item !== cat))}>Delete</Button>
                        </li>
                    );
                })}
            </ul>
            <p><Button onClick={() => setCategories(categories.concat([""]))}>Add</Button></p>
        </>
    );
}