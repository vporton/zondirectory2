import * as React from "react";
import { useEffect, useState } from "react";
import { Button, Col, Container, Form, Row } from "react-bootstrap"; // TODO: Import by one component.

export default function EditCategoriesList(props: {
    defaultCategories?: [string, {beginning: null} | {end: null}][],
    defaultAntiComments?: [string, {beginning: null} | {end: null}][],
    onChangeCategories?: (categories: [string, {beginning: null} | {end: null}][]) => void,
    onChangeAntiComments?: (categories: [string, {beginning: null} | {end: null}][]) => void,
    noComments?: boolean,
    reverse?: boolean,
}) {
    const [categories, setCategories] = useState<[string, {beginning: null} | {end:null}][] | undefined>(undefined);
    const [antiComments, setAntiComments] = useState<[string, {beginning: null} | {end: null}][] | undefined>(undefined);
    enum SideType { beginning, end };
    const [side, setSide] = useState<SideType>(SideType.beginning);
    useEffect(() => {
        if (categories === undefined && props.defaultCategories?.length !== 0) {
            setCategories(props.defaultCategories ?? []);
        }
    }, [props.defaultCategories])
    useEffect(() => {
        if (antiComments === undefined && props.defaultAntiComments?.length !== 0) {
            setAntiComments(props.defaultAntiComments ?? []);
        }
    }, [props.defaultAntiComments])
    function updateCategories() {
        if (props.onChangeCategories !== undefined && categories !== undefined) {
            props.onChangeCategories(categories);
        }
    }
    function updateAntiComments() {
        if (props.onChangeAntiComments !== undefined && antiComments !== undefined) {
            props.onChangeAntiComments(antiComments);
        }
    }
    useEffect(updateCategories, [categories]);
    useEffect(updateAntiComments, [antiComments]);
    function updateCategoriesList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#categoriesList input[type=text]') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        const list2: ({beginning: null} | {end: null})[] = [];
        for (const e of document.querySelectorAll('#categoriesList input[type=radio]:checked') as any) {
            const value = (e as HTMLInputElement).value;
            list2.push(value === 'beginning' ? {beginning: null} : {end: null});
        }
        const list3 = list.map(function(e, i) {
            const v: [string, {beginning: null} | {end:null}] = [e, list2[i]];
            return v;
        });
        setCategories(list3);
    }
    function updateAntiCommentsList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#antiCommentsList input[type=text]') as any) {
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
            <h2>{props.reverse ? `Categories to post` : `Post to categories`}</h2>
            <p>TODO: Visual editor of categories; TODO: Limited to ?? posts per day; TODO: begin/end works only for owned folders</p>
            <Container>
                <Row>
                    <Col>
                        <h3>Categories</h3>
                        <ul id="categoriesList">
                            {(categories ?? []).map((cat, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control value={cat[0]} onChange={updateCategoriesList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setCategories(categories!.filter((item) => item !== cat))}>Delete</Button>{" "}
                                        <label><input type="radio" name="side" checked={side === SideType.beginning}
                                            onChange={onSideChanged}/>&#160;beginning</label>{" "}
                                        <label><input type="radio" name="side" checked={side === SideType.end}
                                            onChange={onSideChanged}/>&#160;end</label>
                                    </li>
                                );
                            })}
                        </ul>
                        <p><Button disabled={categories === undefined} onClick={() => setCategories(categories!.concat(["", {beginning: null}]))}>Add</Button></p>
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
                        <p><Button disabled={antiComments === undefined} onClick={() => setAntiComments(antiComments!.concat(["", {beginning: null}]))}>Add</Button></p>
                    </Col>}
                </Row>
            </Container>
        </>
    );
}