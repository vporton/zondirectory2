import * as React from "react";
import 'bootstrap/dist/css/bootstrap.min.css';
import { Component, ErrorInfo, ReactNode, Suspense, createContext, useContext, useEffect, useMemo, useState } from "react";
import { Button, Col, Container, Nav, NavDropdown, Navbar, Offcanvas, Row } from 'react-bootstrap'; // TODO: selective imports
import ShowItem from "./ShowItem";
import {
    BrowserRouter as Router,
    Route,
    Routes,
    NavLink,
    useNavigate,
    HashRouter,
    useParams,
    Link,
    BrowserRouter,
    useLocation,
} from "react-router-dom";
import { Actor, Agent, getDefaultAgent } from '@dfinity/agent';
import SubFolders from "./SubFolders";
import EditItem from "./EditItem";
import EditFolder from "./EditFolder";
import { getIsLocal } from "../util/client";
import { serializeItemRef } from '../data/Data'
import { Principal } from "@dfinity/principal";
import { AuthContext, AuthProvider, useAuth } from './auth/use-auth-client'
import { idlFactory as mainIdlFactory } from "../../../declarations/main";
import { _SERVICE as ZonBackend } from "../../../declarations/main/main.did";
import { Helmet } from 'react-helmet';
import { AllItems } from "./AllItems";
import { ErrorBoundary, ErrorHandler } from "./ErrorBoundary";
import { ErrorProvider } from "./ErrorContext";
import Prefs from "./Prefs";
import { MainContext, MainContextType, MainProvider } from './MainContext';
import { BusyContext, BusyProvider, BusyWidget } from "./busy";
import ReactGA from 'react-ga4';
import { createBrowserHistory } from 'history';

