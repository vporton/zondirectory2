import * as React from "react";
import { useEffect, useState } from "react";
import { Button, Col, Container, Form, Row } from "react-bootstrap"; // TODO: Import by one component.

export default function EditFoldersList(props: {
    defaultFolders?: [string, {beginning: null} | {end: null}][],
    defaultAntiComments?: [string, {beginning: null} | {end: null}][],
    onChangeFolders?: (folders: [string, {beginning: null} | {end: null}][]) => void,
    onChangeAntiComments?: (folders: [string, {beginning: null} | {end: null}][]) => void,
    noComments?: boolean,
    reverse?: boolean,
}) {
    const [folders, setFolders] = useState<[string, {beginning: null} | {end:null}][] | undefined>(undefined);
    const [antiComments, setAntiComments] = useState<[string, {beginning: null} | {end: null}][] | undefined>(undefined);
    enum SideType { beginning, end };
    const [side, setSide] = useState<SideType>(SideType.beginning);
    useEffect(() => {
        if (folders === undefined && props.defaultFolders?.length !== 0) {
            setFolders(props.defaultFolders ?? []);
        }
    }, [props.defaultFolders])
    useEffect(() => {
        if (antiComments === undefined && props.defaultAntiComments?.length !== 0) {
            setAntiComments(props.defaultAntiComments ?? []);
        }
    }, [props.defaultAntiComments])
    function updateFolders() {
        if (props.onChangeFolders !== undefined && folders !== undefined) {
            props.onChangeFolders(folders);
        }
    }
    function updateAntiComments() {
        if (props.onChangeAntiComments !== undefined && antiComments !== undefined) {
            props.onChangeAntiComments(antiComments);
        }
    }
    useEffect(updateFolders, [folders]);
    useEffect(updateAntiComments, [antiComments]);
    function updateFoldersList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#foldersList input[class=form-control]') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        const list2: ({beginning: null} | {end: null})[] = [];
        for (const e of document.querySelectorAll('#foldersList input[type=radio]:checked') as any) {
            const value = (e as HTMLInputElement).value;
            list2.push(value === 'beginning' ? {beginning: null} : {end: null});
        }
        const list3 = list.map(function(e, i) {
            const v: [string, {beginning: null} | {end:null}] = [e, list2[i]];
            return v;
        });
        console.log("ZZZ", list3)
        setFolders(list3);
    }
    function updateAntiCommentsList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#antiCommentsList input[class=form-control]') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        const list2: ({beginning: null} | {end: null})[] = [];
        for (const e of document.querySelectorAll('#antiCommentsList input[type=radio]:checked') as any) {
            const value = (e as HTMLInputElement).value;
            list2.push(value === 'beginning' ? {beginning: null} : {end: null});
        }
        const list3 = list.map(function(e, i) {
            const v: [string, {beginning: null} | {end:null}] = [e, list2[i]];
            return v;
        });
        setAntiComments(list3);
    }
    function onSideChanged(e) {
        setSide(e.currentTarget.value == 'beginning' ? SideType.beginning : SideType.end);
    }

    return (
        <>
            <h2>{props.reverse ? `Folders to post` : `Post to folders`}</h2>
            <p>TODO: Visual editor of folders; TODO: Limited to ?? posts per day; TODO: begin/end works only for owned folders</p>
            <Container>
                <Row>
                    <Col>
                        <h3>Folders</h3>
                        <ul id="foldersList">
                            {(folders ?? []).map((cat, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control value={cat[0]} onChange={updateFoldersList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setFolders(folders!.filter((item) => item !== cat))}>Delete</Button>{" "}
                                        <label><input type="radio" name="side" checked={side === SideType.beginning}
                                            onChange={onSideChanged}/>&#160;beginning</label>{" "}
                                        <label><input type="radio" name="side" checked={side === SideType.end}
                                            onChange={onSideChanged}/>&#160;end</label>
                                    </li>
                                );
                            })}
                        </ul>
                        <p><Button disabled={folders === undefined} onClick={() => setFolders(folders!.concat([["", {beginning: null}]]))}>Add</Button></p>
                    </Col>
                    {!props.noComments &&
                    <Col>
                        <h3>Comment to</h3>
                        <ul id="antiCommentsList">
                            {(antiComments ?? []).map((cat, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control value={cat[0]} onChange={updateAntiCommentsList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setAntiComments(antiComments!.filter((item) => item !== cat))}>Delete</Button>
                                    </li>
                                );
                            })}
                        </ul>
                        <p><Button disabled={antiComments === undefined} onClick={() => setAntiComments(antiComments!.concat([["", {beginning: null}]]))}>Add</Button></p>
                    </Col>}
                </Row>
            </Container>
        </>
    );
}