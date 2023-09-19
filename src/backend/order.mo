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

  // var rng: Prng.Seiran128 = Prng.Seiran128();
  // let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

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
      case (#category cat) {
        switch (cat.catKind) {
          case (#communal) {};
          case (#owned) {
            lib.onlyItemOwner(caller, categoryItem);
          };
        };
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
  }
}