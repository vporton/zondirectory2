export default class MockData {
    constructor(folderId) {}
    folderName() {
        return "Writings of Victor Porton";
    }
    folderDescription() {
        return "Folder owned by Victor Porton, where he publishes his writings";
    }
    subCategories() {
        return [
            {id: 1, name: "Climate change"},
            {id: 2, name: "Science"},
            {id: 3, name: "Life style"},
            {id: 4, name: "Victor Porton's writing", description: "My personal writings. I write about science, software, and religion."},
            {id: 5, name: "Sport"},
        ];
    }
}