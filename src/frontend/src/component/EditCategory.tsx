import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useNavigate, useParams } from "react-router-dom";
import { Tab, TabList, TabPanel, Tabs } from "react-tabs";
import { ItemWithoutOwner } from "../../../declarations/main/main.did";
import { createActor as mainActor } from "../../../declarations/main";
import EditCategoriesList from "./EditCategoriesList";
import { addToCategory, addToMultipleCategories } from "../util/category";
import { parseItemRef, serializeItemRef } from "../data/Data";
import { AuthContext } from "./auth/use-auth-client";

export default function EditCategory(props: {super?: boolean}) {
    const routeParams = useParams(); // TODO: a dynamic value
    const navigate = useNavigate();
    const [superCategory, setSuperCategory] = useState<string | undefined>();
    const [categoriesList, setCategoriesList] = useState<string[]>([]);
    const [antiCommentsList, setAntiCommentsList] = useState<string[]>([]);
    useEffect(() => {
        setSuperCategory(routeParams.cat);
    }, [routeParams.cat])
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
            case 1:
                setCategoryKind(CategoryKind.communal);
                break;
            }
    }
    return (
        <AuthContext.Consumer>
            {({agent, isAuthenticated}) => {
                async function submit() {
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
                        const backend = mainActor(process.env.CANISTER_ID_MAIN!, {agent});
                        const [part, n] = await backend.createItemData(item);
                        const ref = serializeItemRef({canister: part, id: Number(n)});
                        if (!(props.super === true)) { // noComments
                            await addToMultipleCategories(agent!, categoriesList, {canister: part, id: Number(n)}, false);
                            await addToMultipleCategories(agent!, antiCommentsList, {canister: part, id: Number(n)}, true);
                        } else {
                            for (const catStr of categoriesList) {
                                // TODO: It may fail to parse.
                                await addToCategory(agent!, {canister: part, id: Number(n)}, parseItemRef(catStr), false);
                            }
                        }
                        navigate("/item/"+ref);
                    }
                    await submitItem(itemData());
                }
                return <>
                    <h1>{props.super === true ? `Create supercategory` : `Create subcategory`}</h1>
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
                    <EditCategoriesList
                        defaultCategories={superCategory === undefined ? [] : [superCategory]}
                        onChangeCategories={setCategoriesList}
                        onChangeAntiComments={setAntiCommentsList}
                        reverse={props.super === true}
                        noComments={props.super === true}
                    />
                    <Button onClick={submit} disabled={!isAuthenticated}>Save</Button>
                </>
            }}
        </AuthContext.Consumer>
    );
}