import * as React from "react";
// import { zon_backend } from "../../../declarations/zon_backend";
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
import SubFolders from "./SubFolders";
 
export default function App() {
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
            </Routes>
        </>
    );
}