import Common "../storage/common";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
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

// TODO: Delete "hanging" items (as soon, as they found)

shared actor class Orders() = this {
  var initialized: Bool = false;

  // var rng: Prng.Seiran128 = Prng.Seiran128();
  let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  // TODO: Remove this function?
  public shared({ caller }) func init(): async () {
    if (initialized) {
      Debug.trap("already initialized");
    };

    // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    initialized := true;
  };

  type GUID = Blob;

  func _toLowerHexDigit(v: Nat): Char {
    Char.fromNat32(Nat32.fromNat(
      if (v < 10) {
        Nat32.toNat(Char.toNat32('0')) + v;
      } else {
        Nat32.toNat(Char.toNat32('a')) + v - 10;
      }
    ));
  };

  func _fromLowerHexDigit(c: Char): Nat {
    Nat32.toNat(
      if (c <= '9') {
        Char.toNat32(c) - Char.toNat32('0');
      } else {
        Char.toNat32(c) - Char.toNat32('a') + 10;
      }
    );
  };

  // TODO: Should use Blob instead and remove these two functions.
  func encodeGuid(g: GUID): Text {
    var result = ""; // TODO: Optimize, if possible, using a Buffer of pre-calculated size.
    for (b in g.vals()) {
      let b2 = Nat8.toNat(b);
      result #= Text.fromChar(_toLowerHexDigit(b2 / 16)) # Text.fromChar(_toLowerHexDigit(b2 % 16));
    };
    result;
  };

  func decodeGuid(t: Text): GUID {
    let buf = Buffer.Buffer<Nat8>(t.size() / 2);
    let c = t.chars();
    label r loop {
      let ?upper = c.next() else {
        Debug.trap("programming error");
      };
      let ?lower = c.next() else {
        break r;
      };
      let b = Nat8.fromNat(_fromLowerHexDigit(upper) * 16 + _fromLowerHexDigit(lower));
      buf.add(b);
    };
    Blob.fromArray(Buffer.toArray(buf));
  };

  // A double linked list:
  type DList = {
    ptrs: ?{
      var start: (CanDBPartition.CanDBPartition, GUID);
      var end: (CanDBPartition.CanDBPartition, GUID);
    };
  };

  type ItemDListNode = {
    var fwd: ?(CanDBPartition.CanDBPartition, GUID);
    var bwd: ?(CanDBPartition.CanDBPartition, GUID);
    itemId: Nat;
    // TODO: Also store number of votes, where appropriate.
  };

  func _serializePointer(ptr: ?(CanDBPartition.CanDBPartition, GUID)): [Entity.AttributeValuePrimitive] {
    switch (ptr) {
      case (?(part, guid)) {
        [
          #int 2,
          #text(Principal.toText(Principal.fromActor(part))),
          #text(encodeGuid(guid)), // TODO: space-inefficient
        ];
      };
      case (null) { [#int 0] };
    }
  };

  // The argument is a slice of an array, starting from the size of the fragment of the array to use.
  func _deserializePointer(e: [Entity.AttributeValuePrimitive])
    : (?(CanDBPartition.CanDBPartition, GUID), [Entity.AttributeValuePrimitive])
  {
    switch (e.size()) {
      case (0) { (null, Array.subArray(e, 1, Int.abs(e.size()-1))) };
      case (2) {
        let (#text(part), #text(guid)) = (e[1], e[2]) else {
          Debug.trap("wrong linked list pointer format");
        };
        (?(actor(part), decodeGuid(guid)), Array.subArray(e, 3, Int.abs(e.size()-3)));
      };
      case _ {
        Debug.trap("wrong linked list pointer format");
      }
    }
  };

  func serializeItemNode(node: ItemDListNode): [Entity.AttributeValuePrimitive] {
    let result = Buffer.Buffer<Entity.AttributeValuePrimitive>(7);
    result.append(Buffer.fromArray(_serializePointer(node.fwd)));
    result.append(Buffer.fromArray(_serializePointer(node.bwd)));
    result.add(#int(node.itemId));
    Buffer.toArray(result);
  };

  // Returns deserialization of item and remaining data.
  func deserializeItemNode(e: [Entity.AttributeValuePrimitive]): (ItemDListNode, [Entity.AttributeValuePrimitive]) {
    let (fwd, e1) = _deserializePointer(e);
    let (bwd, e2) = _deserializePointer(e1);
    let #int itemId = e2[0] else {
      Debug.trap("wrong linked list pointer format");
    };
    (
      {var fwd; var bwd; itemId = Int.abs(itemId)},
      Array.subArray(e2, 1, Int.abs(e2.size()-1)),
    );
  };

  func iter(list: DList): { next: shared() -> async ?[Entity.AttributeValuePrimitive] } {
    var current = do ? { list.ptrs!.start };
    {
      next = shared func(): async ?[Entity.AttributeValuePrimitive] {
        let ?cur = current else {
          return null;
        };
        let v = await cur.0.get({sk = encodeGuid(cur.1)});
        switch (v) {
          case (?v) {
            let ?(#tuple t) = RBT.get(v.attributes, Text.compare, "x") else {
              Debug.trap("wrong linked list pointer format");
            };
            ?t;
          };
          case (null) { null }
        };
      };
    };
  };

  func prepend(list: DList, value: ({itemId: Nat}, [Entity.AttributeValuePrimitive])) {
    let wasEmpty = switch (list.ptrs) {
      case (?ptrs) { false };
      case null { true };
    };
    let newItem = {
      fwd = do ? { ptrs!.start };
      bwd = null;
      itemId = value.0.itemId;
    };
    let value2 = Buffer.fromArray(serializeItemNode(newItem));
    value2.append(value.1);
    let start = rng.next();
    CanDBIndex.put({sk = start; attributes = [("x", value2)]});
    ptrs.start := start;
    if (wasEmpty) {
      ptrs.end := start;
    };
  };

  func append(list: DList, value: ({itemId: Nat}, [Entity.AttributeValuePrimitive])) {
    let wasEmpty = switch (list.ptrs) {
      case (?ptrs) { false };
      case null { true };
    };
    let newItem = {
      fwd = null;
      bwd = do ? { ptrs!.start };
      itemId = value.0.itemId;
    };
    let value2 = Buffer.fromArray(serializeItemNode(newItem));
    value2.append(value.1);
    let end = rng.next();
    CanDBIndex.put({sk = end; attributes = [("x", value2)]});
    ptrs.end := end;
    if (wasEmpty) {
      ptrs.start := end;
    };
  };
}