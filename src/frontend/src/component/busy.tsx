import React, { ReactNode, createContext, useContext, useEffect, useState } from "react";

export interface BusyContextType {
    busy: boolean,
    setBusy: (busy: boolean) => void,
}

const defaultBusyContext: BusyContextType = {
    busy: false,
    setBusy: (busy: boolean) => {},
};

export const BusyContext = createContext<BusyContextType>(defaultBusyContext);

export const BusyProvider: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const [busy, setBusy] = useState(false);
    const value: BusyContextType = {busy, setBusy};
    return <BusyContext.Provider value={value}>{props.children}</BusyContext.Provider>;
}

export const BusyWidget: React.FC<{children: React.ReactNode}> = (props: { children: ReactNode }) => {
    const {busy} = useContext(BusyContext);
    useEffect(() => {
        document.addEventListener('DOMContentLoaded', function () {
            const overlay = document.getElementById('overlay')!;
        
            // Запретить фокус на элементах внутри overlay
            overlay.addEventListener('focus', (event) => {
                event.stopPropagation();
                overlay.focus();
            }, true);
        
            // Обработчик для перехвата всех событий клавиатуры
            overlay.addEventListener('keydown', (event) => {
                event.stopPropagation();
                event.preventDefault();
            });
        
            // Перехват всех событий клика
            overlay.addEventListener('click', (event) => {
                event.stopPropagation();
                event.preventDefault();
            });
        
            // Принудительно устанавливаем фокус на overlay
            overlay.tabIndex = 0;
            overlay.focus();
        });
    }, [])
    return <>
        <div id="overlay" style={{display: (busy ? 'flex' : 'none')}}>
            <div id="overlayInside">Wait...</div>
        </div>
        <div id="content">
            {props.children}
        </div>
    </>;

    return busy ? <p>Processing...</p> : props.children;
}