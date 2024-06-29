import * as React from "react";
import { useContext, useEffect, useState } from "react";
import { Button } from "react-bootstrap";
import { useNavigate, useParams } from "react-router-dom";
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import { Helmet } from 'react-helmet';
import 'react-tabs/style/react-tabs.css';
import { idlFactory as itemsIdlFactory } from "../../../declarations/items";
import { ItemDataWithoutOwner, Items } from "../../../declarations/items/items.did";
import { idlFactory as canDBPartitionIdlFactory } from "../../../declarations/CanDBPartition";
import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import EditFoldersList from "./EditFoldersList";
import { parseItemRef, serializeItemRef } from "../data/Data";
import { addToMultipleFolders } from "../util/folder";
import { AuthContext } from "./auth/use-auth-client";
import { BusyContext } from "./busy";
import { Actor, Agent } from "@dfinity/agent";
import { ErrorContext } from "./ErrorContext";
import { MainContext, MainContextType } from "./MainContext";

export default function EditItem(props: {
    itemId?: string,
    comment?: boolean,
    defaultAgent: Agent | undefined,
}) {
    const routeParams = useParams();
    const navigate = useNavigate();
    const {fetchUserScore} = useContext<MainContextType>(MainContext);
    const [mainFolder, setMainFolder] = useState<string | undefined>(undefined); // TODO: For a comment, it may be not a folder.
    const [foldersList, setFoldersList] = useState<[string, 'beginning' | 'end'][]>([]);
    const [antiCommentsList, setAntiCommentsList] = useState<[string, 'beginning' | 'end'][]>([]);
    useEffect(() => {
        setMainFolder(routeParams.folder);
    }, [routeParams.folder]);
    enum FolderKind { owned, communal };
    const [folderKind, setFolderKind] = useState<FolderKind>(FolderKind.owned);
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
    const { setError } = useContext(ErrorContext)!;
    useEffect(() => {
        if (props.itemId !== undefined) {
            const itemId = parseItemRef(props.itemId);
            const actor: CanDBPartition = Actor.createActor(canDBPartitionIdlFactory, {canisterId: itemId.canister, agent: props.defaultAgent});
            actor.getItem(BigInt(itemId.id))
                .then(async (itemx) => {
                    const item = itemx ? itemx!.data.item : undefined;
                    const communal = itemx[0]?.communal; // TODO: Simplify.
                    setFolderKind(communal ? FolderKind.communal : FolderKind.owned);
                    setLocale(item!.locale);
                    setTitle(item!.title);
                    setShortDescription(item!.description);
                    console.log(item!.details);
                    if ('post' in item!.details) {
                        setSelectedTab(SelectedTab.selectedOther);
                        const t = (await actor.getAttribute({sk: "i/" + itemId.id}, "t") as any)[0]; // TODO: error handling
                        setPost(t === undefined ? "" : Object.values(t)[0] as string);
                    }
                });
            // actor.getItem(BigInt(itemId.id))
            //     .then((itemx) => {
            //         const item = itemx ? itemx!.data.item : undefined;
            //         const communal = itemx[0]?.communal; // TODO: Simplify.
            //         setFolderKind(communal ? FolderKind.communal : FolderKind.owned);
            //         setLocale(item!.locale);
            //         setTitle(item!.title);
            //         setShortDescription(item!.description);
            //     });
        }
    }, [props.itemId]);
    return (
            <BusyContext.Consumer>
                {({setBusy}) =>
                <AuthContext.Consumer>
                    {({agent, defaultAgent, isAuthenticated}) => {
                    async function submit() {
                        setBusy(true);
                        function itemData(): ItemDataWithoutOwner {
                            // TODO: Differentiating post and message by `post === ""` is unreliable.
                            const isPost = selectedTab == SelectedTab.selectedOther && post !== "";
                            return {
                                // communal: false, // TODO: Item can be communal.
                                locale,
                                title,
                                description: shortDescription,
                                details: selectedTab == SelectedTab.selectedLink ? {link: link} :
                                    isPost ? {post: null} : {message: null},
                                price: 0.0, // TODO
                            };
                        }
                        async function submitItem(item: ItemDataWithoutOwner) {
                            try {
                                const backend: Items = Actor.createActor(itemsIdlFactory, {canisterId: process.env.CANISTER_ID_ITEMS!, agent});
                                let part, n;
                                if (routeParams.item !== undefined) {
                                    const folder = parseItemRef(routeParams.item); // TODO: not here
                                    console.log("QQ", item);
                                    await backend.setItemData(folder.canister, BigInt(folder.id), item, 't'+post);
                                    part = folder.canister;
                                    n = BigInt(folder.id);
                                } else {
                                    [part, n] = await backend.createItemData({data: item, communal: folderKind == FolderKind.communal}, 't'+post);
                                }
                                const ref = serializeItemRef({canister: part, id: Number(n)});
                                // TODO: What to do with this on editing the folder?
                                await addToMultipleFolders(agent!, foldersList, {canister: part, id: Number(n)}, false);
                                await addToMultipleFolders(agent!, antiCommentsList, {canister: part, id: Number(n)}, true);
                                navigate("/item/"+ref);
                                await fetchUserScore!(); // TODO: `!`
                            }
                            catch (e) {
                                if (/Canister trapped explicitly: spam/.test(e)) {
                                    e = "Stop spamming our server.";
                                }
                                setError(e.toString());
                            }
                        }
                        const item = itemData();
                        await submitItem(item);
                        setBusy(false);
                    }
                    async function remove() {
                        if (!window.confirm("Really delete?")) {
                            return;
                        }
                        const backend: Items = Actor.createActor(itemsIdlFactory, {canisterId: process.env.CANISTER_ID_ITEMS!, agent});
                        const folder = parseItemRef(props.itemId!); // TODO: not here
                        await backend.removeItem(folder.canister, BigInt(folder.id));
                        navigate("/");
                    }
                    return <>
                        <Helmet>
                            <meta name="canonical" content="https://zoncircle.com/create"/>
                            <title>Zon Social Media - create a new item</title>
                        </Helmet>
                        <p>Language: <input type="text" required={true} defaultValue={locale} onChange={e => setLocale(e.target.value)}/></p>
                        <p>Title: <input type="text" required={true} defaultValue={title} onChange={e => setTitle(e.target.value)}/></p>
                        <p>Short (meta) description: <textarea defaultValue={shortDescription
                        } onChange={e => setShortDescription(e.target.value)}/></p>
                        {/* TODO (should not because complicates ordering?):
                        <p>Link type:
                            <label><input type="radio" name="kind" value="0" required={true}/> Directory entry</label>
                            <label><input type="radio" name="kind" value="1" required={true}/> Message</label></p>*/}
                        <Tabs onSelect={onSelectTab} selectedIndex={selectedTab === SelectedTab.selectedLink ? 0 : 1}>
                            <TabList>
                                <Tab>Link</Tab>
                                <Tab>Blog post</Tab>
                            </TabList>
                            <TabPanel>
                                <p>Link: <input type="url" defaultValue={link} onChange={e => setLink(e.target.value)}/></p>
                            </TabPanel>
                            <TabPanel>
                                <p>Text: <textarea style={{height: "10ex"}} defaultValue={post} onChange={e => setPost(e.target.value)}/></p>
                            </TabPanel>
                        </Tabs>
                        <EditFoldersList
                            defaultFolders={!(props.comment === true) && mainFolder !== undefined ? [[mainFolder, 'beginning']] : []}
                            defaultAntiComments={props.comment === true && mainFolder !== undefined ? [[mainFolder, 'beginning']] : []}
                            onChangeFolders={setFoldersList}
                            onChangeAntiComments={setAntiCommentsList}
                        />
                        <p>
                            <Button onClick={submit} disabled={!isAuthenticated}>Submit</Button>
                            {props.itemId !== undefined &&
                                <Button onClick={remove} disabled={!isAuthenticated}>Delete</Button>
                            }
                        </p>
                    </>;
                }}
            </AuthContext.Consumer>
            }
        </BusyContext.Consumer>
    );
}