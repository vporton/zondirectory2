import Common "../storage/common";
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
import Payments "payments";

// TODO: Delete "hanging" items (as soon, as they found)

shared actor class Orders() = this {
  var initialized: Bool = false;

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
    itemId: Nat;
    var fwd: ?(CanDBPartition.CanDBPartition, GUID);
    var bwd: ?(CanDBPartition.CanDBPartition, GUID);
  };

  func iter(list: DList): { next: shared() -> async ?Nat} {
    var current = do ? { list.ptrs!.start };
    {
      next = shared func(): async ?Nat {
        let ?cur = current else {
          return null;
        };
        let item = await cur.0.get({sk = encodeGuid(cur.1)});
        current := cur.fwd;
        do ? { item!.value };
      };
    };
  };

  // FIXME
  func prepend<T>(list: DList, value: T) {
    let newItem = {
      value;
      fwd = do ? { list!.start };
      bwd = nil;
    };
    if (list.ptrs == nil) {
      
    };
  }
}