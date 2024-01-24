import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useNavigate, useParams } from "react-router-dom";
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import 'react-tabs/style/react-tabs.css';
import { ItemWithoutCreator } from "../../../declarations/main/main.did";
import { createActor as mainActor } from "../../../declarations/main";
import EditCategoriesList from "./EditCategoriesList";
import { serializeItemRef } from "../data/Data";
import { addToMultipleCategories } from "../util/category";
import { AuthContext } from "./auth/use-auth-client";
import { BusyContext } from "./App";

export default function EditItemItem(props: {comment?: boolean}) {
    const routeParams = useParams();
    const navigate = useNavigate();
    const [mainCategory, setMainCategory] = useState<string | undefined>(undefined); // TODO: For a comment, it may be not a category.
    const [categoriesList, setCategoriesList] = useState<[string, {beginning: null} | {end: null}][]>([]);
    const [antiCommentsList, setAntiCommentsList] = useState<[string, {beginning: null} | {end: null}][]>([]);
    useEffect(() => {
        setMainCategory(routeParams.cat);
    }, [routeParams.cat]);
    const [locale, setLocale] = useState('en'); // TODO: user's locale
    const [title, setTitle] = useState("");
    const [shortDescription, setShortDescription] = useState("");
    const [link, setLink] = useState(""); // TODO: Check URL validity.
    const [post, setPost] = useState("");
    enum SelectedTab {selectedLink, selectedOther}
    const [selectedTab, setSelectedTab] = useState(SelectedTab.selectedLink);
    function onSelectTab(index) {
        switch (index) {
            case 0:
                setSelectedTab(SelectedTab.selectedLink);
                break;
            case 1:
                setSelectedTab(SelectedTab.selectedOther);
                break;
            }
    }
    return (
            <BusyContext.Consumer>
                {({setBusy}) =>
                <AuthContext.Consumer>
                    {({agent, isAuthenticated}) => {
                    async function submit() {
                        function itemData(): ItemWithoutCreator {
                            // TODO: Differentiating post and message by `post === ""` is unreliable.
                            const isPost = selectedTab == SelectedTab.selectedOther && post !== "";
                            return {
                                locale,
                                title,
                                description: shortDescription,
                                details: selectedTab == SelectedTab.selectedLink ? {link: link} :
                                    isPost ? {post: null} : {message: null},
                                price: 0.0, // TODO
                            };
                        }
                        async function submitItem(item: ItemWithoutCreator) {
                            const backend = mainActor(process.env.CANISTER_ID_MAIN!, {agent});
                            const [part, n] = await backend.createItemData(item);
                            await backend.setPostText(part, n, post);
                            console.log("post:", post);
                            const ref = serializeItemRef({canister: part, id: Number(n)});
                            await addToMultipleCategories(agent!, categoriesList, {canister: part, id: Number(n)}, false);
                            await addToMultipleCategories(agent!, antiCommentsList, {canister: part, id: Number(n)}, true);
                            navigate("/item/"+ref);
                        }
                        setBusy(true);
                        await submitItem(itemData());
                        setBusy(false);
                    }
                    return <>
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
                        <EditCategoriesList
                            defaultCategories={!(props.comment === true) && mainCategory !== undefined ? [[mainCategory, {beginning: null}]] : []}
                            defaultAntiComments={props.comment === true && mainCategory !== undefined ? [[mainCategory, {beginning: null}]] : []}
                            onChangeCategories={setCategoriesList}
                            onChangeAntiComments={setAntiCommentsList}
                        />
                        <p><Button onClick={submit} disabled={!isAuthenticated}>Submit</Button></p>
                    </>;
                }}
            </AuthContext.Consumer>
            }
        </BusyContext.Consumer>
    );
}