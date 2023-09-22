import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import TrieSet "mo:base/TrieSet";
import CA "mo:candb/CanisterActions";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stable-buffer/StableBuffer";
import CanDBPartition "CanDBPartition";
import CanDBPartition2 "../storage/CanDBPartition";
import Admin "mo:candb/CanDBAdmin";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Array "mo:base/Array";
import Int "mo:base/Int";
import CanDB "mo:candb/CanDB";
import Entity "mo:candb/Entity";
import Canister "mo:matchers/Canister";

actor class CanDBIndex() = this {
  stable var owners: [Principal] = [];

  stable var initialized: Bool = false;

  public shared func init(initialOwners: [Principal]): async () {
    if (initialized) {
      Debug.trap("already initialized");
    };

    owners := initialOwners;
    ignore await* createStorageCanister("main", ownersOrSelf());
    ignore await* createStorageCanister("sybil", ownersOrSelf()); // user data

    initialized := true;
  };

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  func ownersOrSelf(): [Principal] {
    let buf = Buffer.fromArray<Principal>(owners);
    Buffer.add(buf, Principal.fromActor(this));
    Buffer.toArray(buf);
  };

  let maxSize = #heapSize(500_000_000);

  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for an specific PK
  ///
  /// This method is called often by the candb-client query & update methods. 
  public shared query({caller}) func getCanistersByPK(pk: Text): async [Text] {
    getCanisterIdsIfExists(pk);
  };
  
  /// @required function (Do not delete or change)
  ///
  /// Helper method acting as an interface for returning an empty array if no canisters
  /// exist for the given PK
  func getCanisterIdsIfExists(pk: Text): [Text] {
    switch(CanisterMap.get(pkToCanisterMap, pk)) {
      case null { [] };
      case (?canisterIdsBuffer) { Buffer.toArray(canisterIdsBuffer) } 
    }
  };

  /// This hook is called by CanDB for AutoScaling the User Service Actor.
  ///
  /// If the developer does not spin up an additional User canister in the same partition within this method, auto-scaling will NOT work
  /// Upgrade user canisters in a PK range, i.e. rolling upgrades (limit is fixed at upgrading the canisters of 5 PKs per call)
  public shared({caller}) func upgradeUserCanistersInPKRange(wasmModule: Blob): async Admin.UpgradePKRangeResult {
    checkCaller(caller);

    await Admin.upgradeCanistersInPKRange({
      canisterMap = pkToCanisterMap;
      lowerPK = "";
      upperPK = "\u{FFFF}";
      limit = 5;
      wasmModule = wasmModule;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = maxSize;
      };
      owners = ?ownersOrSelf();
    });
  };

  public shared({caller}) func autoScaleCanister(pk: Text): async Text {
    checkCaller(caller);

    if (Utils.callingCanisterOwnsPK(caller, pkToCanisterMap, pk)) {
      await* createStorageCanister(pk, ownersOrSelf());
    } else {
      Debug.trap("error, called by non-controller=" # debug_show(caller));
    };
  };

  func createStorageCanister(pk: Text, controllers: [Principal]): async* Text {
    Debug.print("creating new storage canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new storage canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000); // TODO: Choose the number.
    let newStorageCanister = await CanDBPartition.CanDBPartition({
      primaryKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = maxSize;
      };
      initialOwners = controllers;
    });
    let newStorageCanisterPrincipal = Principal.fromActor(newStorageCanister);
    await CA.updateCanisterSettings({
      canisterId = newStorageCanisterPrincipal;
      settings = {
        controllers = ?controllers;
        compute_allocation = ?0;
        memory_allocation = ?0;
        freezing_threshold = ?2592000;
      }
    });

    let newStorageCanisterId = Principal.toText(newStorageCanisterPrincipal);
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newStorageCanisterId);

    Debug.print("new storage canisterId=" # newStorageCanisterId);
    newStorageCanisterId;
  };

  // Put to a canister. It may create duplicates.
  public shared({caller}) func putNew(pk: Entity.PK, options: CanDB.PutOptions): async () {
    checkCaller(caller);

    let canisterIds = getCanisterIdsIfExists(pk);
    let part0 = if (canisterIds == []) {
      await* createStorageCanister(pk, ownersOrSelf());
    } else {
      canisterIds[canisterIds.size() - 1];
    };
    let part: CanDBPartition2.CanDBPartition = actor(part0);
    await part.put(options);
  };

  // FIXME: race conditions?
  public shared({caller}) func putNewNoDuplicates(pk: Entity.PK, options: CanDB.PutOptions): async () {
    checkCaller(caller);

    // Do parallel search in existing canisters:
    let canisterIds = getCanisterIdsIfExists(pk);
    let threads : [var ?(async())] = Array.init(canisterIds.size(), null);
    var foundInCanister: ?Nat = null;
    for (threadNum in threads.keys()) {
      threads[threadNum] := ?(async {
        let canister: CanDBPartition.CanDBPartition = actor(canisterIds[threadNum]);
        switch (foundInCanister) {
          case (?foundInCanister) {
            if (foundInCanister < threadNum) {
              return; // eliminate unnecessary work.
            };
          };
          case null {};
        };
        if (await canister.skExists(options.sk)) {
          foundInCanister := ?threadNum;
        };
      });
    };
    for (topt in threads.vals()) {
      let ?t = topt else {
        Debug.trap("programming error: threads");
      };
      await t;
    };

    let partition = switch (foundInCanister) {
      case (?foundInCanister) {
        actor(canisterIds[foundInCanister]): CanDBPartition.CanDBPartition;
      };
      case null {
        let newStorageCanisterId = await* createStorageCanister(pk, ownersOrSelf());
        actor(newStorageCanisterId): CanDBPartition.CanDBPartition;
      };
    };
    await partition.put({sk = options.sk; attributes = options.attributes});
  };
}