import * as React from "react";
import { useContext, useEffect, useState } from "react";
// import { backend } from "../../../declarations/backend";
import { Button, Nav } from 'react-bootstrap';
import ShowItem from "./ShowItem";
import {
    BrowserRouter as Router,
    Route,
    Routes,
    NavLink,
    useNavigate,
    HashRouter,
} from "react-router-dom";
import { Agent } from '@dfinity/agent';
import SubFolders from "./SubFolders";
import EditItem from "./EditItem";
import EditCategory from "./EditCategory";
import { getIsLocal, initializeMainClient } from "../util/client";
import { serializeItemRef } from '../data/Data'
// import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { Principal } from "@dfinity/principal";
import { AuthContext, AuthProvider, useAuth } from './auth/use-auth-client'
 
export default function App() {
    const identityCanister = process.env.CANISTER_ID_INTERNET_IDENTITY;
    const identityProvider = getIsLocal() ? `http://localhost:8000/?canisterId=${identityCanister}` : undefined;
    return (
        <>
            <h1>Zon Dir</h1>
            <AuthProvider options={{loginOptions: {
                identityProvider: (getIsLocal() ? `http://localhost:8000/?canisterId=${identityCanister}` : undefined),
                maxTimeToLive: BigInt (7) * BigInt(24) * BigInt(3_600_000_000_000), // 1 week // TODO
                windowOpenerFeatures: "toolbar=0,location=0,menubar=0,width=500,height=500,left=100,top=100",
                onSuccess: () => {
                    console.log('Login Successful!');
                },
                onError: (error) => {
                    console.error('Login Failed: ', error);
                }
            }}}>
                <HashRouter>
                    <MyRouted/>
                </HashRouter>
            </AuthProvider>
        </>
    );
}

function MyRouted() {
    const navigate = useNavigate();
    const [root, setRoot] = useState("");
    let main = initializeMainClient();
    async function fetchRootItem() {
        const data0 = await main.getRootItem();
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
    const contextValue = useAuth();
    return (
        <>
            <AuthContext.Consumer>
                {({isAuthenticated, principal, authClient, defaultAgent, options, login, logout}) => {
                    const signin = () => {
                        login!(); // TODO: `!`
                    };
                    const signout = async () => {
                        await logout!(); // TODO: `!`
                    };
                    return <><p>
                            Logged in as: {isAuthenticated ? <small>{principal?.toString()}</small> : "(none)"}{" "}
                            {isAuthenticated ? <Button onClick={signout}>Logout</Button> : <Button onClick={signin}>Login</Button>}
                        </p>
                        <nav>
                            <NavLink to={"/item/"+root}>Main folder</NavLink>
                        </nav>
                        <Routes>
                            <Route
                                path=""
                                element={<RootRedirector root={root}/>}
                            />
                            <Route
                                path="/item/:id"
                                element={<ShowItem/>}
                            />
                            <Route
                                path="/subfolders-of/:id"
                                element={<SubFolders data-dir="sub" defaultAgent={defaultAgent}/>}
                            />
                            <Route
                                path="/superfolders-of/:id"
                                element={<SubFolders data-dir="super" defaultAgent={defaultAgent}/>}
                            />
                            <Route
                                path="/create/"
                                element={<EditItem/>}
                            />
                            <Route
                                path="/create/for-category/:cat"
                                element={<EditItem/>}
                            />
                            <Route
                                path="/create-subcategory/for-category/:cat"
                                element={<EditCategory/>}
                            />
                        </Routes>
                    </>
            }}
            </AuthContext.Consumer>
        </>
    );
}