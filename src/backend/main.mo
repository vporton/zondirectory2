import ICRC1Types "mo:icrc1/ICRC1/Types";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import MyCycles "mo:nacdb/Cycles";
import Common "../storage/common";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Entity "mo:candb/Entity";
import BTree "mo:stableheapbtreemap/BTree";
import RBT "mo:stable-rbtree/StableRBTree";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import xNat "mo:xtendedNumbers/NatX";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import StableBuffer "mo:StableBuffer/StableBuffer";
import Payments "payments";
import NacDbPartition "../storage/NacDBPartition";
import lib "lib";
import config "../../config";

shared actor class ZonBackend() = this {
  /// External Canisters ///

  /// Some Global Variables ///

  // See ARCHITECTURE.md for database structure

  // TODO: Avoid duplicate user nick names.

  stable var maxId: Nat = 0;

  stable var founder: ?Principal = null;

  /// Initialization ///

  stable var initialized: Bool = false;

  public shared({ caller }) func init(): async () {
    ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    if (initialized) {
      Debug.trap("already initialized");
    };

    founder := ?caller;

    initialized := true;
  };

  /// Owners ///

  func onlyMainOwner(caller: Principal) {
    if (?caller != founder) {
      Debug.trap("not the main owner");
    }
  };

  public shared({caller}) func setMainOwner(_founder: Principal) {
    onlyMainOwner(caller);

    founder := ?_founder;
  };

  public shared({caller}) func removeMainOwner() {
    onlyMainOwner(caller);
    
    founder := null;
  };

  /// Users ///

  // anti-Sybil verification
  public shared({caller}) func verifyUser(): async () {
    await* lib.checkSybil(caller);
  };

  type User = {
    locale: Text;
    nick: Text;
    title: Text;
    description: Text;
    link : Text;
  };

  func serializeUser(user: User): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int 0); // version
    buf.add(#text (user.locale));
    buf.add(#text (user.nick));
    buf.add(#text (user.title));
    buf.add(#text (user.description));
    buf.add(#text (user.link));
    #tuple (Buffer.toArray(buf));
  };

  func deserializeUser(attr: Entity.AttributeValue): User {
    var locale = "";
    var nick = "";
    var title = "";
    var description = "";
    var link = "";
    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        while (pos < arr.size()) {
          switch (pos) {
            case (0) {
              switch (arr[pos]) {
                case (#int v) {
                  assert v == 0; // version
                };
                case _ { break r false };
              };
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  locale := v;
                };
                case _ { break r false };
              };
            };
            case (2) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false };
              };
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false };
              };
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false };
              };
            };
            case (5) {
              switch (arr[pos]) {
                case (#text v) {
                  link := v;
                };
                case _ { break r false };
              };
            };
            case _ { break r false; };
          };
          pos += 1;
        };
        true;
      };
      case _ {
        false;
      };
    };
    if (not res) {
      Debug.trap("wrong user format");
    };
    {
      locale = locale;
      nick = nick;
      title = title;
      description = description;
      link = link;
    };    
  };

  public shared({caller}) func setUserData(partitionId: ?Principal, _user: User) {
    await* lib.checkSybil(caller);
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    // TODO: Add Hint to CanDBMulti
    ignore await CanDBIndex.putAttributeNoDuplicates("user", {
        sk = key;
        key = "u";
        value = serializeUser(_user);
      },
    );
  };

  // TODO: Should also remove all his/her items?
  public shared({caller}) func removeUser(canisterId: Principal) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };

  /// Items ///

  stable var rootItem: ?(CanDBPartition.CanDBPartition, Nat) = null;

  public shared({caller}) func setRootItem(part: Principal, id: Nat)
    : async ()
  {
    onlyMainOwner(caller);

    rootItem := ?(actor(Principal.toText(part)), id);
  };

  public query func getRootItem(): async ?(Principal, Nat) {
    do ? {
      let (part, n) = rootItem!;
      (Principal.fromActor(part), n);
    };
  };

  public shared({caller}) func createItemData(item: lib.ItemWithoutCreator)
    : async (Principal, Nat)
  {
    await* lib.checkSybil(caller);

    let item2: lib.Item = { creator = caller; item; };
    let itemId = maxId;
    maxId += 1;
    let key = "i/" # Nat.toText(itemId);
    let canisterId = await CanDBIndex.putAttributeWithPossibleDuplicate(
      "main", { sk = key; key = "i"; value = lib.serializeItem(item2) }
    );
    (canisterId, itemId);
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, _itemId: Nat, item: lib.ItemWithoutCreator) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        let _item: lib.Item = { item = item; creator = caller; var streams = null; };
        if (_item.item.kind != oldItem.item.kind) {
          Debug.trap("can't change item type");
        };
        switch (oldItem.item.ownership) {
          case (#communal) {
            Debug.trap("can't edit communal category");
          };
          case _ {};
        };
        lib.onlyItemOwner(caller, oldItem);
        await db.putAttribute({sk = key; key = "i"; value = lib.serializeItem(_item)});
      };
      case _ { Debug.trap("no item") };
    };
  };

  public shared({caller}) func setPostText(canisterId: Principal, _itemId: Nat, text: Text) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        lib.onlyItemOwner(caller, oldItem);
        switch(oldItem.item.kind) {
          case (#post) {};
          case _ { Debug.trap("not a post"); };
        };
        await db.putAttribute({ sk = key; key = "t"; value = #text(text) });
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Also remove voting data.
  public shared({caller}) func removeItem(canisterId: Principal, _itemId: Nat) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId);
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr);
        switch (oldItem.item.ownership) {
          case (#communal) {
            Debug.trap("it's communal");
          };
          case _ {};
        };
        lib.onlyItemOwner(caller, oldItem);
        await db.delete({sk = key});
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Set maximum lengths on user nick, chirp length, etc.

  /// Affiliates ///

  // public shared({caller}) func setAffiliate(canister: Principal, buyerAffiliate: ?Principal, sellerAffiliate: ?Principal): async () {
  //   var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canister));
  //   if (buyerAffiliate == null and sellerAffiliate == null) {
  //     await db.delete({sk = "a/" # Principal.toText(caller)});
  //   };
  //   let buyerAffiliateStr = switch (buyerAffiliate) {
  //     case (?user) { Principal.toText(user) };
  //     case (null) { "" }
  //   };
  //   let sellerAffiliateStr = switch (sellerAffiliate) {
  //     case (?user) { Principal.toText(user) };
  //     case (null) { "" }
  //   };
  //   // await db.put({sk = "a/" # Principal.toText(caller); attributes = [("v", #text (buyerAffiliateStr # "/" # sellerAffiliateStr))]});
  // };

  public shared func get_trusted_origins(): async [Text] {
    return [];
  }
}
