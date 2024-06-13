import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import lib "lib";

shared({caller = initialOwner}) actor class Users() = this {
  /// Initialization ///

  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("users: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  stable var initialized: Bool = false;

  public shared({ caller }) func init(): async () {
    checkCaller(caller);

    if (initialized) {
      Debug.trap("already initialized");
    };

    initialized := true;
  };

  public shared({caller}) func setUserData(partitionId: ?Principal, user: lib.User) {
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    // TODO: Add Hint to CanDBMulti
    ignore await CanDBIndex.putAttributeNoDuplicates("user", partitionId, {
        sk = key;
        subkey = "u";
        value = lib.serializeUser(user);
      },
    );
  };

  /// FIXME: Should also remove all his/her items.
  /// FIXME: Present this in UI for legal reasons.
  /// TODO: For it to work, need user streams
  ///       (by time only, because it's undetermined whether user stream is owned or communal).
  public shared({caller}) func removeUser(canisterId: Principal) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };
}