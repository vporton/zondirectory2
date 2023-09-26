// TODO
export default class AppData {
    itemId: number;
    item: Item;
    constructor(itemId) {
        this.itemId = itemId;
    }
    locale() {
        return 'en';
    }
    title() {
        return "The Homepage";
    }
    description() {
        return null;
    }
    // FIXME: For non-folders, no distinction between `subCategories` and `items` (or better no subcategories?)
    subCategories() {
        return [
            {id: 1, locale: "en", title: "Climate change", type: 'public'},
            {id: 4, locale: "en", title: "Victor Porton's writings", description: "My personal writings. I write about science, software, and religion.", type: 'private'},
            {id: 2, locale: "en", title: "Science", type: 'public'},
            {id: 3, locale: "en", title: "Life style", type: 'public'},
            {id: 5, locale: "en", title: "Sport", type: 'public'},
        ];
    }
    superCategories() {
        return [
            {id: 1, locale: "en", title: "All the World", type: 'public'},
            {id: 4, locale: "en", title: "John's notes", type: 'private', description: "John writes about everything, including the content of The Homepage."},
        ];
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
                id: 2,
                locale: "en",
                title: "A post with a link",
                description: "This is just an example post with a link.",
                link: "https://example.com",
            },
            {
                id: 3,
                locale: "en",
                title: "A paid item",
                description: "This is for purchase.",
                link: "https://example.com",
                price: "11.0",
            },
        ];
    }
}