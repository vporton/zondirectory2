import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import Common "../storage/common";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import NacDBPartition "../storage/NacDBPartition";
import Entity "mo:candb/Entity";
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
import Payments "payments";
import RBT "mo:stable-rbtree/StableRBTree";
import Prng "mo:prng";
import lib "lib";

// TODO: Delete "hanging" items (as soon, as they found)

shared actor class Orders() = this {
  var initialized: Bool = false;

  stable var rng: Prng.Seiran128 = Prng.Seiran128(); // WARNING: This is not a cryptographically secure pseudorandom number generator.
  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  // TODO: Remove this function?
  public shared({ caller }) func init(): async () {
    if (initialized) {
      Debug.trap("already initialized");
    };

    // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    initialized := true;
  };

  // TODO: It seems that below there are many unused functions.

  // func _serializePointer(ptr: ?(CanDBPartition.CanDBPartition, GUID)): [Entity.AttributeValuePrimitive] {
  //   switch (ptr) {
  //     case (?(part, guid)) {
  //       [
  //         #int 2,
  //         #text(Principal.toText(Principal.fromActor(part))),
  //         #text(encodeGuid(guid)), // TODO: space-inefficient
  //       ];
  //     };
  //     case (null) { [#int 0] };
  //   }
  // };

  // The argument is a slice of an array, starting from the size of the fragment of the array to use.
  // func _deserializePointer(e: [Entity.AttributeValuePrimitive])
  //   : (?(CanDBPartition.CanDBPartition, GUID), [Entity.AttributeValuePrimitive])
  // {
  //   switch (e.size()) {
  //     case (0) { (null, Array.subArray(e, 1, Int.abs(e.size()-1))) };
  //     case (2) {
  //       let (#text(part), #text(guid)) = (e[1], e[2]) else {
  //         Debug.trap("wrong linked list pointer format");
  //       };
  //       (?(actor(part), decodeGuid(guid)), Array.subArray(e, 3, Int.abs(e.size()-3)));
  //     };
  //     case _ {
  //       Debug.trap("wrong linked list pointer format");
  //     }
  //   }
  // };

  // func serializeItemNode(node: ItemDListNode): [Entity.AttributeValuePrimitive] {
  //   let result = Buffer.Buffer<Entity.AttributeValuePrimitive>(7);
  //   result.append(Buffer.fromArray(_serializePointer(node.fwd)));
  //   result.append(Buffer.fromArray(_serializePointer(node.bwd)));
  //   result.add(#int(node.itemId));
  //   Buffer.toArray(result);
  // };

  // Returns deserialization of item and remaining data.
  // func deserializeItemNode(e: [Entity.AttributeValuePrimitive]): (ItemDListNode, [Entity.AttributeValuePrimitive]) {
  //   let (fwd, e1) = _deserializePointer(e);
  //   let (bwd, e2) = _deserializePointer(e1);
  //   let #int itemId = e2[0] else {
  //     Debug.trap("wrong linked list pointer format");
  //   };
  //   (
  //     {var fwd; var bwd; itemId = Int.abs(itemId)},
  //     Array.subArray(e2, 1, Int.abs(e2.size()-1)),
  //   );
  // };

  // Public API //

  // FIXME: Check function arguments (and whether they are used correctly).
  public shared({caller}) func addItemToCategory(catId: (CanDBPartition.CanDBPartition, Nat), itemId: (CanDBPartition.CanDBPartition, Nat)): async () {
    // TODO: The below reads&deserializes `categoryItemData` twice.
    let ?categoryItemData = await catId.0.get({sk = "i/" # Nat.toText(catId.1)}) else {
      Debug.trap("cannot get category item"); // FIXME: Should trap here?
    };
    let categoryItem = lib.deserializeItem(categoryItemData.attributes);

    switch (categoryItem.item.details) {
      case (#ownedCategory) {
        lib.onlyItemOwner(caller, categoryItem);
      };
      case _ {
        // TODO: Keep doing for other categories after a trap?
        Debug.trap("not a category");
      };
    };

    // FIXME: To reduce cost of moving an item (jumping over several items of the same weight),
    //        need to make multi-hash instead of just hash.
    // For now, I implement a simple hash-map, it does not need moving items around.

    // Put into the beginning of time order.
    let { timeOrderSubDB } = await obtainStreams(catId);
    let timeScanResult = await timeOrderSubDB.0.scanLimitOuter({
      dir = #bwd;
      outerKey = timeOrderSubDB.1;
      lowerBound = "";
      upperBound = "x";
      limit = 1;
      ascending = ?false;
    });
    // FIXME: The below is probably with errors.
    let timeScanSK = if (timeScanResult.results.size() == 0) { // empty list
      0;
    } else {
      let #int n = timeScanResult.results[0].1 else {
        Debug.trap("wrong stream"); // FIXME: trap?
      };
      n + 1;
    };
    let timeScanItemInfo = #tuple([#text(Principal.toText(Principal.fromActor(itemId.0))), #int(itemId.1)]);
    
    ignore await timeOrderSubDB.0.insert({
      guid = "xxx"; // FIXME
      indexCanister = actor(Principal.toText(Principal.fromActor(NacDBIndex))); // FIXME: This conversion is unreliable, but direct usage of NacDBIndex doesn't work in some reason.
      outerCanister = timeOrderSubDB.0;
      outerKey = timeOrderSubDB.1;
      sk = lib.encodeInt(timeScanSK);
      value = timeScanItemInfo;
    });
  };

  // Create streams for a folder identified by `itemId`, if they were not yet created.
  func obtainStreams(itemId: (CanDBPartition.CanDBPartition, Nat)): async {
    timeOrderSubDB: (
      NacDBPartition.Partition,
      Nat,
    );
    // votesOrderSubDB: ( // TODO
    //   NacDBPartition.Partition,
    //   Nat,
    // );
  } {
    let ?itemData = await itemId.0.get({sk = "i/" # Nat.toText(itemId.1)}) else {
      Debug.trap("cannot get category item"); // FIXME: Should trap here?
    };
    let item = lib.deserializeItem(itemData.attributes);
    switch (item.streams) {
      case (?data) { data };
      case null {
        let { outer = timeOrderSubDB } = await NacDBIndex.createSubDB({guid = GUID.nextGuid(guidGen); userData = ""}); // FIXME: `guid`
        item.streams := ?{timeOrderSubDB};
        let itemData = lib.serializeItem(item);
        itemId.0.insert({pk = ""/* FIXME */; sk = "i/" # Nat.toText(itemId.1); value = itemData}); // FIXME: `guid`
        {timeOrderSubDB};
      }
    };
  };

  /// Voting ///

  // FIXME: Below functions?

  // Determines item order.
  type ItemWeight = {
    weight: Float;
    random: Text; // TODO: Is this field used by the below algorithm.
  };

  // module ItemWeight {
  //   public func compare(X: ItemWeight, Y: ItemWeight): Order.Order {
  //     let c = Float.compare(X.weight, Y.weight);
  //     if (c != #equal) {
  //       c;
  //     } else {
  //       Text.compare(X.random, Y.random);
  //     }
  //   };
  // };

  // FIXME: Move votes to `order.mo`.
  type VotesTmp = {
    parent: Nat64;
    child: Nat64;
    var inProcess: Bool;
  };

  type VotesStream = {
    // var settingVotes: StableBuffer.StableBuffer<VotesTmp>; // TODO: Delete old ones.
    // var currentVotes: BTree.BTree<Nat64, ()>; // Item ID -> () // TODO: Delete old ones.
    prefix1: Text;
    prefix2: Text;
  };

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
  // FIXME: Rewrite this function.
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
        { weight = newVotesWeight; random = rng.next() };
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

  // TODO: Also ordering by time of publication (requires lexigraphical ordering by item ID).
}