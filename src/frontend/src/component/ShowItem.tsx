import * as React from "react";
import { useContext, useEffect, useState } from "react";
import { AppData } from "../DataDispatcher";
import { Link, useNavigate, useParams } from "react-router-dom";
import { AuthContext } from "./auth/use-auth-client";
import { ItemDB, ItemRef, loadTotalVotes, loadUserVote, parseItemRef, serializeItemRef } from "../data/Data";
import ItemType from "./misc/ItemType";
import { Button, Col, Container, Nav, Row } from "react-bootstrap";
import { ItemData, ItemTransfer } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import UpDown, { updateVotes } from "./misc/UpDown";
import { Tab, TabList, TabPanel, Tabs } from "react-tabs";
import { Helmet } from 'react-helmet';
import { Agent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { OnpageNavigation } from "./OnpageNavigation";
import { ErrorContext } from "./ErrorContext";

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

function ShowItemContent(props: {defaultAgent: Agent | undefined}) {
    const { setError } = useContext(ErrorContext)!;
    const { id: idParam } = useParams();
    let idParam2;
    try {
        idParam2 = parseItemRef(idParam!)
    }
    catch(_) {
        setError("404 page not found");
        return;
    }
    const [id, setId] = useState(idParam2);
    useEffect(() => {
        setId(parseItemRef(idParam!))
    }, [idParam]);
    const { principal } = useContext(AuthContext);
    const [locale, setLocale] = useState("");
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [postText, setPostText] = useState("");
    const [type, setType] = useState<string | undefined>(undefined);
    const [creator, setCreator] = useState<Principal | undefined>();
    const [subfolders, setSubfolders] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);
    const [superfolders, setSuperfolders] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);
    const [items, setItems] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);
    const [comments, setComments] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);
    const [antiComments, setAntiComments] = useState<{order: string, id: ItemRef, item: ItemTransfer}[] | undefined>(undefined);
    const [data, setData] = useState<ItemTransfer | undefined>(undefined); // TODO: hack
    const [xdata, setXData] = useState<ItemDB | undefined>(undefined); // TODO: hack
    const [itemsLast, setItemsLast] = useState("");
    const [itemsReachedEnd, setItemsReachedEnd] = useState(false);
    const [commentsLast, setCommentsLast] = useState("");
    const [commentsReachedEnd, setCommentsReachedEnd] = useState(false);
    const [antiCommentsLast, setAntiCommentsLast] = useState("");
    const [antiCommentsReachedEnd, setAntiCommentsReachedEnd] = useState(false);
    const [streamKind, setStreamKind] = useState<"t" | "v">("v"); // time, votes
    const [totalVotesSubFolders, setTotalVotesSubFolders] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteSubFolders, setUserVoteSubFolders] = useState<{[key: string]: number}>({});
    const [totalVotesSuperFolders, setTotalVotesSuperFolders] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteSuperFolders, setUserVoteSuperFolders] = useState<{[key: string]: number}>({});
    const [totalVotesItems, setTotalVotesItems] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteItems, setUserVoteItems] = useState<{[key: string]: number}>({});
    const [totalVotesComments, setTotalVotesComments] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteComments, setUserVoteComments] = useState<{[key: string]: number}>({});
    const [totalVotesCommentsOn, setTotalVotesCommentsOn] = useState<{[key: string]: {up: number, down: number}}>({});
    const [userVoteCommentsOn, setUserVoteCommentsOn] = useState<{[key: string]: number}>({});
    const [startItemsPage, setStartItemsPage] = useState(new Map([
        ["nitems", 5],
    ]));
    const [itemsPage, setItemsPage] = useState(new Map());

    const navigate = useNavigate();
    useEffect(() => {
        setSubfolders(undefined);
        setSuperfolders(undefined);
        setItems(undefined);
        setComments(undefined);
        setAntiComments(undefined);
    }, [id]);
    useEffect(() => {
        props.defaultAgent && subfolders && updateVotes(props.defaultAgent, id, principal, subfolders, setTotalVotesSubFolders, setUserVoteSubFolders).then(() => {});
    }, [subfolders, principal, props.defaultAgent]);
    useEffect(() => {
        props.defaultAgent && superfolders && updateVotes(props.defaultAgent, id, principal, superfolders, setTotalVotesSuperFolders, setUserVoteSuperFolders).then(() => {});
    }, [superfolders, principal, props.defaultAgent]);
    useEffect(() => {
        props.defaultAgent && items && updateVotes(props.defaultAgent, id, principal, items, setTotalVotesItems, setUserVoteItems).then(() => {});
    }, [items, principal, props.defaultAgent]);
    useEffect(() => {
        props.defaultAgent && comments && updateVotes(props.defaultAgent, id, principal, comments, setTotalVotesComments, setUserVoteComments).then(() => {});
    }, [comments, principal, props.defaultAgent]);
    useEffect(() => {
        if (id !== undefined && props.defaultAgent !== undefined) {
            console.log("Loading from AppData");
            try {
                AppData.create(props.defaultAgent, serializeItemRef(id), streamKind).then(data => {
                    setXData(data);
                    setData(data.item);
                    data.locale().then(x => setLocale(x));
                    data.title().then(x => setTitle(x));
                    data.description().then(x => setDescription(x));
                    data.postText().then(x => setPostText(x !== undefined ? x.substring(1) : "")); // strip `t` denoting that it's a text
                    data.creator().then(x => setCreator(x));
                    data.subFolders().then(x => setSubfolders(x));
                    data.superFolders().then(x => {
                        setSuperfolders(x);
                    });
                    data.items({limit: startItemsPage.get("nitems")}).then(x => {
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
                    data.details().then((x) => {
                        setType(Object.keys(x)[0]);
                    });
                })
                    .catch(_ => { // TODO: check error
                        setError("404 page not found"); // duplicate code
                    });
            }
            catch(_) { // TODO: check error
                    setError("404 page not found"); // duplicate code
            };
        }
    }, [id, props.defaultAgent, streamKind]);
    function moreSubfolders(event: any) {
        event.preventDefault();
        navigate(`/subfolders-of/`+serializeItemRef(id))
    }
    function moreSuperfolders(event: any) {
        event.preventDefault();
        navigate(`/superfolders-of/`+serializeItemRef(id))
    }
    function moreItems(event: any) {
        event.preventDefault();
        if (items?.length === 0) {
            return;
        }
        const lowerBound = itemsLast + 'x';
        xdata && xdata.items({lowerBound, limit: 10}).then(x => {
            const newItems = items?.concat(x);
            if (!newItems) {
                return;
            }
            setItems(newItems);
            if (x.length !== 0) {
                setItemsLast(x[x.length - 1].order); // duplicate code
            } else {
                setItemsReachedEnd(true);
            }
            setItemsPage((old) => old.set("nitems", newItems.length));
        });
    }
    function moreComments(event: any) {
        event.preventDefault();
        if (comments?.length === 0) {
            return;
        }
        const lowerBound = commentsLast + 'x';
        xdata?.items({lowerBound, limit: 10}).then(x => {
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
        xdata?.items({lowerBound, limit: 10}).then(x => {
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
    const isFolder = type === 'folder';
    return <>
        <Helmet>
            {idParam && <link rel="canonical" href={`https://zoncircle.com/item/${idParam}`}/>}
            <title>{isFolder ? `${title} (folder) - Zon` : `${title} - Zon`}</title>
            <meta name="description" content={description}/>
            <meta property="og:title" content={isFolder ? `${title} (folder)` : `${title}`}/>
            <meta property="og:author" content={creator?.toText()}/>
            {idParam && <meta property="og:url" content={`https://zoncircle.com/item/${idParam}`}/>}
            <meta property="og:description" content={description}/>
            <meta property="og:locale" content={locale}/>
            <meta property="og:site_name" content="Zon Social Network"/>
            {/*(!superfolders || superfolders.length === 0 ? <meta name="robots" content="noindex"/>)*/} {/* anti-search-spam measure */}
        </Helmet>
        <OnpageNavigation startPage={startItemsPage} page={itemsPage}/>
        <h1>{data !== undefined && <ItemType item={data}/>}{isFolder ? "Folder: " : " "}<span lang={locale}>{title}</span></h1>
        <div data-nosnippet="true">
            <p>Creator: <small>{creator !== undefined && creator.toString()}</small>
                {creator !== undefined && principal !== undefined && creator.compareTo(principal) === 'eq' &&
                    <>
                        {" "}
                        {id && <Button href={`/edit/${isFolder ? 'folder' : 'item'}/${serializeItemRef(id)}`}>Edit</Button>}
                    </>
                }
            </p>
        </div>
        {description !== null ? <p lang={locale}><em>{description}</em></p> : ""}
        {postText !== "" ? <p lang={locale} style={{whiteSpace: 'break-spaces'}}>{postText}</p> : ""}
        <div data-nosnippet="true">
            <p>Sort by:{" "}
                <label><input type="radio" name="stream" value="t" onChange={updateStreamKind} checked={streamKind == "t"}/> time</label>{" "}
                <label><input type="radio" name="stream" value="v" onChange={updateStreamKind} checked={streamKind == "v"}/> votes</label>{" "}
            </p>
        </div>
        <Tabs>
            <TabList>
                <Tab><span data-nosnippet="true">Main content</span></Tab>
                <Tab><span data-nosnippet="true">Comments</span></Tab>
            </TabList>
            <TabPanel>
                <Container>
                    <Row>
                    {!isFolder ? "" : <>
                        <Col>
                            <h3><span data-nosnippet="true">Sub-folders</span></h3>
                            {subfolders === undefined ? <p>Loading...</p> :
                            <ul>
                                {subfolders.map((x: {order: string, id: ItemRef, item: ItemTransfer}) =>
                                    <li lang={x.item.data.item.locale} key={serializeItemRef(x.id as any)}>
                                        {props.defaultAgent && <UpDown
                                            parent={{id}}
                                            item={x}
                                            agent={props.defaultAgent!}
                                            userVote={userVoteSubFolders[serializeItemRef(x.id)]}
                                            totalVotes={totalVotesSubFolders[serializeItemRef(x.id)]}
                                            onSetUserVote={(id: ItemRef, v: number) =>
                                                setUserVoteSubFolders({...userVoteSubFolders, [serializeItemRef(id)]: v})}
                                            onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                                setTotalVotesSubFolders({...totalVotesSubFolders, [serializeItemRef(id)]: v})}
                                            onUpdateList={() => xdata && xdata.subFolders().then(x => setSubfolders(x))}
                                        />}
                                        <ItemType item={x.item}/>
                                        <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>
                                        {" "}
                                        {principal && x.item.data.creator.compareTo(principal) === 'eq' &&
                                            <Button className="edit" href={`/edit/folder/${serializeItemRef(x.id)}`}>Edit</Button>
                                        }
                                    </li>)}
                            </ul>}
                            <nav>
                                <p>
                                    <Link to="#" onClick={e => moreSubfolders(e)}>More...</Link> {id && <Link to={`/create-subfolder/for-folder/${serializeItemRef(id)}`}>Create subfolder</Link>}
                                </p>
                            </nav>
                        </Col>
                    </>}
                        <Col>
                            <h3><span data-nosnippet="true">Super-folders</span></h3>
                            <p><small><span data-nosnippet="true">Voting in this stream not yet implemented.</span></small></p>
                            {superfolders === undefined ? <p>Loading...</p> :
                            <ul>
                                {superfolders.map((x: {order: string, id: ItemRef, item: ItemTransfer}) =>
                                    <li lang={x.item.data.item.locale} key={serializeItemRef(x.id as any)}>
                                        {/* TODO: up/down here is complicated by exchanhing parent/child. */}
                                        {/*<UpDown
                                            parent={{id}}
                                            item={x}
                                            agent={props.defaultAgent}
                                            userVote={userVoteSuperFolders[serializeItemRef(x.id)]}
                                            totalVotes={totalVotesSuperFolders[serializeItemRef(x.id)]}
                                            onSetUserVote={(id: ItemRef, v: number) =>
                                                setUserVoteSuperFolders({...userVoteSuperFolders, [serializeItemRef(id)]: v})}
                                            onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                                setTotalVotesSuperFolders({...totalVotesSubFolders, [serializeItemRef(id)]: v})}
                                            onUpdateList={() => xdata.superFolders().then(x => {
                                                console.log(x)
                                                setSuperfolders(x);
                                            })}
                                        />*/}
                                        <ItemType item={x.item}/>
                                        <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>
                                        {principal !== undefined && x.item.data.creator.compareTo(principal) === 'eq' &&
                                            <>
                                                {" "}
                                                <Button className="edit" href={`/edit/folder/${serializeItemRef(x.id)}`}>Edit</Button>
                                            </>
                                        }
                                    </li>)}
                            </ul>}
                            {/* TODO: Create super-folder */}
                            <nav>
                                <p><Link to="#" onClick={e => moreSuperfolders(e)}>More...</Link> {id && <Link to={`/create-superfolder/for-folder/${serializeItemRef(id)}`}>Create</Link>}</p>
                            </nav>
                        </Col>
                    {!isFolder ? "" : <>
                        <Col>
                            <h3><span data-nosnippet="true">Items</span></h3>
                            {items === undefined ? <p>Loading...</p> : items.map((x: {order: string, id: ItemRef, item: ItemTransfer}) => 
                                <div key={serializeItemRef(x.id)}>
                                    <p lang={x.item.data.item.locale}>
                                        {props.defaultAgent && <UpDown
                                            parent={{id}}
                                            item={x}
                                            agent={props.defaultAgent!}
                                            userVote={userVoteItems[serializeItemRef(x.id)]}
                                            totalVotes={totalVotesItems[serializeItemRef(x.id)]}
                                            onSetUserVote={(id: ItemRef, v: number) =>
                                                setUserVoteItems({...userVoteItems, [serializeItemRef(id)]: v})}
                                            onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                                setTotalVotesItems({...totalVotesItems, [serializeItemRef(id)]: v})}
                                            onUpdateList={() => xdata && xdata.items().then(x => setItems(x))}
                                        />}{" "}
                                        {x.item.data.item.price ? <>({x.item.data.item.price} ICP) </> : ""}
                                        {(x.item.data.item.details as any).link ?
                                            <>
                                                <Link to={(x.item.data.item.details as any).link}>{x.item.data.item.title}</Link>{" "}
                                                <Link to={`/item/${serializeItemRef(x.id)}`}>[H]</Link>
                                            </> :
                                            <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>}
                                        {" "}
                                        {principal !== undefined && x.item.data.creator.compareTo(principal) === 'eq' &&
                                            <Nav.Link className="edit" href={`/edit/item/${serializeItemRef(x.id)}`} style={{display: 'inline'}}><Button>Edit</Button></Nav.Link>
                                        }
                                    </p>
                                    <p lang={x.item.data.item.locale} style={{marginLeft: '1em'}}>{x.item.data.item.description}</p>
                                </div>
                            )}
                            <nav>
                                <p><Link to="#" onClick={e => moreItems(e)} style={{visibility: itemsReachedEnd ? 'hidden' : 'visible'}}>More...</Link>{" "}
                                {id && <Link to={`/create/for-folder/${serializeItemRef(id)}`}>Create</Link>}</p>
                            </nav>
                        </Col>
                    </>}
                    </Row>
                </Container>
            </TabPanel>
            <TabPanel>
                <Container>
                    <Row>
                        <Col>
                            <h3>Comments</h3>
                            {comments === undefined ? <p>Loading...</p> : comments.map(x => 
                                <div key={serializeItemRef(x.id)}>
                                    <p lang={x.item.data.item.locale}>
                                        {props.defaultAgent && <UpDown
                                            parent={{id}}
                                            item={x}
                                            agent={props.defaultAgent!}
                                            userVote={userVoteComments[serializeItemRef(x.id)]}
                                            totalVotes={totalVotesComments[serializeItemRef(x.id)]}
                                            onSetUserVote={(id: ItemRef, v: number) =>
                                                setUserVoteComments({...userVoteComments, [serializeItemRef(id)]: v})}
                                            onSetTotalVotes={(id: ItemRef, v: {up: number, down: number}) =>
                                                setTotalVotesComments({...totalVotesComments, [serializeItemRef(id)]: v})}
                                            onUpdateList={() => xdata && xdata.comments().then(x => setComments(x))}
                                            isComment={true}
                                        />}
                                        {x.item.data.item.price ? <>({x.item.data.item.price} ICP) </> : ""}
                                        {(x.item.data.item.details as any).link ?
                                            <>
                                                <Link to={(x.item.data.item.details as any).link}>{x.item.data.item.title}</Link>{" "}
                                                <Link to={`/item/${serializeItemRef(x.id)}`}>[H]</Link>
                                            </> :
                                            <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>
                                        }
                                        
                                    </p>
                                    <p lang={x.item.data.item.locale} style={{marginLeft: '1em'}}>{x.item.data.item.description}</p>
                                </div>
                            )}
                            <nav>
                                <p><Link to="#" onClick={e => moreComments(e)} style={{visibility: commentsReachedEnd ? 'hidden' : 'visible'}}>More...</Link>{" "}
                                    {id && <Link to={`/create/comment/${serializeItemRef(id)}`}>Create</Link>}</p>
                            </nav>
                        </Col>
                        <Col>
                            <h3>Comment on</h3>
                            <p><small><span data-nosnippet="true">Voting in this stream not yet implemented.</span></small></p>
                            {antiComments === undefined ? <p>Loading...</p> : antiComments.map((x: {order: string, id: ItemRef, item: ItemTransfer}) => 
                                <div key={serializeItemRef(x.id)}>
                                    <p lang={x.item.data.item.locale}>
                                        {x.item.data.item.price ? <>({x.item.data.item.price} ICP) </> : ""}
                                        {(x.item.data.item.details as any).link ?
                                            <>
                                                <Link to={(x.item.data.item.details as any).link}>{x.item.data.item.title}</Link>{" "}
                                                <Link to={`/item/${serializeItemRef(x.id)}`}>[H]</Link>
                                            </> :
                                            <Link to={`/item/${serializeItemRef(x.id)}`}>{x.item.data.item.title}</Link>}
                                    </p>
                                    <p lang={x.item.data.item.locale} style={{marginLeft: '1em'}}>{x.item.data.item.description}</p>
                                </div>
                            )}
                            <nav>
                                <p><Link to="#" onClick={e => moreAntiComments(e)} style={{visibility: antiCommentsReachedEnd ? 'hidden' : 'visible'}}>More...</Link>{" "}</p>
                            </nav>
                        </Col>
                    </Row>
                </Container>
            </TabPanel>
        </Tabs>
    </>
}