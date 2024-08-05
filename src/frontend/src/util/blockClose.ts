import { useEffect } from "react";

export const useBlockTabClose = () => {
    useEffect(() => {
        const handleBeforeUnload = (event) => {
            const message = 'You have unsaved changes. Are you sure you want to leave?';
            event.returnValue = message;
            return message;
        };
    
        window.addEventListener('beforeunload', handleBeforeUnload);
        return () => {
            window.removeEventListener('beforeunload', handleBeforeUnload);
        };
    }, []);
};