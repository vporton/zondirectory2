import { createContext, useState } from "react";

export interface MainContextType {
    userScore: number | undefined,
    setUserScore?: (score: number) => void,
}

const defaultMainContext: MainContextType = {
    userScore: undefined,
};

export const MainContext = createContext<MainContextType>(defaultMainContext);

export const MainProvider: React.FC<{children: React.ReactNode}> = ({ children }) => {
    const [userScore, setUserScore] = useState<number | undefined>(undefined);
    const value: MainContextType = {
        userScore,
        setUserScore,
    };
    return <MainContext.Provider value={value}>{children}</MainContext.Provider>;
}
