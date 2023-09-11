import ICRC1Types "mo:icrc1/ICRC1/Types";
import Token "mo:icrc1/ICRC1/Canisters/Token";
import CanDBIndex "../storage/CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "../storage/NacDBIndex";
import NacDBPartition "../storage/NacDBPartition";
import Nac "mo:nacdb/NacDB";
import MyCycles "mo:nacdb/Cycles";
import Common "../storage/common";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Entity "mo:candb/Entity";
import BTree "mo:btree/BTree";
import RBT "mo:stable-rbtree/StableRBTree";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import xNat "mo:xtendedNumbers/NatX";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import fractions "./fractions";
import HashMap "mo:base/HashMap";
import Nat8 "mo:base/Nat8";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Order "mo:base/Order";
import Prng "mo:motoko-lib/Prng";
import StableBuffer "mo:StableBuffer/StableBuffer";

shared actor class ZonBackend() = this {
  /// External Canisters ///

  let phoneNumberVerificationCanisterId = "gzqxf-kqaaa-aaaak-qakba-cai"; // https://docs.nfid.one/developer/credentials/mobile-phone-number-credential

  /// Some Global Variables ///

  stable var canDBIndex: ?CanDBIndex.CanDBIndex = null;
  stable var nacDBIndex: ?NacDBIndex.NacDBIndex = null;

  // FIXME: Fix this comment.
  // "s/" - anti-sybil
  // "u/" - Principal -> User
  // "i/" - ID -> Item
  // "a/" - user -> <buyer affiliate>/<seller affiliate>
  // // "v/" - <parent>/<votes>/<random> -> <child> [prefix1]
  // // "p/" - <parent>/<child> -> <votes> [prefix2]
  // // "q/" - <parent>/<child> -> <quadratic votes> [prefix1]
  // // "w/" - <parent>/<quadratic votes>/<random> -> <child> [prefix2]
  // TODO: Avoid duplicate user nick names.

  stable var maxId: Nat64 = 0;

  stable var founder: ?Principal = null;

  /// Initialization ///

  public shared({ caller }) func init(subaccount : ?ICRC1Types.Subaccount): async () {
    ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    founder := ?caller;
    if (canDBIndex == null) {
      MyCycles.addPart(Common.dbOptions.partitionCycles);
      canDBIndex := ?(await CanDBIndex.CanDBIndex([Principal.fromActor(this)]));
    };
    if (nacDBIndex == null) {
      MyCycles.addPart(Common.dbOptions.partitionCycles);
      nacDBIndex := ?(await NacDBIndex.NacDBIndex([Principal.fromActor(this)]));
    };
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

  func checkSybil(sybilCanister: Principal, user: Principal): async* () {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(sybilCanister));
    switch (await db.get({sk = "s/" # Principal.toText(user)})) {
      case (null) {
        Debug.trap("not verified user");
      };
      case _ {};
    };
  };

  // anti-Sybil verification
  public shared({caller}) func verifyUser(sybilCanister: Principal): async () {
    let verifyActor = actor(phoneNumberVerificationCanisterId): actor {
      is_phone_number_approved(principal: Text) : async Bool;
    };
    if (await verifyActor.is_phone_number_approved(Principal.toText(caller))) {
      var db: CanDBPartition.CanDBPartition = actor(Principal.toText(sybilCanister));
      await db.put({sk = "s/" # Principal.toText(caller); attributes = [("v", #bool true)]});
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
    await* checkSybil(sybilCanisterId, caller);
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

  type ItemWithoutOwner = {
    price: Nat;
    locale: Text;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #message : ();
      #post : ();
      #ownedCategory : ();
      #communalCategory : ();
    };
  };


  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Item version.
  type Item = {
    creator: Principal;
    item: ItemWithoutOwner;
  };

  func onlyItemOwner(caller: Principal, _item: Item) {
    if (caller != _item.creator) {
      Debug.trap("not the item owner");
    };
  };

  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_OWNED_CATEGORY = 3;
  let ITEM_TYPE_COMMUNAL_CATEGORY = 4;

  func serializeItemAttr(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int (switch (item.item.details) {
      case (#link v) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post) { ITEM_TYPE_POST };
      case (#ownedCategory) { ITEM_TYPE_OWNED_CATEGORY };
      case (#communalCategory) { ITEM_TYPE_COMMUNAL_CATEGORY };
    }));
    buf.add(#text (Principal.toText(item.creator)));
    buf.add(#int (item.item.price));
    buf.add(#text (item.item.locale));
    buf.add(#text (item.item.title));
    buf.add(#text (item.item.description));
    switch (item.item.details) {
      case (#link v) {
        buf.add(#text v);
      };
      case _ {};
    };
    #tuple (Buffer.toArray(buf));
  };

  func serializeItem(item: Item): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeItemAttr(item))];
  };

  func deserializeItemAttr(attr: Entity.AttributeValue): Item {
    var kind: Nat = 0;
    var creator: ?Principal = null;
    var price = 0;
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
                case (#int v) {
                  price := Int.abs(v);
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
          case (2) { #post };
          case (3) { #ownedCategory };
          case (4) { #communalCategory };
          case _ { Debug.trap("wrong item format"); }
        };
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

  public shared({caller}) func createItemData(canisterId: Principal, _item: ItemWithoutOwner, sybilCanisterId: Principal) {
    await* checkSybil(sybilCanisterId, caller);

    let item2 = { creator = caller; item = _item; };
    let _itemId = maxId;
    maxId += 1;
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    await db.put({sk = key; attributes = serializeItem(item2)});
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, _itemId: Nat64, item: ItemWithoutOwner) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr.attributes);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        let _item = { item = item; creator = caller };
        if (_item.item.details != oldItem.item.details) {
          Debug.trap("can't change item type");
        };
        if (oldItem.item.details == #communalCategory) {
          Debug.trap("can't edit communal category");
        };
        onlyItemOwner(caller, oldItem);
        await db.put({sk = key; attributes = serializeItem(_item)});
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
        let oldItem = deserializeItem(oldItemRepr.attributes);
        if (oldItem.item.details == #communalCategory) {
          Debug.trap("it's communal")
        };
        onlyItemOwner(caller, oldItem);
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

  /// Voting ///

  // Determines item order.
  type ItemWeight = {
    weight: Float;
    random: Text; // TODO: Is this field used by the below algorithm.
  };

  module ItemWeight {
    public func compare(X: ItemWeight, Y: ItemWeight): Order.Order {
      let c = Float.compare(X.weight, Y.weight);
      if (c != #equal) {
        c;
      } else {
        Text.compare(X.random, Y.random);
      }
    };
  };

  type VotesTmp = {
    parent: Nat64;
    child: Nat64;
    var inProcess: Bool;
  };

  type VotesStream = {
    var settingVotes: StableBuffer.StableBuffer<VotesTmp>; // TODO: Delete old ones.
    var currentVotes: BTree.BTree<Nat64, ()>; // Item ID -> () // TODO: Delete old ones.
    prefix1: Text;
    prefix2: Text;
  };

  // TODO: Check out the UUID and ULID libraries: https://github.com/aviate-labs/ulid.mo
  // TODO: Does the below initialize pseudo-random correctly?
  // stable var rng = Prng.SFC64a(); // WARNING: This is not a cryptographically secure pseudorandom number generator.

  func deserializeVoteAttr(attr: Entity.AttributeValue): Float {
    switch(attr) {
      case (#float v) { v };
      case _ { Debug.trap("wrong data"); };
    }
  };
  
  func deserializeVotes(map: Entity.AttributeMap): Float {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeVoteAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  // TODO: It has race period of duplicate (two) keys. In frontend de-duplicate.
  // TODO: Use binary keys.
  // FIXME: Sorting CanDB by `Float` is wrong order.
  func setVotes(
    stream: VotesStream,
    oldVotesRandom: Text,
    votesUpdater: ?Float -> Float,
    oldVotesDBCanisterId: Principal,
    parentChildCanisterId: Principal,
  ): async* () {
    if (StableBuffer.size(stream.settingVotes) != 0) {
      return;
    };
    let tmp = StableBuffer.get(stream.settingVotes, Int.abs((StableBuffer.size(stream.settingVotes): Int) - 1));

    // Prevent races:
    if (not tmp.inProcess) {
      if (BTree.has(stream.currentVotes, Nat64.compare, tmp.parent) or BTree.has(stream.currentVotes, Nat64.compare, tmp.child)) {
        Debug.trap("clash");
      };
      ignore BTree.insert(stream.currentVotes, Nat64.compare, tmp.parent, ());
      ignore BTree.insert(stream.currentVotes, Nat64.compare, tmp.child, ());
      tmp.inProcess := true;
    };

    let oldVotesDB: CanDBPartition.CanDBPartition = actor(Principal.toText(oldVotesDBCanisterId));
    let oldVotesKey = stream.prefix2 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Nat.toText(xNat.from64ToNat(tmp.child));
    let oldVotesWeight = switch (await oldVotesDB.get({sk = oldVotesKey})) {
      case (?oldVotesData) { ?deserializeVotes(oldVotesData.attributes) };
      case (null) { null }
    };
    let newVotes = switch (oldVotesWeight) {
      case (?oldVotesWeight) {
        let newVotesWeight = votesUpdater(?oldVotesWeight);
        { weight = newVotesWeight; random = oldVotesRandom };
      };
      case (null) {
        let newVotesWeight = votesUpdater null;
        { weight = newVotesWeight; random = 0/*rng.next()*/ }; // FIXME
      };
    };

    // TODO: Should use binary format. // FIXME: Decimal serialization makes order by `random` broken.
    // newVotes -> child
    let newKey = stream.prefix1 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Float.toText(newVotes.weight) # "/" # oldVotesRandom;
    await oldVotesDB.put({sk = newKey; attributes = [("v", #text (Nat.toText(Nat64.toNat(tmp.child))))]});
    // child -> newVotes
    let parentChildCanister: CanDBPartition.CanDBPartition = actor(Principal.toText(parentChildCanisterId));
    let newKey2 = stream.prefix2 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Nat.toText(xNat.from64ToNat(tmp.child));
    // FIXME: Use NacDB:
    await parentChildCanister.put({sk = newKey2; attributes = [("v", #float (newVotes.weight))]});
    switch (oldVotesWeight) {
      case (?oldVotesWeight) {
        let oldKey = stream.prefix1 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Float.toText(oldVotesWeight) # "/" # oldVotesRandom;
        // delete oldVotes -> child
        await oldVotesDB.delete({sk = oldKey});
      };
      case (null) {};
    };

    ignore StableBuffer.removeLast(stream.settingVotes);
  };

  stable var userBusyVoting: BTree.BTree<Principal, ()> = BTree.init<Principal, ()>(null); // TODO: Delete old ones.

  // TODO: Need to remember the votes // FIXME: Remembering in CanDB makes no sense because need to check canister.
  public shared({caller}) func oneVotePerPersonVote(sybilCanister: Principal) {
    await* checkSybil(sybilCanister, caller);
    ignore BTree.insert(userBusyVoting, Principal.compare, caller, ());
    
    // setVotes(
    //   stream: VotesStream,
    //   oldVotesRandom: Text,
    //   votesUpdater: ?Float -> Float,
    //   oldVotesDBCanisterId: Principal,
    //   parentChildCanisterId)
    // TODO
  };

  // func setVotes2(parent: Nat64, child: Nat64, prefix1: Text, prefix2: Text) {

  // }

  // TODO: Also ordering by time of publication (requires lexigraphical ordering by item ID).
};
