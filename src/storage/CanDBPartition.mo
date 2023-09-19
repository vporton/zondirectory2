import Array "mo:base/Array";
import CA "mo:candb/CanisterActions";
import Entity "mo:candb/Entity";
import CanDB "mo:candb/CanDB";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";

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

  // FIXME: Why here and below `await` with `*`? Is it correct?
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
}