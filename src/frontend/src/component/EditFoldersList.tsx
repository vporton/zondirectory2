import * as React from "react";
import { useContext, useEffect, useState } from "react";
import { Button, Col, Container, Form, Row } from "react-bootstrap"; // TODO: Import by one component.
import { MainContext, MainContextType } from "./MainContext";

export default function EditFoldersList(props: {
    defaultFolders?: [string, 'beginning' | 'end'][],
    defaultAntiComments?: [string, 'beginning' | 'end'][],
    onChangeFolders?: (folders: [string, 'beginning' | 'end'][]) => void,
    onChangeAntiComments?: (folders: [string, 'beginning' | 'end'][]) => void,
    noComments?: boolean,
    reverse?: boolean,
}) {
    const {userScore} = useContext<MainContextType>(MainContext);
    const [folders, _setFolders] = useState<[string, 'beginning' | 'end'][] | undefined>(undefined);
    const [antiComments, _setAntiComments] = useState<[string, 'beginning' | 'end'][] | undefined>(undefined);
    const [side, setSide] = useState<{ [i: number]: 'beginning' | 'end' }>({});
    function setFolders(data: [string, 'beginning' | 'end'][]) {
        if ((folders?.length ?? 0) + (antiComments?.length ?? 0) > (userScore ?? 0) + Number(process.env.REACT_APP_POST_SCORE)) {
            alert(`Can't add more folders because you have a low score!`);
        }
        _setFolders(data);
    }
    function setAntiComments(data: [string, 'beginning' | 'end'][]) {
        if ((folders?.length ?? 0) + (antiComments?.length ?? 0) > (userScore ?? 0) + Number(process.env.REACT_APP_POST_SCORE)) {
            alert(`Can't add more folders because you have a low score!`);
        }
        _setAntiComments(data);
    }
    useEffect(() => {
        if (folders === undefined && props.defaultFolders !== undefined) {
            setFolders(props.defaultFolders ?? []);
        }
    }, [props.defaultFolders])
    useEffect(() => {
        if (antiComments === undefined && props.defaultAntiComments !== undefined) {
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
        // if (props.defaultFolders !== undefined) {
        //     return;
        // }

        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#foldersList input[class=form-control]') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        const list2: ('beginning' | 'end')[] = [];
        for (const e of document.querySelectorAll('#foldersList input[type=radio]:checked') as any) {
            const value = (e as HTMLInputElement).value;
            list2.push(value === 'beginning' ? 'beginning' : 'end');
        }
        const list3 = list.map(function(e, i) {
            const v: [string, 'beginning' | 'end'] = [e, list2[i]];
            return v;
        });
        setFolders(list3);
    }
    function updateAntiCommentsList() {
        if (props.defaultAntiComments !== undefined) {
            return;
        }

        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#antiCommentsList input[class=form-control]') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        const list2: ('beginning' | 'end')[] = [];
        for (const e of document.querySelectorAll('#antiCommentsList input[type=radio]:checked') as any) {
            const value = (e as HTMLInputElement).value;
            list2.push(value === 'beginning' ? 'beginning' : 'end');
        }
        const list3 = list.map(function(e, i) {
            const v: [string, 'beginning' | 'end'] = [e, list2[i]];
            return v;
        });
        setAntiComments(list3);
    }
    function onSideChanged(e: React.ChangeEvent<HTMLInputElement>, i: number) {
        const newSide = {...side, [i]: ((e.currentTarget as HTMLInputElement).value === 'end' ? 'end' : 'beginning') as 'beginning' | 'end'};
        setSide(newSide);
    }

    return (
        <>
            <h1>{props.reverse ? `Folders to post` : `Post to folders`}</h1>
            <p>TODO: Visual editor of folders. TODO: begin/end works only for owned folders.</p>
            <Container>
                <Row>
                    <Col>
                        <h3>Folders</h3>
                        <ul id="foldersList">
                            {(folders ?? []).map((folder, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control defaultValue={folder[0]} onChange={updateFoldersList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setFolders(folders!.filter((item) => item !== folder))}>Delete</Button>{" "}
                                        <label><input type="radio" name={`side-f${i}`} checked={side[i] === 'beginning' || side[i] === undefined}
                                            onChange={e => onSideChanged(e, i)} value="beginning"/>&#160;beginning</label>{" "}
                                        <label><input type="radio" name={`side-f${i}`} checked={side[i] === 'end'}
                                            onChange={e => onSideChanged(e, i)} value="end"/>&#160;end</label>
                                    </li>
                                );
                            })}
                        </ul>
                        <p>
                            <Button onClick={() => setFolders((folders ?? []).concat([["", 'beginning']]))}>
                                Add
                            </Button>
                        </p>
                    </Col>
                    {!props.noComments &&
                    <Col>
                        <h3>Comment to</h3>
                        <ul id="antiCommentsList">
                            {(antiComments ?? []).map((folder, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control defaultValue={folder[0]} onChange={updateAntiCommentsList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setAntiComments(antiComments!.filter((item) => item !== folder))}>Delete</Button>
                                    </li>
                                );
                            })}
                        </ul>
                        <p>
                            <Button onClick={() => setAntiComments((antiComments ?? []).concat([["", 'beginning']]))}>
                                Add
                            </Button>
                        </p>
                    </Col>}
                </Row>
            </Container>
        </>
    );
}