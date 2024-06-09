import Nac "mo:nacdb/NacDB";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Reorder "mo:nacdb-reorder/Reorder";
import GUID "mo:nacdb/GUID";
import Itertools "mo:itertools/Iter";
import CanDBIndex "canister:CanDBIndex";
import NacDBIndex "canister:NacDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import MyCycles "mo:nacdb/Cycles";
import DBConfig "../libs/configs/db.config";
import lib "lib";
import AI "ai";
import AITypes "HttpTypes";

shared({caller = initialOwner}) actor class Items() = this {
  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("item: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  stable var initialized: Bool = false;

  public shared({ caller }) func init(_owners: [Principal]): async () { // FIXME: Initialize in Makefile.
    checkCaller(caller);
    ignore MyCycles.topUpCycles<system>(DBConfig.dbOptions.partitionCycles); // TODO: another number of cycles?
    if (initialized) {
        Debug.trap("already initialized");
    };

    owners := _owners;
    MyCycles.addPart<system>(DBConfig.dbOptions.partitionCycles);

    initialized := true;
  };

  /// Items ///

  stable var maxId: Nat = 0;

  public query func checkSpamTransform(args: AITypes.TransformArgs): async AITypes.HttpResponsePayload {
    AI.removeHTTPHeaders(args);
  };

  private func itemCheckSpam(item: lib.ItemDataWithoutOwner): async* () {
    if (not (await* AI.checkSpam(item.title # "\n" # item.description, checkSpamTransform))) {
      Debug.trap("spam");
    };
  };

  public shared({caller}) func createItemData(item: lib.ItemTransferWithoutOwner)
    : async (Principal, Nat)
  {
    await* itemCheckSpam(item.data);
    let (canisterId, itemId) = if (item.communal) {
      let variant: lib.ItemVariant = { creator = caller; item = item.data; };
      let variantId = maxId;
      maxId += 1;
      let variantKey = "r/" # Nat.toText(variantId);
      let variantCanisterId = await CanDBIndex.putAttributeWithPossibleDuplicate(
        "main", { sk = variantKey; key = "i"; value = lib.serializeItemVariant(variant) }
      );
      let itemId = maxId;
      maxId += 1;
      let itemKey = "i/" # Nat.toText(itemId);
      let timeStream = await NacDBIndex.reorderCreateOrder(GUID.nextGuid(guidGen));
      let votesStream = await NacDBIndex.reorderCreateOrder(GUID.nextGuid(guidGen));
      let item2 = #communal { timeStream; votesStream; isFolder = item.data.details == #folder };
      let variantValue = Nat.toText(variantId) # "@" # Principal.toText(variantCanisterId);
      await NacDBIndex.reorderAdd(GUID.nextGuid(guidGen), {
        hardCap = ?100; key = -2; order = votesStream; value = variantValue; // TODO: Take position `key` configurable.
      });

      // Put variant in time stream // TODO: duplicate code
      let scanResult = await timeStream.order.0.scanLimitOuter({
        dir = #fwd;
        outerKey = timeStream.order.1;
        lowerBound = "";
        upperBound = "x";
        limit = 1;
        ascending = ?true;
      });
      let timeScanSK = if (scanResult.results.size() == 0) { // empty list
        0;
      } else {
        let t = scanResult.results[0].0;
        let n = lib.decodeInt(Text.fromIter(Itertools.takeWhile(t.chars(), func (c: Char): Bool { c != '#' })));
        n - 1;
      };
      let guid = GUID.nextGuid(guidGen);
      // TODO: race condition
      await NacDBIndex.reorderAdd(guid, {
        order = timeStream;
        key = timeScanSK;
        value = variantValue;
        hardCap = DBConfig.dbOptions.hardCap;
      });

      let itemCanisterId = await CanDBIndex.putAttributeWithPossibleDuplicate(
        "main", { sk = itemKey; key = "i"; value = lib.serializeItem(item2) }
      );
      (itemCanisterId, itemId);
    } else {
      let item2: lib.Item = #owned { creator = caller; item = item.data; edited = false };
      let itemId = maxId;
      maxId += 1;
      let key = "i/" # Nat.toText(itemId);
      let canisterId = await CanDBIndex.putAttributeWithPossibleDuplicate(
        "main", { sk = key; key = "i"; value = lib.serializeItem(item2) }
      );
      (canisterId, itemId);
    };

    await* insertIntoAllTimeStream((canisterId, itemId));
    (canisterId, itemId);
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, itemId: Nat, item: lib.ItemDataWithoutOwner) {
    await* itemCheckSpam(item);
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr);
        let item2: lib.ItemData = { item = item; creator = caller; edited = true }; // TODO: edited only if actually changed
        lib.onlyItemOwner(caller, oldItem); // also rejects changing communal items.
        await db.putAttribute({sk = key; key = "i"; value = lib.serializeItem(#owned item2)});
      };
      case null { Debug.trap("no item") };
    };
  };

  // TODO: If item set is successful and setPostText is unsuccessful, this is counter-intuitive.
  public shared({caller}) func setPostText(canisterId: Principal, _itemId: Nat, text: Text) {
    if (not (await* AI.checkSpam(text, checkSpamTransform))) {
      Debug.trap("spam");
    };

    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = lib.deserializeItem(oldItemRepr);
        lib.onlyItemOwner(caller, oldItem);
        switch (oldItem) {
          case (#owned data) {
            switch (data.item.details) {
              case (#post) {};
              case _ { Debug.trap("not a post"); };
            };
          };
          case (#communal _) { Debug.trap("programming error") };
        };
        await db.putAttribute({ sk = key; key = "t"; value = #text(text) });
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Also remove voting data.
  public shared({caller}) func removeItem(canisterId: Principal, itemId: Nat) {
    // We first remove links, then the item itself, in order to avoid race conditions when displaying.
    await* removeItemLinks((canisterId, itemId));
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(itemId);
    let ?oldItemRepr = await db.getAttribute({sk = key}, "i") else {
      Debug.trap("no item");
    };
    let oldItem = lib.deserializeItem(oldItemRepr);
    // if (oldItem.item.communal) { // FIXME
    //   Debug.trap("it's communal");
    // };
    lib.onlyItemOwner(caller, oldItem);
    await db.delete({sk = key});
  };

  /// Order of items ///

  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0)); // FIXME: Gather randomness.

  func addItemToList(theSubDB: Reorder.Order, itemToAdd: (Principal, Nat), side: { #beginning; #end; #zero }): async* () {
    let scanItemInfo = Nat.toText(itemToAdd.1) # "@" # Principal.toText(itemToAdd.0);
    let theSubDB2: Nac.OuterCanister = theSubDB.order.0;
    if (await theSubDB2.hasByOuter({outerKey = theSubDB.reverse.1; sk = scanItemInfo})) {
      return; // prevent duplicate
    };
    // TODO: race

    // TODO: duplicate code

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
        if (side == #end) { n + 1 } else { n - 1 };
      };
      timeScanSK;
    };
    
    let guid = GUID.nextGuid(guidGen);

    // TODO: race condition
    await NacDBIndex.reorderAdd(guid, {
      order = theSubDB;
      key = timeScanSK;
      value = scanItemInfo;
      hardCap = DBConfig.dbOptions.hardCap;
    });
  };

  // func removeItemFromFolder(parent: (Principal, Nat), child: (Principal, Nat)): async* () {
  // };

  // Public API //

  public shared({caller}) func addItemToFolder(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool,
    side: { #beginning; #end }, // ignored unless adding to an owned folder
  ): async () {
    let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    // TODO: Race condition when adding an item.
    // TODO: Ensure that it is retrieved once.
    let ?folderItemData = await catId1.getAttribute({sk = "i/" # Nat.toText(catId.1)}, "i") else {
      Debug.trap("cannot get folder item");
    };
    let folderItem = lib.deserializeItem(folderItemData);

    // if (not folderItem.item.communal) { // FIXME
    //   lib.onlyItemOwner(caller, folderItem);
    // };
    if (not lib.isFolder(folderItem) and not comment) {
      Debug.trap("not a folder");
    };
    let links = await* getStreamLinks(itemId, comment);
    await* addToStreams(catId, itemId, comment, links, itemId1, "st", "rst", #beginning);
    if (lib.isFolder(folderItem)) {
      await* addToStreams(catId, itemId, comment, links, itemId1, "sv", "rsv", side);
    } else {
      await* addToStreams(catId, itemId, comment, links, itemId1, "sv", "rsv", #end);
    };
  };

  /// `key1` and `key2` are like `"st"` and `"rst"`
  func addToStreams(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool, // FIXME: Use it.
    links: lib.StreamsLinks,
    itemId1: CanDBPartition.CanDBPartition,
    key1: Text,
    key2: Text,
    side: { #beginning; #end; #zero },
  ): async* () {
    // Put into the beginning of time order.
    let streams1 = await* itemsStream(catId, key1);
    let streams2 = await* itemsStream(itemId, key2);
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
        let v = await NacDBIndex.reorderCreateOrder(GUID.nextGuid(guidGen));
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
        let v = await NacDBIndex.reorderCreateOrder(GUID.nextGuid(guidGen));
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

  func removeItemLinks(itemId: (Principal, Nat)): async* () {
    await* _removeStream("st", itemId);
    await* _removeStream("sv", itemId);
    await* _removeStream("rst", itemId);
    await* _removeStream("rsv", itemId);
    // await* _removeStream("stc", itemId);
    // await* _removeStream("vsc", itemId);
    // await* _removeStream("rstc", itemId);
    // await* _removeStream("rsvc", itemId);
    await* removeFromAllTimeStream(itemId);
  };

  /// Removes a stream
  /// TODO: Race condition on removing first links in only one direction. Check for more race conditions.
  func _removeStream(kind: Text, itemId: (Principal, Nat)): async* () {
    let directStream = await* itemsStream(itemId, kind);
    switch (directStream) {
      case (?directStream) {
        for (index in directStream.keys()) {
          switch (directStream[index]) {
            case (?directOrder) {
              let value = Nat.toText(itemId.1) # "@" # Principal.toText(itemId.0);
              let reverseKind = if (kind.chars().next() == ?'r') {
                let iter = kind.chars();
                ignore iter.next();
                Text.fromIter(iter);
              } else {
                "r" # kind;
              };
              // Delete links pointing to us:
              // TODO: If more than 100_000?
              let result = await directOrder.order.0.scanLimitOuter({outerKey = directOrder.order.1; lowerBound = ""; upperBound = "x"; dir = #fwd; limit = 100_000});
              for (p in result.results.vals()) {
                let #text q = p.1 else {
                  Debug.trap("order: programming error");
                };
                // TODO: Extract this to a function:
                let words = Text.split(q, #char '@'); // a bit inefficient
                let w1o = words.next();
                let w2o = words.next();
                let (?w1, ?w2) = (w1o, w2o) else {
                  Debug.trap("order: programming error");
                };
                let ?w1i = Nat.fromText(w1) else {
                  Debug.trap("order: programming error");
                };
                let reverseStream = await* itemsStream((Principal.fromText(w2), w1i), reverseKind);
                switch (reverseStream) {
                  case (?reverseStream) {
                    switch (reverseStream[index]) {
                      case (?reverseOrder) {
                        await NacDBIndex.reorderDelete(GUID.nextGuid(guidGen), { order = reverseOrder; value });
                      };
                      case null {};
                    };
                  };
                  case null {};
                };
              };
              // Delete our own sub-DB (before deleting the item itself):
              await directOrder.order.0.deleteSubDBOuter({outerKey = directOrder.order.1});
            };
            case null {};
          }
        };
      };
      case null {};
    };
  };

  func getStreamLinks(/*catId: (Principal, Nat),*/ itemId: (Principal, Nat), comment: Bool)
    : async* lib.StreamsLinks
  {
    // let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));
    // TODO: Ensure that item data is readed once per `addItemToFolder` call.
    let ?childItemData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, "i") else {
      // TODO: Keep doing for other folders after a trap?
      Debug.trap("cannot get child item");
    };
    let childItem = lib.deserializeItem(childItemData);

    if (comment) {
      lib.STREAM_LINK_COMMENTS;
    } else {
      if (lib.isFolder(childItem)) {
        lib.STREAM_LINK_SUBFOLDERS;
      } else {
        lib.STREAM_LINK_SUBITEMS;
      };
    };
  };

  /// `key1` and `key2` are like `"st"` and `"rst"`
  /// TODO: No need to return an option type
  func itemsStream(itemId: (Principal, Nat), key2: Text)
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
  public shared({caller}) func vote(parentPrincipal: Principal, parent: Nat, childPrincipal: Principal, child: Nat, value: Int, comment: Bool): async () {
    await CanDBIndex.checkSybil(caller);
    assert value >= -1 and value <= 1;

    let votingPower = value;
    // TODO: Use this:
    // let votingPower = Float.toInt(Float.fromInt(value) * PCB.adjustVotingPower(user)); // TODO: `Float.toInt` is a hack.

    let userVotesSK = "v/" # Principal.toText(caller) # "/" # Nat.toText(parent) # "/" # Nat.toText(child);
    let oldVotes = await CanDBIndex.getFirstAttribute("user", { sk = userVotesSK; key = "v" }); // TODO: race condition
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
    let difference = votingPower - oldValue2;
    if (difference == 0) {
      return;
    };
    // TODO: Take advantage of `principal` as a hint.
    ignore await CanDBIndex.putAttributeNoDuplicates("user", { sk = userVotesSK; key = "v"; value = #int votingPower });

    // Update total votes for the given parent/child:
    let totalVotesSK = "w/" # Nat.toText(parent) # "/" # Nat.toText(child);
    let oldTotals = await CanDBIndex.getFirstAttribute("user", { sk = totalVotesSK; key = "v" }); // TODO: race condition
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
    let changeUp = (votingPower == 1 and oldValue2 != 1) or (oldValue2 == 1 and votingPower != 1);
    let changeDown = (votingPower == -1 and oldValue2 != -1) or (oldValue2 == -1 and votingPower != -1);
    var up2 = up;
    var down2 = down;
    if (changeUp or changeDown) {
      if (changeUp) {
        up2 += if (difference > 0) { 1 } else { -1 };
      };
      if (changeDown) {
        down2 += if (difference > 0) { -1 } else { 1 };
      };
      // Just don't show instead of removal.
      // if (up2 + down2 >= 20 and up2 * 4 <= up2 + down2) { // Remove severely voted down items.
      //   await* removeItemFromFolder((parentPrincipal, parent), (childPrincipal, child));
      // };
      // TODO: Take advantage of `oldTotalsPrincipal` as a hint:
      ignore await CanDBIndex.putAttributeNoDuplicates("user", { sk = totalVotesSK; key = "v"; value = #tuple([#int up2, #int down2]) }); // TODO: race condition
    };

    let parentCanister = actor(Principal.toText(parentPrincipal)) : CanDBPartition.CanDBPartition;
    let links = await* getStreamLinks((childPrincipal, child), comment);
    let streamsData = await* itemsStream((parentPrincipal, parent), "sv");
    let streamsVar: [var ?Reorder.Order] = switch (streamsData) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let order = switch (streamsVar[links]) {
      case (?order) { order };
      case null {
        await NacDBIndex.reorderCreateOrder(GUID.nextGuid(guidGen));
      };
    };
    if (streamsVar[links] == null) {
      streamsVar[links] := ?order;
      let data = lib.serializeStreams(Array.freeze(streamsVar));
      await parentCanister.putAttribute({ sk = "i/" # Nat.toText(parent); key = "sv"; value = data });
    };

    await NacDBIndex.reorderMove(GUID.nextGuid(guidGen), {
      order;
      value = Nat.toText(child) # "@" # Principal.toText(childPrincipal);
      relative = true;
      newKey = -difference * 2**16;
    });
  };

  /// Insert item into the beginning of the global list.
  func insertIntoAllTimeStream(itemId: (Principal, Nat)): async* () {
    let globalTimeStream = await NacDBIndex.getAllItemsStream();
    await* addItemToList(globalTimeStream, itemId, #beginning); // TODO: Implement #beginning special case.
  };

  /// Remove item from the beginning of the global list.
  func removeFromAllTimeStream(itemId: (Principal, Nat)): async* () {
    let globalTimeStream = await NacDBIndex.getAllItemsStream();
    let value = Nat.toText(itemId.1) # "@" # Principal.toText(itemId.0);
    await NacDBIndex.reorderDelete(GUID.nextGuid(guidGen), { order = globalTimeStream; value });
  };

  // TODO: Below functions?

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
  // TODO: Sorting CanDB by `Float` is wrong order.
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

  //   // TODO: Should use binary format. // TODO: Decimal serialization makes order by `random` broken.
  //   // newVotes -> child
  //   let newKey = stream.prefix1 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Float.toText(newVotes.weight) # "/" # oldVotesRandom;
  //   await oldVotesDB.put({sk = newKey; attributes = [("v", #text (Nat.toText(Nat64.toNat(tmp.child))))]});
  //   // child -> newVotes
  //   let parentChildCanister: CanDBPartition.CanDBPartition = actor(Principal.toText(parentChildCanisterId));
  //   let newKey2 = stream.prefix2 # Nat.toText(xNat.from64ToNat(tmp.parent)) # "/" # Nat.toText(xNat.from64ToNat(tmp.child));
  //   // TODO: Use NacDB:
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

  // TODO: Need to remember the votes // TODO: Remembering in CanDB makes no sense because need to check canister.
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