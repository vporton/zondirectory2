import { ItemData } from "./data/Data";

// export const AppData = process.env.REACT_APP_USE_MOCK_DATA === "1" ? MockData : ItemData;
export const AppData = ItemData; // TODO: Remove this indirection.