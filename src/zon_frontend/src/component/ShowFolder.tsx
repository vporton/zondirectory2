import * as React from "react";
import { AppData } from "../DataDispatcher";
import { useParams } from "react-router-dom";
// import { zon_backend } from "../../../declarations/zon_backend";

export default function ShowFolder() {
    const { id } = useParams();
    const data = new AppData(id);
    return (
        <>
            <h2>Folder: {data.folderName()}</h2>
        </>
    );
}