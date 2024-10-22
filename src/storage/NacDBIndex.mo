import Nac "mo:nacdb/NacDB";
import Reorder "mo:nacdb-reorder/Reorder";
import GUID "mo:nacdb/GUID";
import StableBuffer "mo:stable-buffer/StableBuffer";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Buffer "mo:stable-buffer/StableBuffer";
import Cycles "mo:base/ExperimentalCycles";
import Partition "./NacDBPartition";
import Battery "canister:battery";
import DBConfig "../libs/configs/db-config";

shared({caller = initialOwner}) actor class NacDBIndex() = this {
    stable var owners = [initialOwner];

    func checkCaller(caller: Principal) {
        // TODO: It isn't really necessary to call itself.
        if (caller != Principal.fromActor(this) and Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
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
    
    stable var guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

    stable var dbIndex: Nac.DBIndex = Nac.createDBIndex(DBConfig.dbOptions);

    stable let orderer = Reorder.createOrderer({queueLengths = 20}); // TODO: What's the number?

    stable var allItemsStream: ?Reorder.Order = null;

    stable var initialized = false;

    public shared({caller}) func init(_owners: [Principal]) : async () {
        checkCaller(caller);
        if (initialized) {
            Debug.trap("already initialized");
        };

        owners := _owners;
        let part = await* _createPartition();
        StableBuffer.add(dbIndex.canisters, part);

        let SubnetManager : actor {
            raw_rand() : async Blob;
        } = actor "aaaaa-aa";
        guidGen := GUID.init(Array.subArray(Blob.toArray(await SubnetManager.raw_rand()), 0, 16));

        allItemsStream := ?(await* Reorder.createOrder(GUID.nextGuid(guidGen), {
            index = this;
            dbIndex;
            orderer;
            hardCap = ?5_000; // TODO: configurable hardCap
        }));

        initialized := true;
    };

    private func _createPartition(): async* Partition.Partition {
        Cycles.add<system>(500_000_000_000);
        let part = await Partition.Partition(ownersOrSelf());
        Battery.addNacDBPartition(Principal.fromActor(part));
        part;
    };

    // TODO: Move this function below.
    public query func getAllItemsStream(): async Reorder.Order {
        let ?v = allItemsStream else {
            Debug.trap("programming error");
        };
        v;
    };

    public query func getCanisters(): async [Principal] {
        let iter = Iter.map(Nac.getCanisters(dbIndex).vals(), func(x: Nac.PartitionCanister): Principal {
            Principal.fromActor(x);
        });
        Iter.toArray(iter);
    };

    public shared({caller}) func createPartition(): async Principal {
        checkCaller(caller);
        Principal.fromActor(await* _createPartition());
    };

    public shared({caller}) func createPartitionImpl(): async Principal {
        checkCaller(caller);

        await* Nac.createPartitionImpl(this, dbIndex);
    };

    public shared({caller}) func createSubDB(guid: [Nat8], {userData: Text; hardCap : ?Nat})
        : async {inner: {canister: Principal; key: Nac.InnerSubDBKey}; outer: {canister: Principal; key: Nac.OuterSubDBKey}}
    {
        checkCaller(caller);

        let r = await* Nac.createSubDB(Blob.fromArray(guid), {
            index = this;
            dbIndex;
            hardCap;
            userData;
        });
        {
            inner = {canister = Principal.fromActor(r.inner.canister); key = r.inner.key};
            outer = {canister = Principal.fromActor(r.outer.canister); key = r.outer.key};
        };
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
                arg = to_candid([]);
                wasm_module = wasm;
                mode = #upgrade;
                canister_id = Principal.fromActor(canisters[i]);
            });
        }
    };

    public shared({caller}) func deleteSubDB(guid: [Nat8], {outerCanister: Principal; outerKey: Nac.OuterSubDBKey}) : async () {
        checkCaller(caller);

        let outer: Nac.OuterCanister = actor (Principal.toText(outerCanister));
        await* Nac.deleteSubDB(Blob.fromArray(guid), {dbOptions = DBConfig.dbOptions; dbIndex; outerCanister = outer; outerKey});
    };

    public shared({caller}) func delete(guid: [Nat8], {outerCanister: Principal; outerKey: Nac.OuterSubDBKey; sk: Nac.SK}): async () {
        checkCaller(caller);

        let outer: Nac.OuterCanister = actor (Principal.toText(outerCanister));
        await* Nac.delete(Blob.fromArray(guid), {dbIndex; outerCanister = outer; outerKey; sk});
    };

    public shared({caller}) func insert(guid: [Nat8], {
        outerCanister: Principal;
        outerKey: Nac.OuterSubDBKey;
        sk: Nac.SK;
        value: Nac.AttributeValue;
        hardCap: ?Nat;
    }) : async Result.Result<{inner: {canister: Principal; key: Nac.InnerSubDBKey}; outer: {canister: Principal; key: Nac.OuterSubDBKey}}, Text> {
        checkCaller(caller);

        let result = await* Nac.insert(Blob.fromArray(guid), {
            indexCanister = Principal.fromActor(this);
            outerCanister = outerCanister;
            dbIndex;
            outerKey;
            sk;
            value;
            hardCap;
        });
        switch (result) {
            case (#ok { inner; outer }) {
                let innerx: Principal = Principal.fromActor(inner.canister);
                let outerx: Principal = Principal.fromActor(outer.canister);
                #ok { inner = { canister = innerx; key = inner.key}; outer = { canister = outerx; key = outer.key} };
            };
            case (#err err) {
                #err err;
            }
        };
    };

    /// reorder methods ///

    public shared({caller}) func reorderCreateOrder(guid: [Nat8]): async Reorder.Order {
        checkCaller(caller);

        await* Reorder.createOrder(Blob.fromArray(guid), {
            index = this;
            dbIndex;
            orderer;
            hardCap = DBConfig.dbOptions.hardCap;
        });
    };

    public shared({caller}) func reorderAdd(guid: [Nat8], options: {
        order: Reorder.Order;
        key: Int;
        value: Text;
    }): async () {
        checkCaller(caller);

        await* Reorder.add(Blob.fromArray(guid), {
            index = this;
            dbIndex;
            orderer;
            order = options.order;
            key = options.key;
            value = options.value;
            hardCap = DBConfig.dbOptions.hardCap;
        });
    };

    public shared({caller}) func reorderMove(guid: [Nat8], options: {
        order: Reorder.Order;
        value: Text;
        relative: Bool;
        newKey: Int;
    }): async Bool {
        checkCaller(caller);

        await* Reorder.move(Blob.fromArray(guid), {
            index = this;
            dbIndex;
            orderer;
            order = options.order;
            value = options.value;
            relative = options.relative;
            newKey = options.newKey;
       });
    };

    public shared({caller}) func reorderDelete(guid: [Nat8], options: {
        order: Reorder.Order;
        value: Text;
    }): async () {
        checkCaller(caller);

        await* Reorder.delete(Blob.fromArray(guid), {
            index = this;
            dbIndex;
            orderer;
            order = options.order;
            value = options.value;
       });
    };
}