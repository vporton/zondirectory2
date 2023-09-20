import * as React from "react";
import { useEffect } from "react";
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
 
export default function App() {
    useEffect(() => {
        async function doIt() {
            const authClient = await AuthClient.create();

            authClient.login({
                // 7 days in nanoseconds
                maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
                onSuccess: async () => {
                  console.log('ID');
                },
                onError(error) {
                    console.log('error', error);
                },
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
    React.useEffect(() => navigate("/folder/0"), []);
    return (
        <>
            <nav>
                <NavLink to="/folder/0">Main folder</NavLink>
            </nav>
            <Routes>
                <Route
                    path="/folder/:id"
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