export default function App() {
    var history = createBrowserHistory();
    useEffect(() => {
        if (!getIsLocal()) {
            ReactGA.initialize("G-PDPFZKZ3R6");
            // ReactGA.send({ hitType: "pageview", page: location.pathname + location.search/*, title: "Landing Page"*/ });
        }
    }, [])
    history.listen(update => { // FIXME: It seems doesn't work.
        console.log("Page view", update.location.pathname + update.location.search);
        // TODO: (Not an easy task) watch also for page title.
        ReactGA.send({ hitType: "pageview", page: update.location.pathname + update.location.search/*, title: "Landing Page"*/ });
    });

    const identityCanister = process.env.CANISTER_ID_INTERNET_IDENTITY;
    const frontendCanister = process.env.CANISTER_ID_FRONTEND;
    const identityProvider = getIsLocal() ? `http://${identityCanister}.localhost:8000` : `https://identity.ic0.app`;
    const [busy, setBusy] = useState(false);
    return (
        <>
            <Helmet>
                <title>Zon Social Media - the world as items in folders</title>
                <meta name="description" content="A fusion of social network, marketplace, and web directory"/>
            </Helmet>
            <Container>
                <header>
                    <div data-nosnippet="true">
                        <Nav style={{marginBottom: '1ex', textAlign: 'center'}}>
                            <Container>
                                <div className="ad">
                                    <a href="https://services.zoncircle.com/what-is-explainer-video/">Explainer Videos</a>
                                </div>
                                <div className="ad">
                                    Freelancers: <a rel="sponsored" href="https://go.fiverr.com/visit/?bta=983331&nci=17044">PRO</a> or{" "}
                                    <a rel="sponsored" href="https://go.fiverr.com/visit/?bta=983331&brand=fiverrmarketplace">utterly cheap</a>
                                </div>
                                <div className="ad">
                                    <a rel="sponsored" href="https://brex.com/signup?rc=Twimner">Corporate Banking</a>
                                </div>
                                <div className="ad">
                                    <a rel="sponsored" href="https://services.zoncircle.com/job-matching-services/">Job Services</a> (for programmers and employers)
                                </div>
                                <div className="ad">
                                    <a rel="sponsored" href="https://get.firstbase.io/wpspq4cqutoe">US companies, legal addresses, automated taxes, etc.</a>
                                </div>
                                <div className="ad">
                                    <a rel="sponsored" href="https://nas.io/?referral=VICTOR_13">Online Communities</a> (with monetization)
                                </div>
                                <div className="ad">
                                    <a rel="sponsored" href="https://www.minds.com/?referrer=zonsocial">Another Social Network</a>
                                </div>
                            </Container>
                        </Nav>
                        <p style={{width: '100%', background: 'red', color: 'white', padding: '4px'}}>
                            It is a preliminary beta version. Some features are missing, notably
                            images/media, communal items (collective editing) and monetization.
                            Neither security of your data, nor any quality of service is warranted.
                        </p>
                    </div>
                </header>
                <div style={{fontSize: '200%'}}>Zon Social Network</div>
                <AuthProvider options={{loginOptions: {
                    identityProvider,
                    maxTimeToLive: BigInt(3600) * BigInt(1_000_000_000),
                    windowOpenerFeatures: "toolbar=0,location=0,menubar=0,width=500,height=586,left=100,top=100",
                    onSuccess: () => {
                        console.log('Login Successful!');
                    },
                    onError: (error) => {
                        console.error('Login Failed: ', error);
                    },
                    derivationOrigin: getIsLocal() ? undefined : "https://zoncircle.com",
                }}}>
                    <BusyProvider>
                        <BusyWidget>
                            <BrowserRouter>
                                <ErrorProvider>
                                    <ErrorBoundary>
                                        <MainProvider>
                                            <AuthContext.Consumer>
                                                {({defaultAgent}) => <MyRouted defaultAgent={defaultAgent}/>}
                                            </AuthContext.Consumer>
                                        </MainProvider>
                                    </ErrorBoundary>
                                </ErrorProvider>
                            </BrowserRouter>
                        </BusyWidget>   
                    </BusyProvider>
                </AuthProvider>
            </Container>
        </>
    );
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit1(props: {defaultAgent: Agent | undefined}) {
    const routeParams = useParams();
    return <EditFolder superFolderId={routeParams.folder} defaultAgent={props.defaultAgent}/>;
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit2(props: {defaultAgent: Agent | undefined}) {
    const routeParams = useParams();
    return <EditFolder folderId={routeParams.folder} defaultAgent={props.defaultAgent}/>;
}

/// Defined outside of other functions not to re-initialize when the tree is updated.
function Edit3(props: {defaultAgent: Agent | undefined}) {
    const routeParams = useParams();
    return <EditItem itemId={routeParams.item} defaultAgent={props.defaultAgent}/>;
}

function MyRouted(props: {defaultAgent: Agent | undefined}) {
    const contextValue = useAuth();
    return (
        <AuthContext.Consumer>
            {({isAuthenticated, principal, authClient, defaultAgent, options, login, logout}) =>
                <MyInner
                    isAuthenticated={isAuthenticated}
                    login={login}
                    logout={logout}
                    principal={principal}
                    defaultAgent={defaultAgent}
                />
            }
        </AuthContext.Consumer>
    );
}

function MyInner(props: {
    isAuthenticated: boolean,
    login?: (callback?: () => Promise<void>) => void,
    logout?: () => Promise<void>,
    principal?: Principal,
    defaultAgent?: Agent,
}) {
    const navigate = useNavigate();
    const signin = () => {
        props.login && props.login();
    };
    const signout = async () => {
        props.logout && await props.logout();
    };
    const {userScore, setUserScore} = useContext<MainContextType>(MainContext);
    const [root, setRoot] = useState("");
    async function fetchRootItem() {
        const MainCanister: ZonBackend = Actor.createActor(mainIdlFactory, {canisterId: process.env.CANISTER_ID_MAIN!, agent: props.defaultAgent})
        const data0 = await MainCanister.getRootItem();
        const [data] = data0; // TODO: We assume that it's initialized.
        if (data != undefined) {
            let [part, id] = data! as [Principal, bigint];
            let item = { canister: part, id: Number(id) };
            setRoot(serializeItemRef(item));
        }
    }
    useEffect(() => {
        fetchRootItem().then(() => {});
    }, []);
    function RootRedirector(props: {root: string}) {
        useEffect(() => {
            if (root !== "") {
                navigate("/item/"+root);
            }
        }, [root]);
        return (
            <p>Loading...</p>
        );
    }

    const Person = React.lazy(() => import('./personhood/Person'));

    return <>
        <nav>
            <p>
                Logged in as: {props.isAuthenticated ? <small>{props.principal?.toString()}</small> : "(none)"}{" "}
                {props.isAuthenticated
                    ? <><Button onClick={signout}>Logout</Button> Your score: {userScore}</>
                    : <Button onClick={signin}>Login/Register</Button>}
            </p>
            <Navbar bg="body-secondary" expand="lg" collapseOnSelect>
      <Container>
        <Navbar.Toggle aria-controls="offcanvasNavbar" />
        <Navbar.Offcanvas
          id="offcanvasNavbar"
          aria-labelledby="offcanvasNavbarLabel"
          placement="end"
        >
          <Offcanvas.Header closeButton>
            <Offcanvas.Title id="offcanvasNavbarLabel">Menu</Offcanvas.Title>
          </Offcanvas.Header>
          <Offcanvas.Body>
            <Nav className="flex-grow-1">
              <Nav.Item>
                <Link className="nav-link" to={`/item/${root}`} title="Start browsing here">
                  Main folder
                </Link>
              </Nav.Item>
              <Nav.Item>
                <Link className="nav-link" to="/latest" title="Everything at this site, recent first">
                  Latest posts
                </Link>
              </Nav.Item>
              <NavDropdown title="User" id="user-nav-dropdown">
                <Link className="dropdown-item" to="/personhood">
                  Verify Your Account
                </Link>
                <Link className="dropdown-item" to="/prefs">
                  Settings
                </Link>
              </NavDropdown>
              <Nav.Item>
                <Link className="nav-link" to="https://docs.zoncircle.com" title="Help and company info">
                  Our site
                </Link>
              </Nav.Item>
              <Nav.Item>
                <Link className="nav-link" to="https://docs.zoncircle.com/invest/" title="Invest into this site">
                  Invest
                </Link>
              </Nav.Item>
              <NavDropdown title="About" id="about-nav-dropdown">
                <NavDropdown.Item href="https://docs.zoncircle.com/blog-archive/" title="Blog related to this site">
                  Blog
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/about-us/" title="About our company">
                  About Us
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/our-partners/" title="Who help to earn money">
                  Our Partners
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/#team" title="Developers and other personnel">
                  The Team
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/carbon-pledge/" title="We will save the world from carbon">
                  Carbon Pledge
                </NavDropdown.Item>
              </NavDropdown>
              <NavDropdown title="Blog" id="blog-nav-dropdown">
                <NavDropdown.Item href="https://docs.zoncircle.com/blog-archive/">
                  All posts
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/author/user/">
                  CEO's posts
                </NavDropdown.Item>
                <NavDropdown.Item href="https://docs.zoncircle.com/social-media/">
                  Social Media
                </NavDropdown.Item>
              </NavDropdown>
            </Nav>
          </Offcanvas.Body>
        </Navbar.Offcanvas>
      </Container>
    </Navbar>
        </nav>
        <Routes>
            <Route
                path=""
                element={<RootRedirector root={root}/>}
            />
            <Route
                path="/latest"
                element={<AllItems defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/item/:id"
                element={<ShowItem/>}
            />
            <Route
                path="/subfolders-of/:id"
                element={<SubFolders data-dir="sub" defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/superfolders-of/:id"
                element={<SubFolders data-dir="super" defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create"
                element={<EditItem defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create/for-folder/:folder"
                element={<EditItem defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create/comment/:folder"
                element={<EditItem comment={true} defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create-subfolder/for-folder/:folder"
                element={<Edit1 defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/create-superfolder/for-folder/:folder"
                element={<EditFolder super={true} defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/edit/folder/:folder"
                element={<Edit2 defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/edit/item/:item"
                element={<Edit3 defaultAgent={props.defaultAgent}/>}
            />
            <Route
                path="/personhood"
                element={<Suspense fallback={<div>Loading...</div>}><Person/></Suspense>}
            />
            <Route
                path="/prefs"
                element={<Prefs/>}
            />
            <Route path="*" element={<ErrorHandler error={"No such page"}/>}/>
        </Routes>
    </>
}