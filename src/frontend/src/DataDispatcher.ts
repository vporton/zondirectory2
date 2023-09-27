import { ItemData } from "./data/Data";
import MockData from "./data/MockData";

export const AppData = process.env.REACT_APP_USE_MOCK_DATA === "1" ? MockData : ItemData;