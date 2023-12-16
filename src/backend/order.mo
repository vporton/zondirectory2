import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import Common "../storage/common";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import NacDBPartition "../storage/NacDBPartition";
import Entity "mo:candb/Entity";
import Reorder "mo:reorder/Reorder";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Payments "payments";
import RBT "mo:stable-rbtree/StableRBTree";
import StableBuffer "mo:StableBuffer/StableBuffer";
import lib "lib";

// TODO: Delete "hanging" items (as soon, as they found)

shared actor class Orders() = this {
  var initialized: Bool = false;

  // stable var rng: Prng.Seiran128 = Prng.Seiran128(); // WARNING: This is not a cryptographically secure pseudorandom number generator.
  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  stable let orderer = Reorder.createOrderer(NacDBIndex);

  // TODO: Remove this function?
  public shared({ caller }) func init(): async () {
    if (initialized) {
      Debug.trap("already initialized");
    };

    // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    initialized := true;
  };

  // Public API //

  func addItemToTimeList(theSubDB: Reorder.Order, itemToAdd: (Principal, Nat)): async* () {
    // FIXME: Check caller.
    // FIXME: Prevent duplicate entries.
    let theSubDB2: Nac.OuterCanister = theSubDB.order.0;
    // FIXME: There are several streams.
    let timeScanResult = await theSubDB2.scanLimitOuter({
      dir = #fwd;
      outerKey = theSubDB.order.1;
      lowerBound = "";
      upperBound = "x";
      limit = 1;
      ascending = ?true;
    });
    let timeScanSK = if (timeScanResult.results.size() == 0) { // empty list
      0;
    } else {
      let t = timeScanResult.results[0].0;
      let n = lib.decodeInt(t);
      n - 1;
    };
    let timeScanItemInfo = Nat.toText(itemToAdd.1) # "@" # Principal.toText(itemToAdd.0);
    
    let guid = GUID.nextGuid(guidGen);

    // FIXME: race condition
    await* Reorder.add(guid, {
      index = NacDBIndex;
      orderer;
      order = theSubDB;
      key = timeScanSK;
      value = timeScanItemInfo;
    });
  };

  public shared({caller}) func addItemToCategory(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool,
  ): async () {
    await* lib.checkSybil(caller);

    let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    let ?categoryItemData = await catId1.getAttribute({sk = "i/" # Nat.toText(catId.1)}, "i") else {
      Debug.trap("cannot get category item");
    };
    let categoryItem = lib.deserializeItem(categoryItemData);

    switch (categoryItem.item.details) {
      case (#ownedCategory) {
        lib.onlyItemOwner(caller, categoryItem);
      };
      // case (#communalCategory) {};
      case _ {
        // We allow to post a subitem not of a category, it's called comments.
        // Debug.trap("not a category");
      };
    };

    // Put into the beginning of time order.
    let (streams, timePair) = await* itemsTimeOrderPair(catId, itemId, comment);
    let streams2: [var ?(Reorder.Order, Reorder.Order)] = Array.thaw(streams);
    let stream = switch (streams[timePair]) {
      case (?stream) { stream };
      case null {
        let pair = (
          await* Reorder.createOrder(GUID.nextGuid(guidGen), {orderer}),
          await* Reorder.createOrder(GUID.nextGuid(guidGen), {orderer}),
        );
        streams2[timePair] := ?pair;
        pair;
      };
    };
    await* addItemToTimeList(stream.0, itemId);
    await* addItemToTimeList(stream.1, catId);
    let itemData = lib.serializeStreams(Array.freeze(streams2));
    await itemId1.putAttribute("i/" # Nat.toText(itemId.1), "s", itemData); // FIXME: Get/set by pair folder/item, not by item only.
  };

  func itemsTimeOrderPair(catId: (Principal, Nat), itemId: (Principal, Nat), comment: Bool)
    : async* (lib.Streams, lib.StreamsLinks)
  {
    let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));
    // TODO: Ensure that item data is readed once per `addItemToCategory` call.
    let ?childItemData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, "i") else {
      // TODO: Keep doing for other categories after a trap?
      Debug.trap("cannot get child item");
    };
    let childItem = lib.deserializeItem(childItemData);

    let streamsData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, "s"); // FIXME: Get/set by pair folder/item, not by item only.
    let streams = switch (streamsData) {
      case (?data) {
        lib.deserializeStreams(data);
      };
      case null {
        [null, null, null];
      }
    };

    let streamLink = if (comment) {
      lib.STREAM_LINK_COMMENTS;
    } else {
      switch (childItem.item.details) {
        case (#communalCategory or #ownedCategory) { lib.STREAM_LINK_SUBCATEGORIES };
        case _ { lib.STREAM_LINK_SUBITEMS };
      };
    };
    (streams, streamLink);
  };

  /// Voting ///

  // FIXME: Below functions?

  // func deserializeVoteAttr(attr: Entity.AttributeValue): Float {
  //   switch(attr) {
  //     case (#float v) { v };
  //     case _ { Debug.trap("wrong data"); };
  //   }
  // };
  
  // func deserializeVotes(map: Entity.AttributeMap): Float {
  //   let v = RBT.get(map, Text.compare, "v");
  //   switch (v) {
  //     case (?v) { deserializeVoteAttr(v) };
  //     case _ { Debug.trap("map not found") };
  //   };    
  // };

  // TODO: It has race period of duplicate (two) keys. In frontend de-duplicate.
  // TODO: Use binary keys.
  // FIXME: Sorting CanDB by `Float` is wrong order.
  // func setVotes(
  //   stream: VotesStream,
  //   oldVotesRandom: Text,
  //   votesUpdater: ?Float -> Float,
  //   oldVotesDBCanisterId: Principal,
  //   parentChildCanisterId: Principal,
  // ): async* () {
  //   if (StableBuffer.size(stream.settingVotes) != 0) {
  //     return;
  //   };
  //   let tmp = StableBuffer.get(stream.settingVotes, Int.abs((StableBuffer.size(stream.settingVotes): Int) - 1));

  //   // Prevent races:
  //   if (not tmp.inProcess) {
  //     if (BTree.has(stream.currentVotes, Nat64.compare, tmp.parent) or BTree.has(stream.currentVotes, Nat64.compare, tmp.child)) {
  //       Debug.trap("clash");
  //     };
  //     ignore BTree.insert(stream.currentVotes, Nat64.compare, tmp.parent, ());
  //     ignore BTree.insert(stream.currentVotes, Nat64.compare, tmp.child, ());
  //     tmp.inProcess := true;
  //   };

  //   let oldVotesDB: CanDBPartition.CanDBPartition = actor(Principal.toText(oldVotesDBCanisterId));
  //   let oldVotesKey = stream.prefix2 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Nat.toText(xNat.from64ToNat(tmp.child));
  //   let oldVotesWeight = switch (await oldVotesDB.get({sk = oldVotesKey})) {
  //     case (?oldVotesData) { ?deserializeVotes(oldVotesData.attributes) };
  //     case (null) { null }
  //   };
  //   let newVotes = switch (oldVotesWeight) {
  //     case (?oldVotesWeight) {
  //       let newVotesWeight = votesUpdater(?oldVotesWeight);
  //       { weight = newVotesWeight; random = oldVotesRandom };
  //     };
  //     case (null) {
  //       let newVotesWeight = votesUpdater null;
  //       { weight = newVotesWeight; random = rng.next() };
  //     };
  //   };

  //   // TODO: Should use binary format. // FIXME: Decimal serialization makes order by `random` broken.
  //   // newVotes -> child
  //   let newKey = stream.prefix1 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Float.toText(newVotes.weight) # "/" # oldVotesRandom;
  //   await oldVotesDB.put({sk = newKey; attributes = [("v", #text (Nat.toText(Nat64.toNat(tmp.child))))]});
  //   // child -> newVotes
  //   let parentChildCanister: CanDBPartition.CanDBPartition = actor(Principal.toText(parentChildCanisterId));
  //   let newKey2 = stream.prefix2 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Nat.toText(xNat.from64ToNat(tmp.child));
  //   // FIXME: Use NacDB:
  //   await parentChildCanister.put({sk = newKey2; attributes = [("v", #float (newVotes.weight))]});
  //   switch (oldVotesWeight) {
  //     case (?oldVotesWeight) {
  //       let oldKey = stream.prefix1 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Float.toText(oldVotesWeight) # "/" # oldVotesRandom;
  //       // delete oldVotes -> child
  //       await oldVotesDB.delete({sk = oldKey});
  //     };
  //     case (null) {};
  //   };

  //   ignore StableBuffer.removeLast(stream.settingVotes);
  // };

  // stable var userBusyVoting: BTree.BTree<Principal, ()> = BTree.init<Principal, ()>(null); // TODO: Delete old ones.

  // TODO: Need to remember the votes // FIXME: Remembering in CanDB makes no sense because need to check canister.
  // public shared({caller}) func oneVotePerPersonVote(sybilCanister: Principal) {
  //   await* checkSybil(sybilCanister, caller);
  //   ignore BTree.insert(userBusyVoting, Principal.compare, caller, ());
    
  //   // setVotes(
  //   //   stream: VotesStream,
  //   //   oldVotesRandom: Text,
  //   //   votesUpdater: ?Float -> Float,
  //   //   oldVotesDBCanisterId: Principal,
  //   //   parentChildCanisterId)
  //   // TODO
  // };

  // func setVotes2(parent: Nat64, child: Nat64, prefix1: Text, prefix2: Text) {

  // }
}