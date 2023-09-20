import * as React from "react";
import { useState } from "react";
import { Button } from "react-bootstrap";
import { useParams } from "react-router-dom";
import { Tab, TabList, TabPanel, Tabs } from "react-tabs";
import { ItemWithoutOwner } from "../../../declarations/backend/backend.did";
import { initializeCanDBPartitionClient, initializeMainClient, intializeCanDBIndexClient } from "../util/client";
import { obtainSybilCanister } from "../util/sybil";

export default function EditCategory() {
    const routeParams = useParams();
    const superCategory: number | undefined = routeParams.cat !== undefined ? +routeParams.cat : undefined;
    enum CategoryKind { owned, communal };
    const [categoryKind, setCategoryKind] = useState<CategoryKind>(CategoryKind.owned);
    const [locale, setLocale] = useState('en'); // TODO: user's locale
    const [title, setTitle] = useState("");
    const [shortDescription, setShortDescription] = useState("");
    function onSelectTab(index) {
        switch (index) {
            case 0:
                setCategoryKind(CategoryKind.owned);
                break;
            case 0:
                setCategoryKind(CategoryKind.communal);
                break;
            }
    }
    async function submit() { // FIXME
        function itemData(): ItemWithoutOwner {
            return {
                locale,
                title,
                description: shortDescription,
                details: categoryKind == CategoryKind.owned ? {ownedCategory: null} : {communalCategory: null},
                price: 0.0, // TODO
            };
        }
        async function submitItem(item: ItemWithoutOwner) {
            const isLocal = true; // FIXME
            const sybilCanister = obtainSybilCanister();
            const canDBIndexClient = intializeCanDBIndexClient(isLocal);
            const canDBPartitionClient = initializeCanDBPartitionClient(isLocal, canDBIndexClient);
            const backend = initializeMainClient(isLocal);
            const canisters = await canDBIndexClient.getCanistersForPK("main");
            const lastCanister = canisters[canisters.length - 1];
            await backend.createItemData(lastCanister, item, sybilCanister)
        }
        await submitItem(itemData());
    }
    return (
        <>
            <Tabs onSelect={onSelectTab}>
                <TabList>
                    <Tab>Owned</Tab>
                    <Tab>Communal</Tab>
                </TabList>
                <TabPanel>
                    <p>Owned categories have an owner (you). Only the owner can add, delete, and reoder items in an owned category,{" "}
                        or rename the category.</p>
                    <p>Language: <input type="text" required={true} value="en" onChange={e => setLocale(e.target.value)}/></p>
                    <p>Title: <input type="text" required={true} onChange={e => setTitle(e.target.value)}/></p>
                    <p>Short (meta) description: <textarea onChange={e => setShortDescription(e.target.value)}/></p>
                </TabPanel>
                <TabPanel>
                    <p>Communal categories have no owner. Anybody can add an item to a communal category.{" "}
                        Nobody can delete an item from a communal category or rename the category. Ordering is determined by voting.</p>
                    <p>Language: <input type="text" required={true} value="en" onChange={e => setLocale(e.target.value)}/></p>
                    <p>Title: <input type="text" required={true} onChange={e => setTitle(e.target.value)}/></p>
                </TabPanel>
            </Tabs>
            <Button>Save</Button> {/* TODO */}
        </>
    );
}