import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import MyCycles "mo:nacdb/Cycles";
import DBConfig "../libs/configs/db.config";
import lib "lib";

actor Users {
  /// Initialization ///

  stable var initialized: Bool = false;

  public shared({ caller }) func init(): async () {
    ignore MyCycles.topUpCycles<system>(DBConfig.dbOptions.partitionCycles);

    if (initialized) {
      Debug.trap("already initialized");
    };

    initialized := true;
  };

  // FIXME: access control
  public shared({caller}) func setUserData(partitionId: ?Principal, user: lib.User) {
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    // TODO: Add Hint to CanDBMulti
    ignore await CanDBIndex.putAttributeNoDuplicates("user", {
        sk = key;
        key = "u";
        value = lib.serializeUser(user);
      },
    );
  };

  /// FIXME: Should also remove all his/her items.
  /// FIXME: Present this in UI for legal reasons.
  /// TODO: For it to work, need user streams (by time only?)
  public shared({caller}) func removeUser(canisterId: Principal) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };
}