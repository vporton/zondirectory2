import React, { ReactNode, createContext, useState } from "react";

export interface MainContextType {
    userScore: number | undefined,
    setUserScore?: (score: number) => void,
}

const defaultMainContext: MainContextType = {
    userScore: undefined,
};

export const MainProvider: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const [userScore, setUserScore] = useState<number | undefined>(undefined);
    const value: MainContextType = {
        userScore,
        setUserScore,
    };
    return <MainContext.Provider value={value}>{props.children}</MainContext.Provider>;
}

export const MainContext = createContext<MainContextType>(defaultMainContext);
