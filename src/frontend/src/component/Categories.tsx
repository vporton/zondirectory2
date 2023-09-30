import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";

export default function Categories(props: { defaultCategories?: string[], onChange?: (categories: string[]) => void }) {
    const [categories, setCategories] = useState<string[] | undefined>();
    const [categoriesList, setCategoriesList] = useState((categories ?? []).map(c => c.toString()));
    useEffect(() => {
        setCategoriesList(props.defaultCategories ?? []);
    }, [props.defaultCategories])
    function updateCategories() {
        setCategories(categoriesList);
        if (props.onChange !== undefined && categoriesList !== undefined) {
            props.onChange(categoriesList);
        }
    }
    useEffect(updateCategories, [categoriesList]);
    function updateCategoriesList() {
        const list: string[] = [];
        for (const e of document.querySelectorAll('#categoriesList input') as any) {
            list.push((e as HTMLInputElement).value)
        }
        setCategoriesList(list);
    }

    return (
        <>
            <h2>Post to categories (TODO: Limited to ?? posts per day)</h2>
            <p>TODO: Visual editor of categories</p>
            <ul id="categoriesList">
                {categoriesList.map((cat, i) => {
                    return (
                        <li key={i}>
                            <input value={cat} onChange={updateCategoriesList}/>
                            <Button onClick={() => setCategoriesList(categoriesList.filter((item) => item !== cat))}>Delete</Button>
                        </li>
                    );
                })}
            </ul>
            <p><Button onClick={() => setCategoriesList(categoriesList.concat([""]))}>Add</Button></p>
        </>
    );
}