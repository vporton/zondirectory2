export default class MockData {
    constructor(folderId) {}
    locale() {
        return 'en';
    }
    folderName() {
        return "Writings of Victor Porton";
    }
    folderDescription() {
        return "Folder owned by Victor Porton, where he publishes his writings";
    }
    subCategories() {
        return [
            {id: 1, locale: "en", title: "Climate change"},
            {id: 2, locale: "en", title: "Science"},
            {id: 3, locale: "en", title: "Life style"},
            {id: 4, locale: "en", title: "Victor Porton's writing", description: "My personal writings. I write about science, software, and religion."},
            {id: 5, locale: "en", title: "Sport"},
        ];
    }
    superCategories() {
        return this.subCategories();
    }
    items() {
        return [
            {
                id: 1,
                locale: "en",
                title: "A post",
                description: "This is just an example post.",
            },
            {
                id: 1,
                locale: "en",
                title: "A with a link",
                description: "This is just an example post with a link.",
                link: "https://example.com",
            },
            {
                id: 1,
                locale: "en",
                title: "A paid item",
                description: "This is for purchase.",
                link: "https://example.com",
                price: "11.0",
            },
        ];
    }
}