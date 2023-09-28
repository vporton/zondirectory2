import Cycles "mo:base/ExperimentalCycles";
import Nac "mo:nacdb/NacDB";
import StableBuffer "mo:stable-buffer/StableBuffer";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import MyCycles "mo:nacdb/Cycles";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:stable-buffer/StableBuffer";
import Partition "./NacDBPartition";
import Common "common";

shared actor class NacDBIndex(
    initialOwners: [Principal],
) = this {
    stable var owners = initialOwners;

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
    
    stable var dbIndex: Nac.DBIndex = Nac.createDBIndex(Common.dbOptions);

    stable var initialized = false;

    public shared({caller}) func init() : async () {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        if (initialized) {
            Debug.trap("already initialized");
        };
        MyCycles.addPart(Common.dbOptions.partitionCycles);
        StableBuffer.add(dbIndex.canisters, await Partition.Partition(ownersOrSelf()));
        initialized := true;
    };

    public query func getCanisters(): async [Nac.PartitionCanister] {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.getCanisters(dbIndex);
    };

    public shared({caller}) func createPartition(): async Nac.PartitionCanister {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        MyCycles.addPart(Common.dbOptions.partitionCycles);
        await Partition.Partition(ownersOrSelf());
    };

    public shared({caller}) func createPartitionImpl(): async Nac.PartitionCanister {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await Nac.createPartitionImpl(this, dbIndex);
    };

    public shared({caller}) func createSubDB({guid: [Nat8]; userData: Text})
        : async {inner: (Nac.InnerCanister, Nac.InnerSubDBKey); outer: (Nac.OuterCanister, Nac.OuterSubDBKey)}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.createSubDB({guid = Blob.fromArray(guid); index = this; dbIndex; dbOptions = Common.dbOptions; userData});
    };
}