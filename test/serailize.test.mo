import M "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import lib "../src/backend/lib";

class testableItem(data: lib.ItemData): T.TestableItem<lib.ItemData> = {
    public let item = data;
    public func display(person: lib.ItemData) : Text =
       debug_show(person.item);
    public func equals(data1: lib.ItemData, data2: lib.ItemData) : Bool =
       data1 == data2;
};

let suite = Suite.suite("Serialize/deserialize", [
    Suite.suite("Item serialize/deserialize",
        Iter.toArray(
            Iter.map([#link "https://example.com", #message, #post, #folder].vals(), func (d: lib.ItemDetails): Suite.Suite {
                let item: lib.ItemData = {
                    creator = Principal.fromText("2vxsx-fae");
                    item = {
                        price = 0.25;
                        locale = "en_US";
                        title = "Title";
                        description = "Description";
                        details = d;
                    };
                };
                Suite.test("serailization of deserialization", item, M.equals(testableItem(lib.deserializeItem(lib.serializeItem(item)))));
            }),
        ),
    ),
]);
Suite.run(suite);