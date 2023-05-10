import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Text "mo:base/Text";
import TrieSet "mo:base/TrieSet";
import CA "mo:candb/CanisterActions";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stable-buffer/StableBuffer";
import DBPartition "DBPartition";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import PeekableIter "mo:itertools/PeekableIter";
import Array "mo:base/Array";

shared actor class IndexCanister(
    initialOwners: [Principal]
) = this {
  stable var owners = initialOwners;

  func checkCaller(caller: Principal): Bool {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) != null) {
      true;
    } else {
      Debug.trap("not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) != null) {
      owners := _owners;
    };
  };

  public query func getOwners(): async [Principal] { owners };

  /// @required stable variable (Do not delete or change)
  ///
  /// Holds the CanisterMap of PK -> CanisterIdList
  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for an specific PK
  ///
  /// This method is called often by the candb-client query & update methods. 
  public shared query({caller = caller}) func getCanistersByPK(pk: Text): async [Text] {
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

  public shared({caller = caller}) func autoScaleCanister(pk: Text): async Text {
    if (Utils.callingCanisterOwnsPK(caller, pkToCanisterMap, pk)) {
      await createStorageCanister(pk, owners);
    } else {
      Debug.trap("error, called by non-controller=" # debug_show(caller));
    };
  };

  public shared({caller = caller}) func createDBPartition(pk: Text): async ?DBPartition.DBPartition {
    switch (await createDBPartitionImpl(pk)) {
      case (?canisterId) { ?actor(canisterId) };
      case (null) { null };
    }
  };

  public shared({caller = caller}) func createDBPartitionImpl(pk: Text): async ?Text {
    if (checkCaller(caller)) {
      let canisterIds = getCanisterIdsIfExists(pk);
      if (canisterIds == []) {
        ?(await createStorageCanister(pk, owners)); // FIXME
      // the partition already exists, so don't create a new canister
      } else {
        Debug.print(pk # " already exists");
        null 
      };
    } else {
      Debug.trap("caller not allowed to create partition");
    }
  };

  func createStorageCanister(pk: Text, controllers: [Principal]): async Text {
    Debug.print("creating new storage canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new storage canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000); // TODO: Choose the number.
    let newStorageCanister = await DBPartition.DBPartition({
      primaryKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = #heapSize(900_000_000); // Scale out at 900MB
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
    // After creating the new Hello Service canister, add it to the pkToCanisterMap
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newStorageCanisterId);

    Debug.print("new storage canisterId=" # newStorageCanisterId);
    newStorageCanisterId;
  };
}