import Array "mo:base/Array";
import CA "mo:candb/CanisterActions";
import Entity "mo:candb/Entity";
import CanDB "mo:candb/CanDB";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import PeekableIter "mo:itertools/PeekableIter";
import Error "mo:base/Error";

shared actor class DBPartition({
  // the primary key of this canister
  primaryKey: Text;
  // the scaling options that determine when to auto-scale out this canister storage partition
  scalingOptions: CanDB.ScalingOptions;
  // (optional) allows the developer to specify additional owners (i.e. for allowing admin or backfill access to specific endpoints)
  initialOwners: [Principal];
}) {
  stable var owners = initialOwners;

  /// @required (may wrap, but must be present in some form in the canister)
  stable let db = CanDB.init({
    pk = primaryKey;
    scalingOptions = scalingOptions;
    btreeOrder = null;
  });

  func checkCaller(caller: Principal): async Bool {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) != null) {
      true;
    } else {
      throw Error.reject("not allowed");
      false;
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) != null) {
      owners := _owners;
    };
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
  public shared({caller = caller}) func put(options: CanDB.PutOptions) {
    if (await checkCaller(caller)) {
      await* CanDB.put(db, options);
    };
  };

  public shared({caller = caller}) func replace(options: CanDB.ReplaceOptions): async ?Entity.Entity {
    if (await checkCaller(caller)) {
      await* CanDB.replace(db, options);
    } else {
      null;
    };
  };

  // public shared({caller = caller}) func update(options: CanDB.UpdateOptions): async ?Entity.Entity {
  //   if (checkCaller(caller)) {
  //     CanDB.update(db, options);
  //   } else {
  //     null;
  //   };
  // };

  public shared({caller = caller}) func delete(options: CanDB.DeleteOptions) {
    if (await checkCaller(caller)) {
      CanDB.delete(db, options);
    };
  };

  public shared({caller = caller}) func remove(options: CanDB.RemoveOptions): async ?Entity.Entity {
    if (await checkCaller(caller)) {
      CanDB.remove(db, options);
    } else {
      null;
    };
  };

  public query func scan(options: CanDB.ScanOptions): async CanDB.ScanResult {
    CanDB.scan(db, options);
  };

  /// @required public API (Do not delete or change)
  public shared({ caller = caller }) func transferCycles(): async () {
    if (await checkCaller(caller)) {
      return await CA.transferCycles(caller);
    };
  };
}