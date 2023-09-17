import NacDbPartition "../storage/NacDBPartition";
import RBT "mo:stable-rbtree/StableRBTree";
import Entity "mo:candb/Entity";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Int "mo:base/Int";

module {
  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_OWNED_CATEGORY = 3;
  let ITEM_TYPE_COMMUNAL_CATEGORY = 4;

  public type ItemWithoutOwner = {
    price: Float;
    locale: Text;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #message : ();
      #post : Text;
      #category: {
        // Locators for `order.mo`:
        // TODO: Are these locators `?opt`
        timeOrderSubDB: ?(
          NacDbPartition.Partition,
          Nat, // TODO: correct type?
        );
        votesOrderSubDB: ?(
          NacDbPartition.Partition,
          Nat, // TODO: correct type?
        );
        catKind: {
          #owned;
          #communal;
        };
      };
    };
  };

  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Item version.
  public type Item = {
    creator: Principal;
    item: ItemWithoutOwner;
  };

  // TODO: messy order of the below functions

  public func deserializeItem(map: Entity.AttributeMap): Item {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeItemAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  func serializeItemAttr(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int (switch (item.item.details) {
      case (#link v) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post _) { ITEM_TYPE_POST };
      case (#category cat) {
        switch (cat.catKind) {
          case (#owned) { ITEM_TYPE_OWNED_CATEGORY };
          case (#communal) { ITEM_TYPE_COMMUNAL_CATEGORY };
        };
      };
    }));
    buf.add(#text (Principal.toText(item.creator)));
    buf.add(#float (item.item.price));
    buf.add(#text (item.item.locale));
    buf.add(#text (item.item.title));
    buf.add(#text (item.item.description));
    switch (item.item.details) {
      case (#link v) {
        buf.add(#text v);
      };
      case (#post v) {
        buf.add(#text v);
      };
      case _ {};
    };
    #tuple (Buffer.toArray(buf));
  };

  public func serializeItem(item: Item): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeItemAttr(item))];
  };

  func deserializeItemAttr(attr: Entity.AttributeValue): Item {
    var kind: Nat = 0;
    var creator: ?Principal = null;
    var price = 0.0;
    var locale = "";
    var nick = "";
    var title = "";
    var description = "";
    var details: {#none; #link; #message; #post; #ownedCategory; #communalCategory} = #none;
    var link = "";
    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        var num = 0;
        while (pos < arr.size()) {
          switch (num) {
            case (0) {
              switch (arr[pos]) {
                case (#int v) {
                  kind := Int.abs(v);
                };
                case _ { break r false };
              };
              pos += 1;
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  creator := ?Principal.fromText(v);
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (2) {
              switch (arr[pos]) {
                case (#float v) {
                  price := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  locale := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (5) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (6) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false; }
              };
              pos += 1;
            };
            case (7) {
              switch (arr[pos]) {
                case (#text v) {
                  link := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case _ { break r false; };
          };
          num += 1;
        };
        true;
      };
      case _ {
        false;
      };
    };
    if (not res) {
      Debug.trap("wrong item format");
    };
    let ?creator2 = creator else { Debug.trap("programming error"); };
    {
      creator = creator2;
      item = {
        price = price;
        locale = locale;
        nick = nick;
        title = title;
        description = description;
        details = switch (kind) {
          case (0) { #link link };
          case (1) { #message };
          case (2) { #post "" }; // FIXME: post text
          case (3) { #category {
              // Locators for `order.mo`:
              timeOrderSubDB = null;
              votesOrderSubDB = null;
              catKind = #owned;
            }
          };
          case (4) { #category {
              // Locators for `order.mo`:
              timeOrderSubDB = null;
              votesOrderSubDB = null;
              catKind = #communal;
            }
          };
          case _ { Debug.trap("wrong item format"); }
        };
      };
    };    
  };

  public func onlyItemOwner(caller: Principal, _item: Item) {
    if (caller != _item.creator) {
      Debug.trap("not the item owner");
    };
  };
}