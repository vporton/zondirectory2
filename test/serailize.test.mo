import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import lib "../src/backend/lib";

class testableItem(data: lib.Item): T.TestableItem<lib.Item> = {
    public let item = data;
    public func display(_item: lib.Item) : Text =
       "<ITEM>"; // TODO
    public func equals(data1: lib.Item, data2: lib.Item) : Bool =
       data1 == data2;
};

class testableItemVariant(data: lib.ItemVariant): T.TestableItem<lib.ItemVariant> = {
    public let item = data;
    public func display(person: lib.ItemVariant) : Text =
       debug_show(person.item);
    public func equals(data1: lib.ItemVariant, data2: lib.ItemVariant) : Bool =
       data1 == data2;
};

let suite = Suite.suite("Serialize/deserialize", [
    Suite.suite("Item serialize/deserialize item",
        Iter.toArray(
            Iter.map([#link "https://example.com", #message, #post, #folder].vals(), func (d: lib.ItemDetails): Suite.Suite {
                // TODO: Test also communal item.
                let item: lib.Item = #owned {
                    creator = Principal.fromText("2vxsx-fae");
                    item = {
                        price = 0.25;
                        locale = "en_US";
                        title = "Title";
                        description = "Description";
                        details = d;
                    } : lib.ItemDataWithoutOwner;
                };
                Suite.test(
                    "serialization of deserialization",
                    item,
                    M.equals(testableItem(lib.deserializeItem(lib.serializeItem(item)))));
            }),
        ),
    ),
    Suite.suite("Item serialize/deserialize item variant",
        Iter.toArray(
            Iter.map([#link "https://example.com", #message, #post, #folder].vals(), func (d: lib.ItemDetails): Suite.Suite {
                let item: lib.ItemVariant = {
                    item = {
                        price = 0.25;
                        locale = "en_US";
                        title = "Title";
                        description = "Description";
                        details = d;
                    };
                };
                Suite.test(
                    "serialization of deserialization",
                    item,
                    M.equals(testableItemVariant(lib.deserializeItemVariant(lib.serializeItemVariant(item)))));
            }),
        ),
    ),
]);
Suite.run(suite);