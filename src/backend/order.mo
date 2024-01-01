import BTree "mo:stableheapbtreemap/BTree"; // TODO: Remove.
import Nac "mo:nacdb/NacDB";
import OpsQueue "mo:nacdb/OpsQueue"; // TODO: Remove.
import GUID "mo:nacdb/GUID";
import Common "../storage/common";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import NacDBPartition "../storage/NacDBPartition";
import Multi "mo:CanDBMulti/Multi";
import Entity "mo:candb/Entity";
import Reorder "mo:NacDBReorder/Reorder";
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
import Itertools "mo:itertools/Iter";
import MyCycles "mo:nacdb/Cycles";
import lib "lib";

// TODO: Delete "hanging" items (as soon, as they found)

shared({caller = initialOwner}) actor class Orders() = this {
  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("order: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  var initialized: Bool = false;

  // stable var rng: Prng.Seiran128 = Prng.Seiran128(); // WARNING: This is not a cryptographically secure pseudorandom number generator.
  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  stable let orderer = Reorder.createOrderer();

  // TODO: Remove this function?
  public shared({ caller }) func init(_owners: [Principal]): async () {
    checkCaller(caller);
    ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles); // TODO: another number of cycles?
    if (initialized) {
        Debug.trap("already initialized");
    };

    owners := _owners;
    MyCycles.addPart(Common.dbOptions.partitionCycles);
    initialized := true;
  };

  // Public API //

  func addItemToList(theSubDB: Reorder.Order, itemToAdd: (Principal, Nat), side: { #beginning; #end; #zero }): async* () {
    // FIXME: Prevent duplicate entries.
    let theSubDB2: Nac.OuterCanister = theSubDB.order.0;
    // FIXME: There are several streams.
    let timeScanSK = if (side == #zero) {
      0;
    } else {
      let scanResult = await theSubDB2.scanLimitOuter({
        dir = if (side == #end) { #bwd } else { #fwd };
        outerKey = theSubDB.order.1;
        lowerBound = "";
        upperBound = "x";
        limit = 1;
        ascending = ?(if (side == #end) { false } else { true });
      });
      let timeScanSK = if (scanResult.results.size() == 0) { // empty list
        0;
      } else {
        let t = scanResult.results[0].0;
        let n = lib.decodeInt(Text.fromIter(Itertools.takeWhile(t.chars(), func (c: Char): Bool { c != '#' })));
        Debug.print("t=" # t # "; n=" # debug_show(n));
        if (side == #end) { n + 1 } else { n - 1 };
      };
      timeScanSK;
    };
    let scanItemInfo = Nat.toText(itemToAdd.1) # "@" # Principal.toText(itemToAdd.0);
    
    let guid = GUID.nextGuid(guidGen);

    // FIXME: race condition
    await* Reorder.add(guid, NacDBIndex, orderer, {
      order = theSubDB;
      key = timeScanSK;
      value = scanItemInfo;
    });
  };

  public shared({caller}) func addItemToCategory(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool,
    side: { #beginning; #end }, // ignored unless adding to an owned folder
  ): async () {
    await* lib.checkSybil(caller);

    let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    // FIXME: Race condition when adding an item.
    // TODO: Ensure that it is retrieved once.
    let ?categoryItemData = await catId1.getAttribute({sk = "i/" # Nat.toText(catId.1)}, "i") else {
      Debug.trap("cannot get category item");
    };
    let categoryItem = lib.deserializeItem(categoryItemData);

    switch (categoryItem.item.details) {
      case (#ownedCategory) {
        lib.onlyItemOwner(caller, categoryItem);
      };
      case (#communalCategory) {};
      case _ {
        if (not comment) {
          Debug.trap("not a category");
        };
      };
    };
    let links = await* getStreamLinks(itemId, comment);
    await* addToStreams(catId, itemId, comment, links, itemId1, "st", "srt", #beginning);
    if (categoryItem.item.details == #ownedCategory) {
      await* addToStreams(catId, itemId, comment, links, itemId1, "sv", "srv", side);
    } else {
      await* addToStreams(catId, itemId, comment, links, itemId1, "sv", "srv", #end);
    };
    await* addToStreams(catId, itemId, comment, links, itemId1, "sp", "srp", #zero);
  };

  /// `key1` and `key2` are like `"s"` and `"sr"`
  func addToStreams(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool,
    links: lib.StreamsLinks,
    itemId1: CanDBPartition.CanDBPartition,
    key1: Text,
    key2: Text,
    side: { #beginning; #end; #zero },
  ): async* () {
    // Put into the beginning of time order.
    let streams1 = await* itemsOrder(catId, key1);
    let streams2 = await* itemsOrder(itemId, key2);
    let streamsVar1: [var ?Reorder.Order] = switch (streams1) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let streamsVar2: [var ?Reorder.Order] = switch (streams2) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let streams1t = switch (streams1) {
      case (?t) { t[links] };
      case (null) { null };
    };
    let stream1 = switch (streams1t) {
      case (?stream) { stream };
      case null {
        let v = await* Reorder.createOrder(GUID.nextGuid(guidGen), NacDBIndex, orderer);
        streamsVar1[links] := ?v;
        v;
      };
    };
    let streams2t = switch (streams2) {
      case (?t) { t[links] };
      case (null) { null };
    };
    let stream2 = switch (streams2t) {
      case (?stream) { stream };
      case null {
        let v = await* Reorder.createOrder(GUID.nextGuid(guidGen), NacDBIndex, orderer);
        streamsVar2[links] := ?v;
        v;
      };
    };
    await* addItemToList(stream1, itemId, side);
    await* addItemToList(stream2, catId, side);
    let itemData1 = lib.serializeStreams(Array.freeze(streamsVar1));
    let itemData2 = lib.serializeStreams(Array.freeze(streamsVar2));
    await itemId1.putAttribute({ sk = "i/" # Nat.toText(catId.1); key = key1; value = itemData1 });
    await itemId1.putAttribute({ sk = "i/" # Nat.toText(itemId.1); key = key2; value = itemData2 });
  };

  func getStreamLinks(/*catId: (Principal, Nat),*/ itemId: (Principal, Nat), comment: Bool)
    : async* lib.StreamsLinks
  {
    // let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));
    // TODO: Ensure that item data is readed once per `addItemToCategory` call.
    let ?childItemData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, "i") else {
      // TODO: Keep doing for other categories after a trap?
      Debug.trap("cannot get child item");
    };
    let childItem = lib.deserializeItem(childItemData);

    if (comment) {
      lib.STREAM_LINK_COMMENTS;
    } else {
      switch (childItem.item.details) {
        case (#communalCategory or #ownedCategory) { lib.STREAM_LINK_SUBCATEGORIES };
        case _ { lib.STREAM_LINK_SUBITEMS };
      };
    };
  };

  /// `key1` and `key2` are like `"s"` and `"sr"`
  /// TODO: No need to return an option type
  func itemsOrder(itemId: (Principal, Nat), key2: Text)
    : async* ?lib.Streams
  {
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    let streamsData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, key2);
    let streams = switch (streamsData) {
      case (?data) {
          lib.deserializeStreams(data);
      };
      case null {
        [null, null, null];
      };
    };
    ?streams;
  };

  /// Voting ///

  /// `amount == 0` means canceling the vote.
  public shared({caller}) func vote(parentPrincipal: Principal, parent: Nat, child: Nat, amount: Int, comment: Bool): async () {
    await* lib.checkSybil(caller);
    Debug.print("VOTE: " # debug_show(parent) # "@" # debug_show(parentPrincipal) # "/" # debug_show(child) # " " # debug_show(amount));
    assert amount == -1 or amount == 1 or amount == 0;

    let sk = "v/" # Principal.toText(caller) # "/" # Nat.toText(parent) # "/" # Nat.toText(child);
    let oldVotes = await CanDBIndex.getFirstAttribute("main", { sk; key = "v" }); // TODO: race condition
    let (principal, oldValue) = switch (oldVotes) {
      case (?oldVotes) { (?oldVotes.0, oldVotes.1) };
      case null { (null, null) };
    };
    let oldValue2 = switch (oldValue) {
      case (?v) {
        let #int v2 = v else {
          Debug.trap("wrong votes");
        };
        v2;
      };
      case null { 0 };
    };
    let difference = amount - oldValue2;
    if (difference == 0) {
      return;
    };
    ignore await CanDBIndex.putAttributeNoDuplicates("main", { sk; key = "v"; value = #int amount });

    // Update total votes for the given parent/child:
    let sk2 = "w/" # Nat.toText(parent) # "/" # Nat.toText(child);
    let oldTotals = await CanDBIndex.getFirstAttribute("main", { sk = sk2; key = "v" }); // TODO: race condition
    let (up, down, oldTotalsPrincipal) = switch (oldTotals) {
      case (?(oldTotalsPrincipal, ?(#tuple(a)))) {
        let (#int up, #int down) = (a[0], a[1]) else {
          Debug.trap("votes programming error")
        };
        (up, down, ?oldTotalsPrincipal);
      };
      case null {
        (0, 0, null);
      };
      case _ {
        Debug.trap("votes programming error");
      };
    };

    // TODO: Check this block of code for errors.
    let changeUp = (amount == 1 and oldValue2 != 1) or (oldValue2 == 1 and amount != 1);
    let changeDown = (amount == -1 and oldValue2 != -1) or (oldValue2 == -1 and amount != -1);
    var up2 = up;
    var down2 = down;
    if (changeUp or changeDown) {
      if (changeUp) {
        up2 += difference;
      };
      if (changeDown) {
        down2 -= difference;
      };
      // TODO: Take advantage of `oldTotalsPrincipal` as a hint:
      ignore await CanDBIndex.putAttributeNoDuplicates("main", { sk = sk2; key = "v"; value = #tuple([#int up2, #int down2]) }); // TODO: race condition
    };

    let parentCanister = actor(Principal.toText(parentPrincipal)) : CanDBPartition.CanDBPartition;
    let links = await* getStreamLinks((parentPrincipal, parent), comment);
    let streamsData = await* itemsOrder((parentPrincipal, parent), "sv");
    let streamsVar: [var ?Reorder.Order] = switch (streamsData) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let order = switch (streamsVar[links]) {
      case (?order) { order };
      case null {
        let order = await* Reorder.createOrder(GUID.nextGuid(guidGen), NacDBIndex, orderer);
        streamsVar[links] := ?order;
        order;
      };
    };

    let data = lib.serializeStreams(Array.freeze(streamsVar));
    await parentCanister.putAttribute({ sk = "i/" # Nat.toText(parent); key = "sv"; value = data });

    await* Reorder.move(GUID.nextGuid(guidGen), NacDBIndex, orderer, {
        order;
        value = lib.encodeNat(child);
        relative = true;
        newKey = difference ** 2**32;
    });
  };

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