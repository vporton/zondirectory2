import Cycles "mo:base/ExperimentalCycles";
import Nac "mo:nacdb/NacDB";
import StableBuffer "mo:stable-buffer/StableBuffer";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import MyCycles "mo:nacdb/Cycles";
import Array "mo:base/Array";
import Buffer "mo:stable-buffer/StableBuffer";
import Partition "./NacDBPartition";

shared actor class NacDBIndex(
    initialOwners: [Principal],
    dbOptions: Nac.DBOptions,
) = this {
    // TODO: Rename.
    public shared({caller}) func constructor(dbOptions: Nac.DBOptions): async Partition.Partition {
        checkCaller(caller);

        await Partition.Partition(ownersOrSelf(), dbOptions);
    };

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
    
    stable var dbIndex: Nac.DBIndex = Nac.createDBIndex(dbOptions);

    stable var initialized = false;

    public shared({caller}) func init() : async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(dbOptions.partitionCycles);
        if (initialized) {
            Debug.trap("already initialized");
        };
        MyCycles.addPart(dbOptions.partitionCycles);
        StableBuffer.add(dbIndex.canisters, await Partition.Partition(ownersOrSelf(), dbOptions));
        initialized := true;
    };

    public query func getCanisters(): async [Nac.PartitionCanister] {
        // ignore MyCycles.topUpCycles(dbOptions.partitionCycles);
        Nac.getCanisters(dbIndex);
    };

    public shared({caller}) func createPartition(dbOptions: Nac.DBOptions): async Nac.PartitionCanister {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(dbOptions.partitionCycles);
        MyCycles.addPart(dbOptions.partitionCycles);
        await Partition.Partition(ownersOrSelf(), dbOptions);
    };

    public shared({caller}) func createPartitionImpl(): async Nac.PartitionCanister {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(dbOptions.partitionCycles);
        await Nac.createPartitionImpl(this, dbIndex);
    };

    public shared({caller}) func createSubDB({guid: Nac.GUID; userData: Text})
        : async {inner: (Nac.InnerCanister, Nac.InnerSubDBKey); outer: (Nac.OuterCanister, Nac.OuterSubDBKey)}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(dbOptions.partitionCycles);
        await* Nac.createSubDB({guid; index = this; dbIndex; dbOptions; userData});
    };
}