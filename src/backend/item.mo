import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";

import Itertools "mo:itertools/Iter";
import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import Reorder "mo:nacdb-reorder/Reorder";
import MyCycles "mo:nacdb/Cycles";
import lib "lib";
import DBConfig "../libs/configs/db.config";

shared({caller = initialOwner}) actor class Orders() = this {
  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("item: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  stable var initialized: Bool = false;

  public shared({ caller }) func init(_owners: [Principal]): async () { // FIXME: Initialize in Makefile.
    checkCaller(caller);
    ignore MyCycles.topUpCycles<system>(DBConfig.dbOptions.partitionCycles); // TODO: another number of cycles?
    if (initialized) {
        Debug.trap("already initialized");
    };

    owners := _owners;
    MyCycles.addPart<system>(DBConfig.dbOptions.partitionCycles);

    initialized := true;
  };


}