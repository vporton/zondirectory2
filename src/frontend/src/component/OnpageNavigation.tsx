import React from "react";
import { Helmet } from "react-helmet";

export type Page = Map<string, number>;

// function getCanonicalUrl() {
//     const links = document.head.querySelectorAll('link[rel="canonical"]');
//     if (links.length > 0) {
//         return (links[0] as HTMLLinkElement).href;
//     } else {
//         // Если canonical URL не найден, возвращаем null или пустую строку, в зависимости от требований
//         return null; // или return '';
//     }
// }

export function OnpageNavigation(props: {
    startPage: Page,
    page: Page,
}) {
    let differences = 0;
    for (const k of props.startPage.keys()) {
        if (props.page.get(k) !== undefined && props.page.get(k) !== props.startPage.get(k)) {
            ++differences;
        }
    }

    const href = window.location.href;
    if (href === null) { // We start with a wrong URL.
        return (
            <Helmet>
                <meta name="robots" content="noindex,nofollow"/>
            </Helmet>
        );
    }
    const url = new URL(href);

    // TODO: Hack to prevent `Failed to execute 'replaceState' on 'History'`:
    // deep copy:   
    url.host = (new String(window.location.host)) as string;
    url.protocol = (new String(window.location.protocol)) as string;

    const params = url.searchParams;
    while (params.size !== 0) {
        params.delete(params.keys().next().value); // to normalize canonical URL // FIXME: normalizes wrong
    }
    for (const k of props.page.keys()) {
        if (props.page.get(k) !== undefined && props.page.get(k) !== props.startPage.get(k)) {
            params.set(k, props.page.get(k)!.toString());
        }
    }
    if (differences !== 0) { // It replaces the state too early when going to folder list, so this check.
        history.replaceState({}, "", url);
    }

    return (
        <Helmet>
            <link rel="canonical" href={url.toString()}/>
            {
                /* Save crawl budget by ignoring navigation by more than one list: */
                differences > 1 ? <meta name="robots" content="noindex,nofollow"/> :
                differences === 1 ? <meta name="robots" content="noindex"/> : ""
            }
        </Helmet>
    );
}