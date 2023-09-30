import I "mo:base/Iter";
import BTree "mo:btree/BTree";
import Nac "mo:nacdb/NacDB";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import MyCycles "mo:nacdb/Cycles";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:stable-buffer/StableBuffer"; // TODO: Here and in other places, use just `Buffer`.
import Common "common";

shared({caller}) actor class Partition(
    initialOwners: [Principal],
) = this {
    stable var owners = initialOwners;

    func checkCaller(caller: Principal) {
        if (caller == Principal.fromActor(this)) { // FIXME: Also eliminate inter-canister calls between partitions.
            return;
        };
        if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
            Debug.trap("NacDBPartition: not allowed from " # Principal.toText(caller));
        }
    };

    public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
        checkCaller(caller);

        owners := _owners;
    };

    public query func getOwners(): async [Principal] { owners };

    // func ownersOrSelf(): [Principal] {
    //     let buf = Buffer.fromArray<Principal>(owners);
    //     Buffer.add(buf, Principal.fromActor(this));
    //     Buffer.toArray(buf);
    // };
    
    stable let index: Nac.IndexCanister = actor(Principal.toText(caller));

    stable let superDB = Nac.createSuperDB(Common.dbOptions);

    // Mandatory methods //

    public shared({caller}) func rawInsertSubDB(map: [(Nac.SK, Nac.AttributeValue)], inner: ?Nac.InnerSubDBKey, userData: Text)
        : async {inner: Nac.OuterSubDBKey}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.rawInsertSubDB(superDB, map, inner, userData);
    };

    public shared({caller}) func rawInsertSubDBAndSetOuter(
        map: [(Nac.SK, Nac.AttributeValue)],
        keys: ?{
            inner: Nac.InnerSubDBKey;
            outer: Nac.OuterSubDBKey;
        },
        userData: Text,
    )
        : async {inner: Nac.InnerSubDBKey; outer: Nac.OuterSubDBKey}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.rawInsertSubDBAndSetOuter(superDB, this, map, keys, userData);
    };

    public shared func isOverflowed({}) : async Bool {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.isOverflowed({dbOptions = Common.dbOptions; superDB});
    };

    // Some data access methods //

    public query func superDBSize() : async Nat {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.superDBSize(superDB);
    };

    public shared({caller}) func deleteSubDB({outerKey: Nac.OuterSubDBKey; guid: [Nat8]}) : async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.deleteSubDB({dbOptions = Common.dbOptions; outerSuperDB = superDB; outerKey; guid = Blob.fromArray(guid)});
    };

    public shared({caller}) func deleteSubDBInner({innerKey: Nac.InnerSubDBKey}) : async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.deleteSubDBInner({superDB; innerKey});
    };

    public shared({caller}) func finishMovingSubDBImpl({
        guid: [Nat8];
        index: Nac.IndexCanister;
        outerCanister: Nac.OuterCanister;
        outerKey: Nac.OuterSubDBKey;
        oldInnerKey: Nac.InnerSubDBKey;
    }) : async (Nac.InnerCanister, Nac.InnerSubDBKey) {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.finishMovingSubDBImpl({
            oldInnerSuperDB = superDB;
            guid = Blob.fromArray(guid);
            index;
            outerCanister;
            outerKey;
            oldInnerKey;
        })
    };

    public shared({caller}) func insert({
        guid: [Nat8];
        indexCanister: Nac.IndexCanister;
        outerCanister: Nac.OuterCanister;
        outerKey: Nac.OuterSubDBKey;
        sk: Nac.SK;
        value: Nac.AttributeValue;
    }) : async {inner: (Nac.InnerCanister, Nac.InnerSubDBKey); outer: (Nac.OuterCanister, Nac.OuterSubDBKey)} {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.insert({
            guid = Blob.fromArray(guid);
            indexCanister;
            outerCanister;
            outerSuperDB = superDB;
            outerKey;
            sk;
            value;
        });
    };

    public shared({caller}) func putLocation(outerKey: Nac.OuterSubDBKey, innerCanister: Nac.InnerCanister, newInnerSubDBKey: Nac.InnerSubDBKey) : async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.putLocation(superDB, outerKey, innerCanister, newInnerSubDBKey);
    };

    public shared({caller}) func createOuter(part: Nac.PartitionCanister, outerKey: Nac.OuterSubDBKey, innerKey: Nac.InnerSubDBKey)
        : async {inner: (Nac.InnerCanister, Nac.InnerSubDBKey); outer: (Nac.OuterCanister, Nac.OuterSubDBKey)}
    {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.createOuter(superDB, part, outerKey, innerKey);
    };

    public shared({caller}) func delete({outerKey: Nac.OuterSubDBKey; sk: Nac.SK; guid: [Nat8]}): async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.delete({outerSuperDB = superDB; outerKey; sk; guid = Blob.fromArray(guid)});
    };

    public shared({caller}) func deleteInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.deleteInner({innerSuperDB = superDB; innerKey; sk});
    };

    public query func scanLimitInner({innerKey: Nac.InnerSubDBKey; lowerBound: Nac.SK; upperBound: Nac.SK; dir: BTree.Direction; limit: Nat})
        : async BTree.ScanLimitResult<Text, Nac.AttributeValue>
    {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.scanLimitInner({innerSuperDB = superDB; innerKey; lowerBound; upperBound; dir; limit});
    };

    public shared func scanLimitOuter({outerKey: Nac.OuterSubDBKey; lowerBound: Text; upperBound: Text; dir: BTree.Direction; limit: Nat})
        : async BTree.ScanLimitResult<Text, Nac.AttributeValue>
    {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.scanLimitOuter({outerSuperDB = superDB; outerKey; lowerBound; upperBound; dir; limit});
    };

    public query func scanSubDBs(): async [(Nac.OuterSubDBKey, (Nac.InnerCanister, Nac.InnerSubDBKey))] {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.scanSubDBs({superDB});
    };

    public query func getByInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async ?Nac.AttributeValue {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.getByInner({superDB; innerKey; sk});
    };

    public query func hasByInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async Bool {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.hasByInner({superDB; innerKey; sk});
    };

    public shared func getByOuter({outerKey: Nac.OuterSubDBKey; sk: Nac.SK}): async ?Nac.AttributeValue {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.getByOuter({outerSuperDB = superDB; outerKey; sk});
    };

    public shared func hasByOuter({outerKey: Nac.OuterSubDBKey; sk: Nac.SK}): async Bool {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.hasByOuter({outerSuperDB = superDB; outerKey; sk});
    };

    public shared func hasSubDBByOuter(options: {outerKey: Nac.OuterSubDBKey}): async Bool {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.hasSubDBByOuter({outerSuperDB = superDB; outerKey = options.outerKey});
    };

    public query func hasSubDBByInner(options: {innerKey: Nac.InnerSubDBKey}): async Bool {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.hasSubDBByInner({innerSuperDB = superDB; innerKey = options.innerKey});
    };

    public shared func subDBSizeByOuter({outerKey: Nac.OuterSubDBKey}): async ?Nat {
        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.subDBSizeByOuter({outerSuperDB = superDB; outerKey});
    };

    public query func subDBSizeByInner({innerKey: Nac.InnerSubDBKey}): async ?Nat {
        // ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        Nac.subDBSizeByInner({superDB; innerKey});
    };

    public shared({caller}) func startInsertingImpl({
        guid: [Nat8];
        indexCanister: Nac.IndexCanister;
        outerCanister: Nac.OuterCanister;
        outerKey: Nac.OuterSubDBKey;
        sk: Nac.SK;
        value: Nac.AttributeValue;
        innerKey: Nac.InnerSubDBKey;
        needsMove: Bool;
    }): async () {
        checkCaller(caller);

        ignore MyCycles.topUpCycles(Common.dbOptions.partitionCycles);
        await* Nac.startInsertingImpl({
            guid = Blob.fromArray(guid);
            indexCanister;
            outerCanister;
            outerKey;
            sk;
            value;
            innerSuperDB = superDB;
            innerKey;
            needsMove;
        });
    };

    public func getSubDBUserDataOuter(options: {outerKey: Nac.OuterSubDBKey}) : async ?Text {
        await* Nac.getSubDBUserDataOuter({superDB; outerKey = options.outerKey});
    };

    public func getSubDBUserDataInner(options: {innerKey: Nac.InnerSubDBKey}) : async ?Text {
        Nac.getSubDBUserDataInner({superDB; subDBKey = options.innerKey});
    };

    // TODO: Remove superfluous functions from above.
}