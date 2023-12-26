import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import Common "../storage/common";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import NacDBPartition "../storage/NacDBPartition";
import Entity "mo:candb/Entity";
import Reorder "mo:reorder/Reorder";
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
import Bool "mo:base/Bool";
import Time "mo:base/Time";
import Payments "payments";
import RBT "mo:stable-rbtree/StableRBTree";
import StableBuffer "mo:StableBuffer/StableBuffer";
import Itertools "mo:itertools/Iter";
import MyCycles "mo:nacdb/Cycles";
import BTree "mo:stableheapbtreemap/BTree";
import lib "lib";

// TODO: Delete "hanging" items (as soon, as they found)

shared({caller = initialOwner}) actor class Activity() = this {
  stable var owners = [initialOwner];

  type UserActivity = {
    time: Time.Time;
    votesCast: Nat;
  };

  stable var activities = BTree.init<Principal, UserActivity>(null);
  stable var activityTimes = BTree.init<Time.Time, Principal>(null);

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("activity: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  var initialized: Bool = false;

  // TODO: Remove this function?
  public shared({ caller }) func init(_owners: [Principal]): async () {
    checkCaller(caller);
    ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles); // TODO: another number of cycles?
    if (initialized) {
        Debug.trap("already initialized");
    };

    owners := _owners;
    MyCycles.addPart(Common.dbOptions.partitionCycles);
    initialized := true;
  };

  shared({caller}) func castVote() {
    // TODO
  };
}