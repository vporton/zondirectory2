import * as React from "react";
import 'bootstrap/dist/css/bootstrap.min.css';
import { Component, ErrorInfo, ReactNode, createContext, useEffect, useMemo, useState } from "react";
import { Button, Container, Nav, NavDropdown, Navbar } from 'react-bootstrap';
import ShowItem from "./ShowItem";
import {
    BrowserRouter as Router,
    Route,
    Routes,
    NavLink,
    useNavigate,
    HashRouter,
    useParams,
    Link,
    BrowserRouter,
} from "react-router-dom";
import { Actor, Agent, getDefaultAgent } from '@dfinity/agent';
import SubFolders from "./SubFolders";
import EditItem from "./EditItem";
import EditFolder from "./EditFolder";
import { getIsLocal } from "../util/client";
import { serializeItemRef } from '../data/Data'
import { Principal } from "@dfinity/principal";
import { AuthContext, AuthProvider, useAuth } from './auth/use-auth-client'
import { idlFactory as mainIdlFactory } from "../../../declarations/main";
import { _SERVICE as ZonBackend } from "../../../declarations/main/main.did";
import { Helmet } from 'react-helmet';
import Person from "./personhood/Person";
import { AllItems } from "./AllItems";
import { ErrorBoundary, ErrorHandler } from "./ErrorBoundary";
import { ErrorProvider } from "./ErrorContext";
import Prefs from "./Prefs";
import { MainContext } from './MainContext';

export const BusyContext = createContext<any>(undefined); // TODO: type
 
