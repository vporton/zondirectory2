import * as React from "react";
// import { zon_backend } from "../../../declarations/zon_backend";
import { Nav } from 'react-bootstrap';
import ShowFolder from "./ShowFolder";
import {
    BrowserRouter as Router,
    Route,
    Routes,
    NavLink,
} from "react-router-dom";
 
export default function App() {
    return (
        <>
            <h1>Zon Dir</h1>
            <Router>
                <nav>
                    <NavLink to="/folder/0">Main folder</NavLink>
                </nav>
                <Routes>
                    <Route
                        path="folder/:id"
                        element={<ShowFolder/>}
                    />
                </Routes>
            </Router>
        </>
    );
}