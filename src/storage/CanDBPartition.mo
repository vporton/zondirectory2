import Array "mo:base/Array";
import CA "mo:candb/CanisterActions";
import Entity "mo:candb/Entity";
import CanDB "mo:candb/CanDB";
import RBT "mo:stable-rbtree/StableRBTree";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import lib "../backend/lib";

shared actor class CanDBPartition({
  primaryKey: Text;
  scalingOptions: CanDB.ScalingOptions;
  initialOwners: [Principal];
}) {
  stable var owners = initialOwners;

  /// @required (may wrap, but must be present in some form in the canister)
  stable let db = CanDB.init({
    pk = primaryKey;
    scalingOptions = scalingOptions;
    btreeOrder = null;
  });

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("not allowed");
    }
  };

  public shared({caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  /// @recommended (not required) public API
  public query func getPK(): async Text { db.pk };

  /// @required public API (Do not delete or change)
  public query func skExists(sk: Text): async Bool { 
    CanDB.skExists(db, sk);
  };

  public query func get(options: CanDB.GetOptions): async ?Entity.Entity { 
    CanDB.get(db, options);
  };

  public shared({caller}) func put(options: CanDB.PutOptions): async () {
    checkCaller(caller);

    await* CanDB.put(db, options);
  };

  // public shared({caller}) func replace(options: CanDB.ReplaceOptions): async ?Entity.Entity {
  //   checkCaller(caller);

  //   await* CanDB.replace(db, options);
  // };

  // public shared({caller = caller}) func update(options: CanDB.UpdateOptions): async ?Entity.Entity {
  //   if (checkCaller(caller)) {
  //     CanDB.update(db, options);
  //   } else {
  //     null;
  //   };
  // };

  public shared({caller}) func delete(options: CanDB.DeleteOptions): async () {
    checkCaller(caller);

    CanDB.delete(db, options);
  };

  // public shared({caller}) func remove(options: CanDB.RemoveOptions): async ?Entity.Entity {
  //   checkCaller(caller);

  //   CanDB.remove(db, options);
  // };

  public query func scan(options: CanDB.ScanOptions): async CanDB.ScanResult {
    CanDB.scan(db, options);
  };

  /// @required public API (Do not delete or change)
  public shared({caller}) func transferCycles(): async () {
    checkCaller(caller);

    return await CA.transferCycles(caller);
  };

  // public shared({caller}) func tryPut(options: CanDB.PutOptions): async () {
  //   checkCaller(caller);

  //   if (not CanDB.skExists(db, options.sk)) {
  //     await* CanDB.put(db, options);
  //   };
  // };

  func _getAttribute(options: CanDB.GetOptions, subkey: Text): ?Entity.AttributeValue {
    let all = CanDB.get(db, options);
    Debug.print("all=" # debug_show(all)); // FIXME: Remove.
    do ? { RBT.get(all!.attributes, Text.compare, subkey)! };
  };

  public query func getAttribute(options: CanDB.GetOptions, subkey: Text): async ?Entity.AttributeValue {
    // checkCaller(caller);
    _getAttribute(options, subkey);
  };

  // public shared({caller}) func transform(
  //   sk: Entity.SK,
  //   modifier: shared(value: ?Entity.AttributeMap) -> async [(Entity.AttributeKey, Entity.AttributeValue)]): async ()
  // {
  //   checkCaller(caller);

  //   let all = do ? { CanDB.get(db, {sk})!.attributes };
  //   await* CanDB.put(db, {sk; attributes = await modifier(all)})
  // };

  public shared({caller}) func putAttribute(
    sk: Entity.SK,
    subkey: Entity.AttributeKey,
    value: Entity.AttributeValue,
  ): async () {
    checkCaller(caller);

    // TODO: duplicate code
    let all = do ? { CanDB.get(db, {sk})!.attributes };
    let new = switch (all) {
      case (?all) {
        let filtered = Iter.filter<(Entity.AttributeKey, Entity.AttributeValue)>(
          RBT.entries<Entity.AttributeKey, Entity.AttributeValue>(all),
          func((k,v): (Entity.AttributeKey, Entity.AttributeValue)) { k != subkey });
        let filteredArray = Iter.toArray(filtered);
        let newAll = Buffer.fromArray<(Entity.AttributeKey, Entity.AttributeValue)>(filteredArray);
        let old = RBT.get(all, Text.compare, subkey);
        newAll.add((subkey, value));
        Buffer.toArray(newAll);
      };
      case null {
        [(subkey, value)];
      };
    };
    await* CanDB.put(db, {sk; attributes = new})
  };

  public shared({caller}) func transformAttribute(
    sk: Entity.SK,
    subkey: Entity.AttributeKey,
    modifier: shared(value: ?Entity.AttributeValue) -> async Entity.AttributeValue
  ): async () {
    checkCaller(caller);

    // TODO: duplicate code
    let all = do ? { CanDB.get(db, {sk})!.attributes };
    let new = switch (all) {
      case (?all) {
        let filtered = Iter.filter<(Entity.AttributeKey, Entity.AttributeValue)>(
          RBT.entries<Entity.AttributeKey, Entity.AttributeValue>(all),
          func((k,v): (Entity.AttributeKey, Entity.AttributeValue)) { k != subkey });
        let filteredArray = Iter.toArray(filtered);
        let newAll = Buffer.fromArray<(Entity.AttributeKey, Entity.AttributeValue)>(filteredArray);
        let old = RBT.get(all, Text.compare, subkey);
        let modified = await modifier(old);
        newAll.add((subkey, modified));
        Buffer.toArray(newAll);
      };
      case null {
        let modified = await modifier(null);
        [(subkey, modified)];
      };
    };
    await* CanDB.put(db, {sk; attributes = new})
  };

  // Application-specific code //

  public query func getItem(itemId: Nat): async ?lib.Item {
    let data = _getAttribute({sk = "i/" # Nat.toText(itemId)}, "i");
    Debug.print("data=" # debug_show(data)); // FIXME: Remove.
    do ? { lib.deserializeItem(data!) };
  };

  public query func getStreams(itemId: Nat): async ?lib.Streams {
    let data = _getAttribute({sk = "i/" # Nat.toText(itemId)}, "s");
    do ? { lib.deserializeStreams(data!) };
  };
}