import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useParams } from "react-router-dom";
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import { obtainSybilCanister } from '../util/sybil';
import 'react-tabs/style/react-tabs.css';
import { initializeCanDBPartitionClient, initializeMainClient, intializeCanDBIndexClient } from "../util/client";
import { ItemWithoutOwner } from "../../../declarations/backend/backend.did";

export default function Edit() {
    const routeParams = useParams();
    const mainCategory: number | undefined = routeParams.cat !== undefined ? +routeParams.cat : undefined;
    const [locale, setLocale] = useState('en'); // TODO: user's locale
    const [title, setTitle] = useState("");
    const [shortDescription, setShortDescription] = useState("");
    const [link, setLink] = useState(""); // TODO: Check URL validity.
    const [post, setPost] = useState("");
    const [categories, setCategories] = useState(mainCategory === undefined ? [] : [mainCategory]);
    const [categoriesList, setCategoriesList] = useState(mainCategory === undefined ? [] : [mainCategory.toString()]);
    enum SelectedTab {selectedLink, selectedOther}
    const [selectedTab, setSelectedTab] = useState(SelectedTab.selectedLink);
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
    async function submit() {
        function itemData(): ItemWithoutOwner {
            // TODO: Differentiating post and message by `post === ""` is unreliable.
            return {
                locale,
                title,
                description: shortDescription,
                details: selectedTab == SelectedTab.selectedLink ? {link: link} :
                    (post === "" ? {message: null} : {post: post}),
                price: 0.0, // TODO
            };
        }
        async function submitItem(item: ItemWithoutOwner) {
            const isLocal = true; // FIXME
            const sybilCanister = obtainSybilCanister();
            const canDBIndexClient = intializeCanDBIndexClient(isLocal);
            const canDBPartitionClient = initializeCanDBPartitionClient(isLocal, canDBIndexClient);
            const backend = initializeMainClient(isLocal);
            const canisters = await canDBIndexClient.getCanistersForPK(""); // FIXME: PK
            const lastCanister = canisters[canisters.length - 1];
            await backend.createItemData(lastCanister, item, sybilCanister)
        }
        await submitItem(itemData());
    }
    function onSelectTab(index) {
        switch (index) {
            case 0:
                setSelectedTab(SelectedTab.selectedLink);
                break;
            case 0:
                setSelectedTab(SelectedTab.selectedOther);
                break;
            }
    }
    return (
        <>
            <p>Language: <input type="text" required={true} value="en" onChange={e => setLocale(e.target.value)}/></p>
            <p>Title: <input type="text" required={true} onChange={e => setTitle(e.target.value)}/></p>
            <p>Short (meta) description: <textarea onChange={e => setShortDescription(e.target.value)}/></p>
            {/* TODO (should not because complicates ordering?):
            <p>Link type:
                <label><input type="radio" name="kind" value="0" required={true}/> Directory entry</label>
                <label><input type="radio" name="kind" value="1" required={true}/> Message</label></p>*/}
            <Tabs onSelect={onSelectTab}>
                <TabList>
                    <Tab>Link</Tab>
                    <Tab>Blog post</Tab>
                </TabList>
                <TabPanel>
                    <p>Link: <input type="url" onChange={e => setLink(e.target.value)}/></p>
                </TabPanel>
                <TabPanel>
                    <p>Text: <textarea style={{height: "10ex"}} onChange={e => setPost(e.target.value)}/></p>
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
            <p><Button onClick={submit}>Submit</Button></p>
        </>
    );
}