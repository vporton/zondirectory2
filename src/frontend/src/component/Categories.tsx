import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";

export default function Categories(props: { defaultCategories?: string[], onChange?: (categories: string[]) => void }) {
    const [categories, setCategories] = useState<string[]>([]);
    useEffect(() => {
        setCategories(props.defaultCategories ?? []);
    }, [props.defaultCategories])
    function updateCategories() {
        if (props.onChange !== undefined && categories !== undefined) {
            props.onChange(categories);
        }
    }
    useEffect(updateCategories, [categories]);
    function updateCategoriesList() {
        const list: string[] = [];
        for (const e of document.querySelectorAll('#categoriesList input') as any) {
            list.push((e as HTMLInputElement).value)
        }
        setCategories(list);
    }

    return (
        <>
            <h2>Post to categories (TODO: Limited to ?? posts per day)</h2>
            <p>TODO: Visual editor of categories</p>
            <ul id="categoriesList">
                {categories.map((cat, i) => {
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