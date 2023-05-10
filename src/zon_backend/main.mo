import IndexCanister "../storage/IndexCanister";
import PST "../zon_pst";
import DBPartition "../storage/DBPartition";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Entity "mo:candb/Entity";
import RBT "mo:stable-rbtree/StableRBTree";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import xNat "mo:xtendedNumbers/NatX";

// TODO: Also make the founder's account an owner?
actor ZonBackend {
  type EntryKind = { #NONE; #DOWNLOADS; #LINK; #CATEGORY; }; // TODO: letter case
  type LinkKind = { #Link; #Message };

  stable var index: ?IndexCanister.IndexCanister = null;
  stable var pst: ?PST.PST = null;
  stable var itemsDB: ?DBPartition.DBPartition = null;

  public shared({ caller }) func init() {
    founder := ?caller;
    if (pst == null) {
      // FIXME: `null` subaccount?
      pst := ?(await PST.PST({ owner = Principal.fromActor(ZonBackend); subaccount = null }));
    };
    if (index == null) {
      index := ?(await IndexCanister.IndexCanister([Principal.fromActor(ZonBackend)]));
    };
    if (itemsDB == null) {
      switch (index) {
        case (?index) {
          itemsDB := await index.createDBPartition("items");
        };
        case (null) {}
      }
    }
  };

  stable var salesOwnersShare = 0.1;
  stable var upvotesOwnersShare = 0.5;
  stable var uploadOwnersShare = 0.15;
  stable var buyerAffiliateShare = 0.1;
  stable var sellerAffiliateShare = 0.15;

  public query func getSalesOwnersShare(): async Float { salesOwnersShare };
  public query func getUpvotesOwnersShare(): async Float { upvotesOwnersShare };
  public query func getUploadOwnersShare(): async Float { uploadOwnersShare };
  public query func getBuyerAffiliateShare(): async Float { buyerAffiliateShare };
  public query func getSellerAffiliateShare(): async Float { sellerAffiliateShare };

  stable var maxId: Nat64 = 0;

  // TODO: Here an below: subaccount?
  stable var founder: ?Principal = null;

  type Item = {
    owner: Principal;
    price: Nat;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #post : ();
    };
  };

  func onlyMainOwner(caller: Principal): Bool {
    if (?caller == founder) {
      true;
    } else {
      Debug.trap("not the main owner");
    }
  };

  public shared({caller = caller}) func setMainOwner(_founder: Principal) {
    if (onlyMainOwner(caller)) {
      founder := ?_founder;
    }
  };

  public shared({caller = caller}) func removeMainOwner() {
    if (onlyMainOwner(caller)) {
      founder := null;
    }
  };

  public shared({caller = caller}) func setSalesOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      salesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUpvotesOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      upvotesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUploadOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      uploadOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setBuyerAffiliateShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      buyerAffiliateShare := _share;
    };
  };

  public shared({caller = caller}) func setSellerAffiliateShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      sellerAffiliateShare := _share;
    };
  };

  func getItemsDB(): DBPartition.DBPartition {
    actor("itemsDB");
  };

  func onlyItemOwner(caller: Principal, _item: Item): Bool {
    if (caller == _item.owner) {
      true;
    } else {
      Debug.trap("not the item owner");
    };
  };

  // TODO: Serialization format.
  func serializeItemAttr(item: Item): Entity.AttributeValue {
    #tuple (switch (item.details) {
      case (#link v) { ([
        #text (Principal.toText(item.owner)),
        #int (item.price),
        #text (item.title),
        #text (item.description),
        #text v,
      ]) };
      case (#post v) { ([
        #text (Principal.toText(item.owner)),
        #int (item.price),
        #text (item.title),
        #text (item.description),
      ]) };
    });
  };

  func serializeItem(item: Item): Entity.AttributeMap {
    var t = RBT.init<Text, Entity.AttributeValue>();
    t := RBT.put(t, Text.compare, "v", serializeItemAttr(item));
    t;
  };

  func deserializeItemAttr(attr: Entity.AttributeValue): Item {
    let value = label r: ?Item ?(switch (attr) {
      case (#tuple arr) {
        if (arr.size() == 4 or arr.size() == 5) {
          {
            owner = switch (arr[0]) {
              case (#text (owner)) { Principal.fromText(owner) };
              case _ { break r null; };
            };
            price = switch (arr[1]) {
              case (#int (price)) { 0/*price*/ }; // FIXME: Convert using https://github.com/edjCase/motoko_numbers ?
              case _ { break r null; };
            };
            title = switch (arr[2]) {
              case (#text (title)) { title };
              case _ { break r null; };
            };
            description = switch (arr[3]) {
              case (#text (description)) { description };
              case _ { break r null; };
            };
            details = if (arr.size() == 4) {
              #post
            } else { // arr.size() == 5
              switch (arr[4]) {
                case (#text (link)) { #link (link) };
                case _ {
                  break r null;
                };
              };
            };
          }
        } else {
          break r null;
        };
      };
      case _ { break r null; }
    });
    switch (value) {
      case (?value) { value };
      case _ { Debug.trap("wrong item format"); }
    };
  };

  func deserializeItem(map: Entity.AttributeMap): Item {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeItemAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  public shared({caller = caller}) func setItemData(_itemId: Nat64, _item: Item) {
    var db = getItemsDB();
    let key = Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr);
        if (onlyItemOwner(caller, oldItem)) {
          db.put({sk = key; attributes = serializeItem(_item)});
        };
      };
      case _ { Debug.trap("no item") };
    }
  }


};
