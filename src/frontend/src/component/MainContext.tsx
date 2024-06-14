import React, { ReactNode, createContext, useEffect, useState } from "react";
import { useAuth } from "./auth/use-auth-client";
import { ZonBackend } from "../../../declarations/main/main.did";
import { Actor } from "@dfinity/agent";
import { idlFactory as mainIdlFactory } from "../../../declarations/main";
import { Principal } from "@dfinity/principal";

export interface MainContextType {
    userScore: number | undefined,
    setUserScore?: (score: number) => void,
    fetchUserScore?: () => Promise<void>,
}

const defaultMainContext: MainContextType = {
    userScore: undefined,
};

export const MainProvider: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const {principal, defaultAgent} = useAuth();
    const [userScore, setUserScore] = useState<number | undefined>(undefined);
    async function fetchUserScore() {
        // TODO: If we have a hint, skip update call.
        const MainCanister: ZonBackend = Actor.createActor(mainIdlFactory, {canisterId: process.env.CANISTER_ID_MAIN!, agent: defaultAgent})
        const data0 = await MainCanister.getUserScore(principal!, []); // TODO: hint
        if (data0.length === 0) {
            setUserScore!(0);
        } else {
            const [data] = data0;
            let [part, id] = data! as [Principal, bigint];
            setUserScore!(Number(id));
        }
    }
    const value: MainContextType = {
        userScore,
        setUserScore,
        fetchUserScore,
    };
    useEffect(() => {
        if (principal !== undefined) {
            fetchUserScore().then(() => {});
        }
    }, [principal]);
    return <MainContext.Provider value={value}>{props.children}</MainContext.Provider>;
}

export const MainContext = createContext<MainContextType>(defaultMainContext);
