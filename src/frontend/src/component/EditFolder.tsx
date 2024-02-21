import * as React from "react";
import { useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useNavigate, useParams } from "react-router-dom";
import { Tab, TabList, TabPanel, Tabs } from "react-tabs";
import { Helmet } from 'react-helmet';
import { ItemWithoutOwner } from "../../../declarations/main/main.did";
import { createActor as mainActor } from "../../../declarations/main";
import EditFoldersList from "./EditFoldersList";
import { addToFolder, addToMultipleFolders } from "../util/folder";
import { parseItemRef, serializeItemRef } from "../data/Data";
import { AuthContext } from "./auth/use-auth-client";
import { BusyContext } from "./App";

export default function EditFolder(props: {super?: boolean}) {
    const routeParams = useParams(); // TODO: a dynamic value
    const navigate = useNavigate();
    const [superFolder, setSuperFolder] = useState<string | undefined>();
    const [foldersList, setFoldersList] = useState<[string, 'beginning' | 'end'][]>([]);
    const [antiCommentsList, setAntiCommentsList] = useState<[string, 'beginning' | 'end'][]>([]);
    useEffect(() => {
        setSuperFolder(routeParams.cat);
    }, [routeParams.cat])
    enum FolderKind { owned, communal };
    const [folderKind, setFolderKind] = useState<FolderKind>(FolderKind.owned);
    const [locale, setLocale] = useState('en'); // TODO: user's locale
    const [title, setTitle] = useState("");
    const [shortDescription, setShortDescription] = useState("");
    function onSelectTab(index) {
        switch (index) {
            case 0:
                setFolderKind(FolderKind.owned);
                break;
            case 1:
                setFolderKind(FolderKind.communal);
                break;
            }
    }
    return (
        <BusyContext.Consumer>
        {({setBusy}) =>
            <AuthContext.Consumer>
            {({agent, isAuthenticated}) => {
                async function submit() {
                    function itemData(): ItemWithoutOwner {
                        return {
                            locale,
                            title,
                            description: shortDescription,
                            details: folderKind == FolderKind.owned ? {ownedFolder: null} : {communalFolder: null},
                            price: 0.0, // TODO
                        };
                    }
                    async function submitItem(item: ItemWithoutOwner) {
                        const backend = mainActor(process.env.CANISTER_ID_MAIN!, {agent});
                        const [part, n] = await backend.createItemData(item);
                        const ref = serializeItemRef({canister: part, id: Number(n)});
                        if (!(props.super === true)) { // noComments
                            await addToMultipleFolders(agent!, foldersList, {canister: part, id: Number(n)}, false);
                            await addToMultipleFolders(agent!, antiCommentsList, {canister: part, id: Number(n)}, true);
                        } else {
                            for (const cat of foldersList) {
                                // TODO: It may fail to parse.
                                await addToFolder(agent!, {canister: part, id: Number(n)}, parseItemRef(cat[0]), false, cat[1]);
                            }
                        }
                        navigate("/item/"+ref);
                    }
                    setBusy(true);
                    await submitItem(itemData());
                    setBusy(false);
            }
                return <>
                    <Helmet>
                        <title>Zon Social Media - create a new folder</title>
                    </Helmet>
                    <h1>{props.super === true ? `Create superfolder` : `Create subfolder`}</h1>
                    <Tabs onSelect={onSelectTab}>
                        <TabList>
                            <Tab>Owned</Tab>
                            <Tab>Communal</Tab>
                        </TabList>
                        <TabPanel>
                            <p>Owned folders have an owner (you). Only the owner can add, delete, and reoder items in an owned folder,{" "}
                                or rename the folder.</p>
                            <p>Language: <input type="text" required={true} value="en" onChange={e => setLocale(e.target.value)}/></p>
                            <p>Title: <input type="text" required={true} onChange={e => setTitle(e.target.value)}/></p>
                            <p>Short (meta) description: <textarea onChange={e => setShortDescription(e.target.value)}/></p>
                        </TabPanel>
                        <TabPanel>
                            <p>Communal folders have no owner. Anybody can add an item to a communal folder.{" "}
                                Nobody can delete an item from a communal folder or rename the folder. Ordering is determined by voting.</p>
                            <p>Language: <input type="text" required={true} value="en" onChange={e => setLocale(e.target.value)}/></p>
                            <p>Title: <input type="text" required={true} onChange={e => setTitle(e.target.value)}/></p>
                        </TabPanel>
                    </Tabs>
                    <EditFoldersList
                        defaultFolders={superFolder === undefined ? [] : [[superFolder, 'beginning']]}
                        onChangeFolders={setFoldersList}
                        onChangeAntiComments={setAntiCommentsList}
                        reverse={props.super === true}
                        noComments={props.super === true}
                    />
                    <Button onClick={submit} disabled={!isAuthenticated}>Save</Button>
                </>
            }}
            </AuthContext.Consumer>
        }
        </BusyContext.Consumer>
    );
}