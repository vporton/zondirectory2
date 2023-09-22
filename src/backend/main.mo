import ICRC1Types "mo:icrc1/ICRC1/Types";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import MyCycles "mo:nacdb/Cycles";
import Common "../storage/common";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Entity "mo:candb/Entity";
import BTree "mo:btree/BTree";
import RBT "mo:stable-rbtree/StableRBTree";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import xNat "mo:xtendedNumbers/NatX";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Order "mo:base/Order";
import StableBuffer "mo:StableBuffer/StableBuffer";
import Payments "payments";
import NacDbPartition "../storage/NacDBPartition";
import lib "lib";
import config "../../config";

shared actor class ZonBackend() = this {
  /// External Canisters ///

  let phoneNumberVerificationCanisterId = "gzqxf-kqaaa-aaaak-qakba-cai"; // https://docs.nfid.one/developer/credentials/mobile-phone-number-credential

  /// Some Global Variables ///

  // See ARCHITECTURE.md for database structure

  // TODO: Avoid duplicate user nick names.

  stable var maxId: Nat64 = 0;

  stable var founder: ?Principal = null;

  /// Initialization ///

  stable var initialized: Bool = false;

  public shared({ caller }) func init(subaccount : ?ICRC1Types.Subaccount): async () {
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

  // Callback (no need to check the caller).
  public shared func _antiSybilMark(_: ?Entity.AttributeValue): async Entity.AttributeValue { #bool true };

  // anti-Sybil verification
  public shared({caller}) func verifyUser(sybilCanister: ?Principal): async () {
    if (config.skipSybil) {
      return;
    };
    let verifyActor = actor(phoneNumberVerificationCanisterId): actor {
      is_phone_number_approved(principal: Text) : async Bool;
    };
    if (await verifyActor.is_phone_number_approved(Principal.toText(caller))) {
      // FIXME: Use User object from "u/" instead.
      switch (sybilCanister) {
        case (?sybilCanister) {
          var db: CanDBPartition.CanDBPartition = actor(Principal.toText(sybilCanister));
          await db.transformAttribute(
            "u/" # Principal.toText(caller),
            "s",
            _antiSybilMark,
          );
        };
        case null {
          // FIXME: Check that there was no user with this principal.
          // FIXME: new interface
          await CanDBIndex.putNoDuplicates("user", {sk = "u/" # Principal.toText(caller); attributes = [("v", #bool true)]}); // FIXME
        };
      }
    } else {
      Debug.trap("cannot verify phone number");
    };
  };

  type User = {
    locale: Text;
    nick: Text;
    title: Text;
    description: Text;
    link : Text;
  };

  func serializeUserAttr(user: User): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(5);
    buf.add(#text (user.locale));
    buf.add(#text (user.nick));
    buf.add(#text (user.title));
    buf.add(#text (user.description));
    buf.add(#text (user.link));
    #tuple (Buffer.toArray(buf));
  };

  func serializeUser(user: User): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeUserAttr(user))];
  };

  func deserializeUserAttr(attr: Entity.AttributeValue): User {
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
                case (#text v) {
                  locale := v;
                };
                case _ { break r false };
              };
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false };
              };
            };
            case (2) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false };
              };
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false };
              };
            };
            case (4) {
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

  func deserializeUser(map: Entity.AttributeMap): User {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeUserAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  public shared({caller}) func setUserData(canisterId: Principal, _user: User, sybilCanisterId: Principal) {
    await* lib.checkSybil(sybilCanisterId, caller);
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    await db.put({sk = key; attributes = serializeUser(_user)});
  };

  // TODO: Should also remove all his/her items?
  public shared({caller}) func removeUser(canisterId: Principal) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };

  /// Items ///

  public shared({caller}) func createItemData(canisterId: Principal, _item: lib.ItemWithoutOwner, sybilCanisterId: Principal)
    : async (Principal, Text)
  {
    await* lib.checkSybil(sybilCanisterId, caller);

    let item2: lib.Item = { creator = caller; item = _item; var streams = null; };
    let _itemId = maxId;
    maxId += 1;
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    await db.put({sk = key; attributes = lib.serializeItem(item2)});
    (canisterId, key);
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, _itemId: Nat64, item: lib.ItemWithoutOwner) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr.attributes);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        let _item: lib.Item = { item = item; creator = caller; var streams = null; };
        if (_item.item.details != oldItem.item.details) {
          Debug.trap("can't change item type");
        };
        switch (oldItem.item.details) {
          case (#communalCategory) {
            Debug.trap("can't edit communal category");
          };
          case _ {};
        };
        lib.onlyItemOwner(caller, oldItem);
        await db.put({sk = key; attributes = lib.serializeItem(_item)});
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Also remove voting data.
  public shared({caller}) func removeItem(canisterId: Principal, _itemId: Nat64) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr.attributes);
        switch (oldItem.item.details) {
          case (#communalCategory) {
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

  public shared({caller}) func setAffiliate(canister: Principal, buyerAffiliate: ?Principal, sellerAffiliate: ?Principal): async () {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canister));
    if (buyerAffiliate == null and sellerAffiliate == null) {
      await db.delete({sk = "a/" # Principal.toText(caller)});
    };
    let buyerAffiliateStr = switch (buyerAffiliate) {
      case (?user) { Principal.toText(user) };
      case (null) { "" }
    };
    let sellerAffiliateStr = switch (sellerAffiliate) {
      case (?user) { Principal.toText(user) };
      case (null) { "" }
    };
    await db.put({sk = "a/" # Principal.toText(caller); attributes = [("v", #text (buyerAffiliateStr # "/" # sellerAffiliateStr))]});
  };

  };
