import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";

export default function Categories(props: { defaultCategories?: number[], onChange?: (categories: number[]) => void }) {
    const [categories, setCategories] = useState(props.defaultCategories ?? []);
    const [categoriesList, setCategoriesList] = useState(categories.map(c => c.toString()) ?? []);
    function updateCategories() {
        // TODO: This filter incorrectly skips without validation strings with letters.
        const cats = categoriesList.filter(c => /^[0-9]+$/.test(c)).map(c => +c);
        setCategories(cats);
        if (props.onChange !== undefined) {
            props.onChange(cats);
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
                        <li key={i}><input type="number" value={cat} onChange={updateCategoriesList}/></li>
                    );
                })}
            </ul>
            <p><Button onClick={() => setCategoriesList(categoriesList.concat([""]))}>Add</Button></p>
        </>
    );
}