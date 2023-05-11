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
import Buffer "mo:base/Buffer";

// TODO: Also make the founder's account an owner?
actor ZonBackend {
  // type EntryKind = { #NONE; #DOWNLOADS; #LINK; #CATEGORY; }; // TODO: letter case
  // type LinkKind = { #Link; #Message };

  stable var index: ?IndexCanister.IndexCanister = null;
  stable var pst: ?PST.PST = null;
  stable var itemsDB: ?DBPartition.DBPartition = null;
  stable var authorsDB: ?DBPartition.DBPartition = null;

  public shared({ caller }) func init() {
    founder := ?caller;
    if (pst == null) {
      // FIXME: `null` subaccount?
      pst := ?(await PST.PST({ owner = Principal.fromActor(ZonBackend); subaccount = null }));
    };
    if (index == null) {
      index := ?(await IndexCanister.IndexCanister([Principal.fromActor(ZonBackend)]));
    };
    if (authorsDB == null) {
      switch (index) {
        case (?index) {
          authorsDB := await index.createDBPartition("authors");
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

  // TODO: Here and below: subaccount?
  stable var founder: ?Principal = null;

  type Item = {
    owner: ?Principal;
    price: Nat;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #post : ();
      #category : ();
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
    if (?caller == _item.owner) {
      true;
    } else {
      Debug.trap("not the item owner");
    };
  };

  let SER_LINK = 0;
  let SER_POST = 1;
  let SER_CATEGORY = 2;

  func serializeItemAttr(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int (switch (item.details) {
      case (#link v) { SER_LINK };
      case (#post) { SER_POST };
      case (#category) { SER_CATEGORY };
    }));
    switch (item.owner) {
      case (?owner) {
        buf.add(#bool (true));
        buf.add(#text (Principal.toText(owner)));
      };
      case (null) {
        buf.add(#bool (false));
      };
    };
    buf.add(#int (item.price));
    buf.add(#text (item.title));
    buf.add(#text (item.description));
    switch (item.details) {
      case (#link v) {
        buf.add(#text v);
      };
      case _ {};
    };
    #tuple (buf.toArray());
  };

  func serializeItem(item: Item): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeItemAttr(item))];
  };

  // FIXME:
  func deserializeItemAttr(attr: Entity.AttributeValue): Item {
    var kind: Int = 0;
    var owner: ?Principal = null;
    var price = 0;
    var title = "";
    var description = "";
    var details: {#none; #category; #link; #post} = #none;
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
                  kind := v;
                };
                case _ { break r false };
              };
              pos += 1;
            };
            case (1) {
              switch (arr[pos]) {
                case (#bool true) {
                  switch (arr[pos+1]) {
                    case (#text v) {
                      owner := ?Principal.fromText(v);
                    };
                    case _ { break r false; };
                  };
                  pos += 2;
                };
                case (#bool false) {
                  owner := null;
                  pos += 1;
                };
                case _ { break r false; }
              };
            };
            case (2) {
              switch (arr[pos]) {
                case (#int v) {
                  price := 0; // FIXME: Use `v` instead.
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false; }
              };
              pos += 1;
            };
            case (5) {
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
    {
      owner = owner;
      price = price;
      title = title;
      description = description;
      details = switch (kind) {
        case (0) { #link link };
        case (1) { #post };
        case (2) { #category };
        case _ { Debug.trap("wrong item format"); }
      };
    };    
  };

  func deserializeItem(map: Entity.AttributeMap): Item {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeItemAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  // FIXME: This allows items with foreign user attribution.
  // We don't check owner: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller = caller}) func createItemData(canisterId: Principal, _item: Item) {
    let _itemId = maxId;
    maxId += 1;
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    db.put({sk = key; attributes = serializeItem(_item)});
  };

  // We don't check owner: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller = caller}) func setItemData(canisterId: Principal, _itemId: Nat64, _item: Item) {
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr.attributes);
        if (onlyItemOwner(caller, oldItem)) {
          db.put({sk = key; attributes = serializeItem(_item)});
        };
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: `removeItemOwner`

};
