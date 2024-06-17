import React, { ReactNode, createContext, useContext, useState } from "react";

export interface BusyContextType {
    busy: boolean,
    setBusy?: (busy: boolean) => void,
}

const defaultBusyContext: BusyContextType = {
    busy: false,
};

export const BusyContext = createContext<BusyContextType>(defaultBusyContext);

export const BusyProvider: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const [busy, setBusy] = useState(false);
    const value: BusyContextType = {busy, setBusy};
    return <BusyContext.Provider value={value}>{props.children}</BusyContext.Provider>;
}

export const BusyWidget: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const {busy} = useContext(BusyContext);
    return busy ? <p>Processing...</p> : props.children;
}