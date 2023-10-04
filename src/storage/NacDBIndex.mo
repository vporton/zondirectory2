import Cycles "mo:base/ExperimentalCycles";
import Nac "mo:nacdb/NacDB";
import StableBuffer "mo:stable-buffer/StableBuffer";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import MyCycles "mo:nacdb/Cycles";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Buffer "mo:stable-buffer/StableBuffer";
import Partition "./NacDBPartition";
import Common "common";

shared({caller = initialOwner}) actor class NacDBIndex() = this {
    stable var owners = [initialOwner];

    func checkCaller(caller: Principal) {
        if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
            Debug.trap("NacDBIndex: not allowed");
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

    public shared({caller}) func init(_owners: [Principal]) : async () {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        if (initialized) {
            Debug.trap("already initialized");
        };
        owners := _owners;
        MyCycles.addPart(Common.dbOptions.partitionCycles);
        StableBuffer.add(dbIndex.canisters, await Partition.Partition(ownersOrSelf()));
        initialized := true;
    };

    public query func getCanisters(): async [Principal] {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        let iter = Iter.map(Nac.getCanisters(dbIndex).vals(), func(x: Nac.PartitionCanister): Principal {
            Principal.fromActor(x);
        });
        Iter.toArray(iter);
    };

    public shared({caller}) func createPartition(): async Principal {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        MyCycles.addPart(Common.dbOptions.partitionCycles);
        Principal.fromActor(await Partition.Partition(ownersOrSelf()));
    };

    public shared({caller}) func createPartitionImpl(): async Principal {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await Nac.createPartitionImpl(this, dbIndex);
    };

    public shared({caller}) func createSubDB({guid: [Nat8]; userData: Text})
        : async {inner: (Principal, Nac.InnerSubDBKey); outer: (Principal, Nac.OuterSubDBKey)}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        let r = await* Nac.createSubDB({guid = Blob.fromArray(guid); index = this; dbIndex; dbOptions = Common.dbOptions; userData});
        { inner = (Principal.fromActor(r.inner.0), r.inner.1); outer = (Principal.fromActor(r.outer.0), r.outer.1) };
    };

    // Management methods //

    type CanisterId = Principal;

    type Management = actor {
        // create_canister : ({ settings : ?CanisterSettings }) -> async ({
        //   canister_id : CanisterId;
        // });
        install_code : ({
        mode : { #install; #reinstall; #upgrade };
            canister_id : CanisterId;
            wasm_module : Blob;
            arg : Blob;
        }) -> async ();
        // update_settings : ({ canister_id : CanisterId; settings : CanisterSettings }) -> async (); // TODO
        deposit_cycles : ({ canister_id : Principal }) -> async ();
    };

    public shared({caller}) func upgradeCanistersInRange(wasm: Blob, inclusiveBottom: Nat, exclusiveTop: Nat) : async ()
    {
        checkCaller(caller);

        let canisters = Nac.getCanisters(dbIndex);
        let ic : Management = actor ("aaaaa-aa");
        for (i in Iter.range(inclusiveBottom, exclusiveTop-1)) {
            await ic.install_code({
                arg = "";
                wasm_module = wasm;
                mode = #upgrade;
                canister_id = Principal.fromActor(canisters[i]);
            });
        }
    }
}