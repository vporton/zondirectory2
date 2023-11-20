import * as React from "react";
import { useEffect, useState } from "react";
import { Button, Col, Container, Form, Row } from "react-bootstrap"; // TODO: Import by one component.

export default function EditCategoriesList(props: {
    defaultCategories?: string[],
    defaultAntiComments?: string[],
    onChangeCategories?: (categories: string[]) => void,
    onChangeAntiComments?: (categories: string[]) => void,
    noComments?: boolean,
    reverse?: boolean,
}) {
    const [categories, setCategories] = useState<string[] | undefined>(undefined);
    const [antiComments, setAntiComments] = useState<string[] | undefined>(undefined);
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
        for (const e of document.querySelectorAll('#categoriesList input') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        setCategories(list);
    }
    function updateAntiCommentsList() {
        const list: string[] = [];
        // TODO: validation
        for (const e of document.querySelectorAll('#aantiCommentsList input') as any) {
            const value = (e as HTMLInputElement).value;
            if (value !== "") {
                list.push(value)
            }
        }
        setAntiComments(list);
    }

    return (
        <>
            <h2>{props.reverse ? `Categories to post` : `Post to categories`}</h2>
            <p>TODO: Visual editor of categories; TODO: Limited to ?? posts per day</p>
            <Container>
                <Row>
                    <Col>
                        <h3>Categories</h3>
                        <ul id="categoriesList">
                            {(categories ?? []).map((cat, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control value={cat} onChange={updateCategoriesList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setCategories(categories!.filter((item) => item !== cat))}>Delete</Button>
                                    </li>
                                );
                            })}
                        </ul>
                        <p><Button disabled={categories === undefined} onClick={() => setCategories(categories!.concat([""]))}>Add</Button></p>
                    </Col>
                    {!props.noComments &&
                    <Col>
                        <h3>Comment to</h3>
                        <ul id="antiCommentsList">
                            {(antiComments ?? []).map((cat, i) => {
                                return (
                                    <li key={i}>
                                        <Form.Control value={cat} onChange={updateAntiCommentsList} style={{display: 'inline', width: '15em'}}/>{" "}
                                        <Button onClick={() => setAntiComments(antiComments!.filter((item) => item !== cat))}>Delete</Button>
                                    </li>
                                );
                            })}
                        </ul>
                        <p><Button disabled={antiComments === undefined} onClick={() => setAntiComments(antiComments!.concat([""]))}>Add</Button></p>
                    </Col>}
                </Row>
            </Container>
        </>
    );
}