export default function App() {
    const identityCanister = process.env.CANISTER_ID_INTERNET_IDENTITY;
    const identityProvider = getIsLocal() ? `http://${identityCanister}.localhost:8000` : `https://identity.ic0.app`;
    const [busy, setBusy] = useState(false);
    return (
        <>
            <Helmet>
                <title>Zon Social Media - the world as items in folders</title>
                <meta name="description" content="A fusion of social network, marketplace, and web directory"/>
            </Helmet>
            <Container>
                <p style={{width: '100%', background: 'red', color: 'white', padding: '4px'}}>
                    It is a preliminary beta version. Some features are missing, notably
                    images/media and monetization.
                    Neither security of your data, nor any quality of service is warranted.
                </p>
                <h1>Zon Social Network</h1>
                <AuthProvider options={{loginOptions: {
                    identityProvider,
                    maxTimeToLive: BigInt(3600) * BigInt(1_000_000_000),
                    windowOpenerFeatures: "toolbar=0,location=0,menubar=0,width=500,height=500,left=100,top=100",
                    onSuccess: () => {
                        console.log('Login Successful!');
                    },
                    onError: (error) => {
                        console.error('Login Failed: ', error);
                    },
                }}}>
                    <BrowserRouter>
                        <ErrorProvider>
                            <ErrorBoundary>
                                <BusyContext.Provider value={{busy, setBusy}}>
                                    {busy ? <p>Processing...</p> :
                                    <AuthContext.Consumer>
                                        {({defaultAgent}) => <MyRouted defaultAgent={defaultAgent}/>}
                                    </AuthContext.Consumer>
                                    }
                                </BusyContext.Provider>
                            </ErrorBoundary>
                        </ErrorProvider>
                    </BrowserRouter>
                </AuthProvider>
            </Container>
        </>
    );
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit1(props: {defaultAgent: Agent | undefined, userScore: number | undefined}) {
    const routeParams = useParams();
    return <EditFolder superFolderId={routeParams.folder} defaultAgent={props.defaultAgent} userScore={props.userScore}/>;
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit2(props: {defaultAgent: Agent | undefined, userScore: number | undefined}) {
    const routeParams = useParams();
    return <EditFolder folderId={routeParams.folder} defaultAgent={props.defaultAgent} userScore={props.userScore}/>;
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit3(props: {userScore: number | undefined}) {
    const routeParams = useParams();
    return <EditItem itemId={routeParams.item} userScore={props.userScore}/>;
}

function MyRouted(props: {defaultAgent: Agent | undefined}) {
    const contextValue = useAuth();
    return (
        <AuthContext.Consumer>
            {({isAuthenticated, principal, authClient, defaultAgent, options, login, logout}) =>
                <MainContext.Consumer>
                {({userScore}) =>
                    <MyInner
                        isAuthenticated={isAuthenticated}
                        login={login}
                        logout={logout}
                        principal={principal}
                        defaultAgent={defaultAgent}
                        userScore={userScore}
                    />
                }
                </MainContext.Consumer>
            }
        </AuthContext.Consumer>
    );
}

function MyInner(props: {
    isAuthenticated: boolean,
    login?: (callback?: () => Promise<void>) => void,
    logout?: () => Promise<void>,
    principal?: Principal,
    defaultAgent?: Agent,
    userScore: number | undefined,
}) {
    const navigate = useNavigate();
    const signin = () => {
        props.login!(); // TODO: `!`
    };
    const signout = async () => {
        await props.logout!(); // TODO: `!`
    };
    async function fetchUserScore() {
        // TODO: If we have a hint, skip update call.
        const MainCanister: ZonBackend = Actor.createActor(mainIdlFactory, {canisterId: process.env.CANISTER_ID_MAIN!, agent: props.defaultAgent})
        const data0 = await MainCanister.getUserScore([]); // TODO: hint
        if (data0.length === 0) {
            setUserScore(0);
        } else {
            const [data] = data0;
            let [part, id] = data! as [Principal, bigint];
            setUserScore(Number(id));
        }
    }
    useEffect(() => {
        if (props.principal !== undefined) {
            fetchUserScore().then(() => {});
        }
    }, [props.principal]);
    const [root, setRoot] = useState("");
    async function fetchRootItem() {
        const MainCanister: ZonBackend = Actor.createActor(mainIdlFactory, {canisterId: process.env.CANISTER_ID_MAIN!, agent: props.defaultAgent})
        const data0 = await MainCanister.getRootItem();
        const [data] = data0; // TODO: We assume that it's initialized.
        let [part, id] = data! as [Principal, bigint];
        let item = { canister: part, id: Number(id) };
        setRoot(serializeItemRef(item));
    }
    fetchRootItem().then(() => {});
    function RootRedirector(props: {root: string}) {
        useEffect(() => {
            if (root !== "") {
                navigate("/item/"+root);
            }
        }, [root]);
        return (
            <p>Loading...</p>
        );
    }

    return <>
        <p>
            Logged in as: {props.isAuthenticated ? <small>{props.principal?.toString()}</small> : "(none)"}{" "}
            {props.isAuthenticated
                ? <><Button onClick={signout}>Logout</Button> Your score: {userScore}</>
                : <Button onClick={signin}>Login</Button>}
        </p>
        <nav>
            <Navbar className="bg-body-secondary" style={{width: "auto"}}>
                <Nav>
                    <Nav.Link onClick={() => navigate("/item/"+root)}>Main folder</Nav.Link>{" "}
                </Nav>
                <Nav>
                    <Nav.Link onClick={() => navigate("/latest")}>Latest posts</Nav.Link>{" "}
                </Nav>
                <Nav>
                    <NavDropdown title="User">
                        <NavDropdown.Item onClick={() => navigate("/personhood")}>
                            Verify Your Account
                        </NavDropdown.Item>
                        <NavDropdown.Item onClick={() => navigate("/prefs")}>
                            Settings
                        </NavDropdown.Item>
                    </NavDropdown>
                </Nav>
                <Nav>
                    <Nav.Link href="https://docs.zoncircle.com">Our site</Nav.Link>
                </Nav>
                <Nav>
                    <Nav.Link href="https://docs.zoncircle.com/invest/">Invest</Nav.Link>
                </Nav>
                <Nav>
                    <NavDropdown title="About">
                        <NavDropdown.Item href="https://docs.zoncircle.com/blog-archive/">Blog</NavDropdown.Item>
                        <NavDropdown.Item href="https://docs.zoncircle.com/about-us/">About Us</NavDropdown.Item>
                        <NavDropdown.Item href="https://docs.zoncircle.com/our-partners/">Our Partners</NavDropdown.Item>
                        <NavDropdown.Item href="https://docs.zoncircle.com/#team">The Team</NavDropdown.Item>
                        <NavDropdown.Item href="https://docs.zoncircle.com/carbon-pledge/">Carbon Pledge</NavDropdown.Item>
                    </NavDropdown>
                </Nav>
                <Nav>
                    <NavDropdown title="Blog">
                        <NavDropdown.Item href="https://docs.zoncircle.com/author/user/">CEO's posts</NavDropdown.Item>
                        <NavDropdown.Item href="https://docs.zoncircle.com/social-media/">Social Media</NavDropdown.Item>
                    </NavDropdown>
                </Nav>
            </Navbar>
        </nav>
        <Routes>
            <Route
                path=""
                element={<RootRedirector root={root}/>}
            />
            <Route
                path="/latest"
                element={<AllItems defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/item/:id"
                element={<ShowItem/>}
            />
            <Route
                path="/subfolders-of/:id"
                element={<SubFolders data-dir="sub" defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/superfolders-of/:id"
                element={<SubFolders data-dir="super" defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create"
                element={<EditItem userScore={userScore}/>}
            />
            <Route
                path="/create/for-folder/:folder"
                element={<EditItem userScore={userScore}/>}
            />
            <Route
                path="/create/comment/:folder"
                element={<EditItem comment={true} userScore={userScore}/>}
            />
            <Route
                path="/create-subfolder/for-folder/:folder"
                element={<Edit1 defaultAgent={props.defaultAgent} userScore={userScore}/>}
            />
            <Route
                path="/create-superfolder/for-folder/:folder"
                element={<EditFolder super={true} defaultAgent={props.defaultAgent} userScore={userScore}/>}
            />
            <Route
                path="/edit/folder/:folder"
                element={<Edit2 defaultAgent={props.defaultAgent} userScore={userScore}/>}
            />
            <Route
                path="/edit/item/:item"
                element={<Edit3 userScore={userScore}/>}
            />
            <Route
                path="/personhood"
                element={<Person/>}
            />
            <Route
                path="/prefs"
                element={<Prefs/>}
            />
            <Route path="*" element={<ErrorHandler error={"No such page"}/>}/>
        </Routes>
    </>
}