import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useParams } from "react-router-dom";
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import { obtainSybilCanister } from '../util/sybil';
import 'react-tabs/style/react-tabs.css';
import { initializeMainClient, intializeCanDBIndexClient } from "../util/client";
import { ItemWithoutOwner } from "../../../declarations/main/main.did";
import Categories from "./Categories";

export default function EditItemItem() {
    const routeParams = useParams();
    const mainCategory: string | undefined = routeParams.cat;
    const [locale, setLocale] = useState('en'); // TODO: user's locale
    const [title, setTitle] = useState("");
    const [shortDescription, setShortDescription] = useState("");
    const [link, setLink] = useState(""); // TODO: Check URL validity.
    const [post, setPost] = useState("");
    enum SelectedTab {selectedLink, selectedOther}
    const [selectedTab, setSelectedTab] = useState(SelectedTab.selectedLink);
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
            // const canDBPartitionClient = initializeCanDBPartitionClient(isLocal, canDBIndexClient);
            const backend = initializeMainClient(isLocal);
            const canisters = await canDBIndexClient.getCanistersForPK("main");
            const lastCanister = canisters[canisters.length - 1];
            let result = await backend.createItemData(lastCanister, item, sybilCanister);
            console.log('XXX:', result); // TODO
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
            <Categories defaultCategories={mainCategory === undefined ? [] : [mainCategory]}/>
            <p><Button onClick={submit}>Submit</Button></p>
        </>
    );
}