import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Bool "mo:base/Bool";

import Itertools "mo:itertools/Iter";
import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import NacDBIndex "canister:NacDBIndex";
import Reorder "mo:nacdb-reorder/Reorder";
import MyCycles "mo:nacdb/Cycles";
import DBConfig "../libs/configs/db.config";

// TODO: Delete "hanging" items (as soon, as they found)

shared({caller = initialOwner}) actor class Orders() = this {
  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("order: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  stable var initialized: Bool = false;

  // stable var rng: Prng.Seiran128 = Prng.Seiran128(); // WARNING: This is not a cryptographically secure pseudorandom number generator.
  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  stable let orderer = Reorder.createOrderer({queueLengths = 20});

  public shared({ caller }) func init(_owners: [Principal]): async () {
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