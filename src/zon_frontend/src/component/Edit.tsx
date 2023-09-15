import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useParams } from "react-router-dom";
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import 'react-tabs/style/react-tabs.css';

export default function Edit() {
    const routeParams = useParams();
    const mainCategory: number | undefined = routeParams.cat !== undefined ? +routeParams.cat : undefined;
    const [categories, setCategories] = useState(mainCategory === undefined ? [] : [mainCategory]);
    const [categoriesList, setCategoriesList] = useState(mainCategory === undefined ? [] : [mainCategory.toString()]);
    function updateCategories() {
        setCategories(categoriesList.filter(c => /^[0-9]+$/.test(c)).map(c => +c));
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
            <p>Language: <input type="text" required={true} value="en"/></p>
            <p>Title: <input type="text" required={true}/></p>
            <p>Short (meta) description: <textarea/></p>
            <p>Link type:
                <label><input type="radio" name="kind" value="0" required={true}/> Directory entry</label>
                <label><input type="radio" name="kind" value="1" required={true}/> Message</label></p>
            <Tabs>
                <TabList>
                    <Tab>Link</Tab>
                    <Tab>Blog post</Tab>
                </TabList>
                <TabPanel>
                    <p>Link: <input type="url"/></p>
                </TabPanel>
                <TabPanel>
                    <p>Text: <textarea style={{height: "10ex"}}/></p>
                </TabPanel>
            </Tabs>
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