import Common "../storage/common";
import Entity "mo:candb/Entity";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

// TODO: Delete "hanging" items (as soon, as they found)

shared actor class Orders() = this {
  var initialized: Bool = false;

  public shared({ caller }) func init(): async () {
    if (initialized) {
      Debug.trap("already initialized");
    };

    ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);

    initialized := true;
  };

  // FIXME: Move lists code to CanDBIndex

  // A double linked list:
  type DList = {
    ptrs: ?{
      var start: (CanDBPartition.CanDBPartition, Nat);
      var end: (CanDBPartition.CanDBPartition, Nat);
    };
  };

  type DListNode<T> = {
    value: T;
    var fwd: ?(CanDBPartition.CanDBPartition, Nat);
    var bwd: ?(CanDBPartition.CanDBPartition, Nat);
  };

  func iter<T>(list: DList): Iter.Iter<T> {
    var current = do ? { list!.start };
    {
      next = func(): ?T {
        let ?cur = current else {
          return null;
        };
        let item = cur.0.get("p/" # Nat.toText(cur.1));
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