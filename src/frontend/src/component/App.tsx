import * as React from "react";
import { useEffect, useState } from "react";
// import { backend } from "../../../declarations/backend";
import { Nav } from 'react-bootstrap';
import ShowFolder from "./ShowFolder";
import {
    BrowserRouter as Router,
    Route,
    Routes,
    NavLink,
    useNavigate,
    HashRouter,
} from "react-router-dom";
import { AuthClient } from '@dfinity/auth-client';
import SubFolders from "./SubFolders";
import EditItem from "./EditItem";
import EditCategory from "./EditCategory";
import { getIsLocal, initializeMainClient } from "../util/client";
import { serializeItemRef } from '../data/Data'
// import { CanDBPartition } from "../../../declarations/CanDBPartition/CanDBPartition.did";
import { Principal } from "@dfinity/principal";
 
export default function App() {
    // TODO
    useEffect(() => {
        async function doIt() {
            const authClient = await AuthClient.create();

            const identityCanister = process.env.CANISTER_ID_INTERNET_IDENTITY;
            authClient.login({
                identityProvider: getIsLocal() ? `http://localhost:8000/?canisterId=${identityCanister}` : undefined,
                maxTimeToLive: BigInt (7) * BigInt(24) * BigInt(3_600_000_000_000), // 1 week // TODO
                windowOpenerFeatures: "toolbar=0,location=0,menubar=0,width=500,height=500,left=100,top=100",
                onSuccess: () => {
                    console.log('Login Successful!');
                    console.log('identity:',
                        authClient.getIdentity().getPrincipal().toString(),
                        '/',
                        authClient.getIdentity().getPrincipal().toText(),
                    )
                },
                onError: (error) => {
                    console.error('Login Failed: ', error);
                }
            });
        }
        doIt().then(()=>{});
    }, []);

    return (
        <>
            <h1>Zon Dir</h1>
            <HashRouter>
                <MyRouted/>
            </HashRouter>
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
    return (
        <>
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
                    element={<ShowFolder/>}
                />
                <Route
                    path="/subfolders-of/:id"
                    element={<SubFolders data-dir="sub"/>}
                />
                <Route
                    path="/superfolders-of/:id"
                    element={<SubFolders data-dir="super"/>}
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
    );
}