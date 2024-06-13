import React, { useState } from "react";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";
import { Items } from "../../../declarations/items/items.did";
import { idlFactory as itemsIdlFactory } from "../../../declarations/items";
import { AuthContext } from "./auth/use-auth-client";
import { Actor, Agent } from "@dfinity/agent";

function DangerZone(props: {agent?: Agent}) {
    const [showDeleteAllModal, setShowDeleteAllModal] = useState(false);
    const [confirmDeleteAll, setConfirmDeleteAll] = useState("");
    const handleCloseDeleteAllDialog = () => setShowDeleteAllModal(false);
    const handleShowDeleteAllDialog = () => setShowDeleteAllModal(true);
    function deleteAllPosts() {
        handleCloseDeleteAllDialog();
        if (confirmDeleteAll === "delete all posts") {
            const backend: Items = Actor.createActor(itemsIdlFactory, {canisterId: process.env.CANISTER_ID_ITEMS!, agent: props.agent});
            backend.deleteAllUserPosts().then(() => {});
        } else {
            alert("You didn't enter confirmation"); // TODO
        }
    }
    return <>
        <div style={{background: 'red', padding: "1ex", color: 'white'}}>
            <h3>Danger Zone</h3>
            <p>DON'T click buttons in this zone, unless you are sure what to do.</p>
            <p>
                <Button onClick={handleShowDeleteAllDialog}>Delete all user info</Button>
            </p>
        </div>
        <Modal show={showDeleteAllModal} onHide={handleCloseDeleteAllDialog}>
            <Modal.Header closeButton style={{background: 'red', color: 'white'}}>
                <Modal.Title>Delete All Posts</Modal.Title>
            </Modal.Header>
            <Modal.Body>
                <p>You are going to delete all your posts. Restoring them after this isn't possible.</p>
                <p>Enter: <q>delete all posts</q> to confirm:<br/>
                    <Form.Control type="text" placeholder="confirmation"
                        onInput={e => setConfirmDeleteAll((e.target as HTMLInputElement).value)}/>
                </p>
            </Modal.Body>
            <Modal.Footer>
                <Button variant="secondary" onClick={handleCloseDeleteAllDialog}>
                    Close
                </Button>
                <Button variant="primary" onClick={deleteAllPosts} style={{background: 'red', color: 'white'}}>
                    Delete
                </Button>
            </Modal.Footer>
        </Modal>
    </>;
}

export default function Prefs() {
    return <>
        <div style={{marginTop: '4ex'}}>
            <h2>Settings</h2>
            <AuthContext.Consumer>
            {({agent}) => <DangerZone agent={agent}/>}
            </AuthContext.Consumer>
        </div>
    </>;
}