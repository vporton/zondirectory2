import * as React from "react";
import { useContext, useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { useNavigate, useParams } from "react-router-dom";
import { AuthContext } from "./auth/use-auth-client";
import { ItemRef, loadTotalVotes, loadUserVote, parseItemRef, serializeItemRef } from "../DataDispatcher";;
import ItemType from "./misc/ItemType";
import { Button } from "react-bootstrap";
import { ItemInfo } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { order } from "../../../declarations/order";
import UpDown, { updateVotes } from "./misc/UpDown";
import { Tab, TabList, TabPanel, Tabs } from "react-tabs";

export default function ShowItem() {
    return (
        <>
            <AuthContext.Consumer>
                {({defaultAgent}) => {
                    return <ShowItemContent defaultAgent={defaultAgent}/>
                }}
            </AuthContext.Consumer>
        </>
    );
}

function ShowItemContent(props: {defaultAgent}) {
    const { id: idParam } = useParams();
    const [id, setId] = useState(parseItemRef(idParam!));
    useEffect(() => {
        setId(parseItemRef(idParam!))
    }, [idParam]);
    const { principal } = useContext(AuthContext) as any;
    const [locale, setLocale] = useState("");
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [postText, setPostText] = useState("");
    const [type, setType] = useState<string | undefined>(undefined);
    const [creator, setCreator] = useState("");
    const [subcategories, setSubcategories] = useState<{order: string, id: ItemRef, item: ItemInfo}[] | undefined>(undefined);
    const [supercategories, setSupercategories] = useState<{order: string, id: ItemRef, item: ItemInfo}[] | undefined>(undefined);
    const [items, setItems] = useState<{order: string, id: ItemRef, item: ItemInfo}[] | undefined>(undefined);
    const [comments, setComments] = useState<{order: string, id: ItemRef, item: ItemInfo}[] | undefined>(undefined);
    const [antiComments, setAntiComments] = useState<{order: string, id: ItemRef, item: ItemInfo}[] | undefined>(undefined);
    const [data, setData] = useState<any>(undefined); // TODO: hack
    const [xdata, setXData] = useState<any>(undefined); // TODO: hack
    const [itemsLast, setItemsLast] = useState("");
    const [itemsReachedEnd, setItemsReachedEnd] = useState(false);
    const [commentsLast, setCommentsLast] = useState("");
    const [commentsReachedEnd, setCommentsReachedEnd] = useState(false);
    const [antiCommentsLast, setAntiCommentsLast] = useState("");
    const [antiCommentsReachedEnd, setAntiCommentsReachedEnd] = useState(false);
    const [streamKind, setStreamKind] = useState<"t" | "v">("v"); // time, votes
    const [totalVotesSubCategories, setTotalVotesSubCategories] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteSubCategories, setUserVoteSubCategories] = useState<{[key: string]: number}>({});
    const [totalVotesSuperCategories, setTotalVotesSuperCategories] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteSuperCategories, setUserVoteSuperCategories] = useState<{[key: string]: number}>({});
    const [totalVotesItems, setTotalVotesItems] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteItems, setUserVoteItems] = useState<{[key: string]: number}>({});
    const [totalVotesComments, setTotalVotesComments] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteComments, setUserVoteComments] = useState<{[key: string]: number}>({});
    const [totalVotesCommentsOn, setTotalVotesCommentsOn] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteCommentsOn, setUserVoteCommentsOn] = useState<{[key: string]: number}>({});

    const navigate = useNavigate();
    useEffect(() => {
        setSubcategories(undefined);
        setSupercategories(undefined);
        setItems(undefined);
        setComments(undefined);
        setAntiComments(undefined);
    }, [id]);
    useEffect(() => {
        updateVotes(id, principal, subcategories!, setTotalVotesSubCategories, setUserVoteSubCategories).then(() => {}); // TODO: `!`
    }, [subcategories, principal]);
    useEffect(() => {
        updateVotes(id, principal, supercategories!, setTotalVotesSuperCategories, setUserVoteSuperCategories).then(() => {}); // TODO: `!`
    }, [supercategories, principal]);
    useEffect(() => {
        updateVotes(id, principal, items!, setTotalVotesItems, setUserVoteItems).then(() => {}); // TODO: `!`
    }, [items, principal]);
    useEffect(() => {
        updateVotes(id, principal, comments!, setTotalVotesComments, setUserVoteComments).then(() => {}); // TODO: `!`
    }, [comments, principal]);
    useEffect(() => { // TODO
        if (id !== undefined) {
            console.log("Loading from AppData");
            AppData.create(props.defaultAgent, serializeItemRef(id), streamKind).then(data => {
                setXData(data);
                setData(data); // TODO: superfluous
                data.locale().then(x => setLocale(x));
                data.title().then(x => setTitle(x));
                data.description().then(x => setDescription(x));
                data.postText().then(x => setPostText(x!)); // TODO: `!`
                data.creator().then(x => setCreator(x.toString())); // TODO
                data.subCategories().then(x => setSubcategories(x));
                data.superCategories().then(x => {
                    setSupercategories(x);
                });
                data.items().then(x => {
                    setItems(x);
                    if (x.length !== 0) {
                        setItemsLast(x[x.length - 1].order); // duplicate code
                    }
                });
                data.comments().then(x => {
                    setComments(x);
                    if (x.length !== 0) {
                        setCommentsLast(x[x.length - 1].order); // duplicate code
                    }
                });
                data.antiComments().then(x => {
                    setAntiComments(x);
                    if (x.length !== 0) {
                        setAntiCommentsLast(x[x.length - 1].order); // duplicate code
                    }
                });
                data.kind().then((x) => {
                    setType(Object.keys(x)[0]);
                });
            });
        }
    }, [id, props.defaultAgent, streamKind]); // TODO: more tight choice
    function moreSubcategories(event: any) {
        event.preventDefault();
        navigate(`/subfolders-of/`+serializeItemRef(id))
    }
    function moreSupercategories(event: any) {
        event.preventDefault();
        navigate(`/superfolders-of/`+serializeItemRef(id))
    }
    function moreItems(event: any) {
        event.preventDefault();
        if (items?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        xdata.items({lowerBound, limit: 10}).then(x => {
            setItems(items?.concat(x));
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            } else {
                setItemsReachedEnd(true);
            }
        });
    }
    function moreComments(event: any) {
        event.preventDefault();
        if (comments?.length === 0) {
            return;
        }
        const lowerBound = commentsLast + 'x';
        xdata.items({lowerBound, limit: 10}).then(x => {
            setItems(comments?.concat(x));
            if (x.length !== 0) {
                setCommentsLast(x[x.length - 1].order); // duplicate code
            } else {
                setCommentsReachedEnd(true);
            }
        });
    }
    function moreAntiComments(event: any) {
        event.preventDefault();
        if (antiComments?.length === 0) {
            return;
        }
        const lowerBound = antiCommentsLast + 'x';
        xdata.items({lowerBound, limit: 10}).then(x => {
            setItems(antiComments?.concat(x));
            if (x.length !== 0) {
                setAntiCommentsLast(x[x.length - 1].order); // duplicate code
            } else {
                setAntiCommentsReachedEnd(true);
            }
        });
    }
    function updateStreamKind(e) {
        setStreamKind(e.currentTarget.value);
    }
    const isCategory = type === 'ownedCategory' || type === 'communalCategory';
    return <>
        <h2><ItemType item={data}/>{isCategory ? "Folder: " : " "}<span lang={locale}>{title}</span></h2>
        <p>Creator: <small>{creator.toString()}</small></p>
        {description !== null ? <p lang={locale}>{description}</p> : ""}
        {postText !== "" ? <p lang={locale}>{postText}</p> : ""}
        <p>Sort by:{" "}
            <label><input type="radio" name="stream" value="t" onChange={updateStreamKind} checked={streamKind == "t"}/> time</label>{" "}
            <label><input type="radio" name="stream" value="v" onChange={updateStreamKind} checked={streamKind == "v"}/> votes</label>{" "}
        </p>
        <Tabs>
            <TabList>
                <Tab>Main content</Tab>
                <Tab>Comments</Tab>
            </TabList>
            <TabPanel>
                {!isCategory ? "" : <>
                <h3>Sub-folders</h3>
                {subcategories === undefined ? <p>Loading...</p> :
                <ul>
                    {subcategories.map((x: {order: string, id: ItemRef, item: ItemInfo}) =>
                        <li lang={x.item.locale} key={serializeItemRef(x.id as any)}>
                            <UpDown
                                parent={{id}}
                                item={x}
                                agent={props.defaultAgent}
                                userVote={userVoteSubCategories[serializeItemRef(x.id)]}
                                totalVotes={totalVotesSubCategories[serializeItemRef(x.id)]}
                                onSetUserVote={(id: ItemRef, v: number) =>
                                    setUserVoteSubCategories({...userVoteSubCategories, [serializeItemRef(id)]: v})}
                                onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                    setTotalVotesSubCategories({...totalVotesSubCategories, [serializeItemRef(id)]: v})}
                                onUpdateList={() => xdata.subCategories().then(x => setSubcategories(x))}
                            />
                            <ItemType item={x.item}/>
                            <a href={`#/item/${serializeItemRef(x.id)}`}>{x.item.title}</a>
                        </li>)}
                </ul>}
                <p><a href="#" onClick={e => moreSubcategories(e)}>More...</a> <a href={`#/create-subcategory/for-category/${serializeItemRef(id)}`}>Create subfolder</a></p>
            </>}
            <h3>Super-folders</h3>
            <p><small>Voting in this stream not yet implemented.</small></p>
            {supercategories === undefined ? <p>Loading...</p> :
            <ul>
                {supercategories.map((x: {order: string, id: ItemRef, item: ItemInfo}) =>
                    <li lang={x.item.locale} key={serializeItemRef(x.id as any)}>
                        {/* TODO: up/down here is complicated by exchanhing parent/child. */}
                        {/*<UpDown
                            parent={{id}}
                            item={x}
                            agent={props.defaultAgent}
                            userVote={userVoteSuperCategories[serializeItemRef(x.id)]}
                            totalVotes={totalVotesSuperCategories[serializeItemRef(x.id)]}
                            onSetUserVote={(id: ItemRef, v: number) =>
                                setUserVoteSuperCategories({...userVoteSuperCategories, [serializeItemRef(id)]: v})}
                            onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                setTotalVotesSuperCategories({...totalVotesSubCategories, [serializeItemRef(id)]: v})}
                            onUpdateList={() => xdata.superCategories().then(x => {
                                console.log(x)
                                setSupercategories(x);
                            })}
                        />*/}
                        <ItemType item={x.item}/>
                        <a href={`#/item/${serializeItemRef(x.id)}`}>{x.item.title}</a>
                    </li>)}
            </ul>}
            {/* TODO: Create super-category */}
            <p><a href="#" onClick={e => moreSupercategories(e)}>More...</a> <a href={`#/create-supercategory/for-category/${serializeItemRef(id)}`}>Create</a></p>
            {!isCategory ? "" : <>
                <h3>Items</h3>
                {items === undefined ? <p>Loading...</p> : items.map((x: {order: string, id: ItemRef, item: ItemInfo}) => 
                    <div key={serializeItemRef(x.id)}>
                        <p lang={x.item.locale}>
                            <UpDown
                                parent={{id}}
                                item={x}
                                agent={props.defaultAgent}
                                userVote={userVoteItems[serializeItemRef(x.id)]}
                                totalVotes={totalVotesItems[serializeItemRef(x.id)]}
                                onSetUserVote={(id: ItemRef, v: number) =>
                                    setUserVoteItems({...userVoteItems, [serializeItemRef(id)]: v})}
                                onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                    setTotalVotesItems({...totalVotesItems, [serializeItemRef(id)]: v})}
                                onUpdateList={() => xdata.items().then(x => setItems(x))}
                            />{" "}
                            {x.item.price ? <>({x.item.price} ICP) </> : ""}
                            {x.item.link.length !== 0 ? <a href={x.item.link[0]}>{x.item.title}</a> : x.item.title}
                            {" "}<a href={`#/item/${serializeItemRef(x.id)}`} title="Homepage">[H]</a>
                        </p>
                        <p lang={x.item.locale} style={{marginLeft: '1em'}}>{x.item.description}</p>
                    </div>
            )}
            <p><a href="#" onClick={e => moreItems(e)} style={{visibility: itemsReachedEnd ? 'hidden' : 'visible'}}>More...</a>{" "}
                <a href={`#/create/for-category/${serializeItemRef(id)}`}>Create</a></p></>}
            </TabPanel>
            <TabPanel>
                <h3>Comments</h3>
                {comments === undefined ? <p>Loading...</p> : comments.map(x => 
                    <div key={serializeItemRef(x.id)}>
                        <p lang={x.item.locale}>
                            <UpDown
                                parent={{id}}
                                item={x}
                                agent={props.defaultAgent}
                                userVote={userVoteComments[serializeItemRef(x.id)]}
                                totalVotes={totalVotesComments[serializeItemRef(x.id)]}
                                onSetUserVote={(id: ItemRef, v: number) =>
                                    setUserVoteComments({...userVoteComments, [serializeItemRef(id)]: v})}
                                onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                    setTotalVotesComments({...totalVotesComments, [serializeItemRef(id)]: v})}
                                onUpdateList={() => xdata.comments().then(x => setComments(x))}
                                isComment={true}
                            />
                            {x.item.price ? <>({x.item.price} ICP) </> : ""}
                            {x.item.link.length !== 0 ? <a href={x.item.link[0]}>{x.item.title}</a> : x.item.title}
                            {" "}<a href={`#/item/${serializeItemRef(x.id)}`} title="Homepage">[H]</a>
                        </p>
                        <p lang={x.item.locale} style={{marginLeft: '1em'}}>{x.item.description}</p>
                    </div>
                )}
                <p><a href="#" onClick={e => moreComments(e)} style={{visibility: commentsReachedEnd ? 'hidden' : 'visible'}}>More...</a>{" "}
                    <a href={`#/create/comment/${serializeItemRef(id)}`}>Create</a></p>
                <h3>Comment on</h3>
                <p><small>Voting in this stream not yet implemented.</small></p>
                {antiComments === undefined ? <p>Loading...</p> : antiComments.map((item: {order: string, id: ItemRef, item: ItemInfo}) => 
                    <div key={serializeItemRef(item.id)}>
                        <p lang={item.item.locale}>
                            {item.item.price ? <>({item.item.price} ICP) </> : ""}
                            {item.item.link.length !== 0 ? <a href={item.item.link[0]}>{item.item.title}</a> : item.item.title}
                            {" "}<a href={`#/item/${serializeItemRef(item.id)}`} title="Homepage">[H]</a>
                        </p>
                        <p lang={item.item.locale} style={{marginLeft: '1em'}}>{item.item.description}</p>
                    </div>
                )}
                <p><a href="#" onClick={e => moreAntiComments(e)} style={{visibility: antiCommentsReachedEnd ? 'hidden' : 'visible'}}>More...</a>{" "}</p>
            </TabPanel>
        </Tabs>
    </>
}