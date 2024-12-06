import BTree "mo:stableheapbtreemap/BTree";
import Nac "mo:nacdb/NacDB";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import DBConfig "../libs/configs/db-config";

shared({caller}) actor class Partition(
    initialOwners: [Principal],
) = this {
    stable var owners = initialOwners;

    func checkCaller(caller: Principal) {
        if (caller == Principal.fromActor(this)) {
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
    
    stable let _index: Nac.IndexCanister = actor(Principal.toText(caller));

    stable let superDB = Nac.createSuperDB(DBConfig.dbOptions);

    // Mandatory methods //

    public shared({caller}) func rawInsertSubDB({
        hardCap : ?Nat;
        innerKey : ?Nac.InnerSubDBKey;
        map : [(Nac.SK, Nac.AttributeValue)];
        userData : Text
    })
        : async {innerKey: Nac.InnerSubDBKey}
    {
        checkCaller(caller);

        Nac.rawInsertSubDB({superDB; map; innerKey; userData; hardCap});
    };

    public shared({caller}) func rawInsertSubDBAndSetOuter({
        map: [(Nac.SK, Nac.AttributeValue)];
        keys: ?{
            innerKey: Nac.InnerSubDBKey;
            outerKey: Nac.OuterSubDBKey;
        };
        userData: Text;
        hardCap: ?Nat;
    })
        : async {innerKey: Nac.InnerSubDBKey; outerKey: Nac.OuterSubDBKey}
    {
        checkCaller(caller);

        Nac.rawInsertSubDBAndSetOuter({superDB; canister = this; map; keys; userData; hardCap});
    };

    public query func isOverflowed() : async Bool {
        Nac.isOverflowed({dbOptions = DBConfig.dbOptions; superDB});
    };

    // Some data access methods //

    public query func superDBSize() : async Nat {
        Nac.superDBSize(superDB);
    };

    public shared({caller}) func deleteSubDBInner({innerKey: Nac.InnerSubDBKey}) : async () {
        checkCaller(caller);

        await* Nac.deleteSubDBInner({superDB; innerKey});
    };

    public shared func putLocation({outerKey: Nac.OuterSubDBKey; innerCanister: Principal; innerKey: Nac.InnerSubDBKey}) : async () {
        checkCaller(caller);

        let inner2: Nac.InnerCanister = actor(Principal.toText(innerCanister));
        Nac.putLocation({outerSuperDB = superDB; outerKey; innerCanister = inner2; innerKey});
    };

    public shared func createOuter({part: Principal; outerKey: Nac.OuterSubDBKey; innerKey: Nac.InnerSubDBKey})
        : async {inner: {canister: Principal; key: Nac.InnerSubDBKey}; outer: {canister: Principal; key: Nac.OuterSubDBKey}}
    {
        checkCaller(caller);

        let part2: Nac.PartitionCanister = actor(Principal.toText(part));
        let { inner; outer } = Nac.createOuter({outerSuperDB = superDB; part = part2; outerKey; innerKey});
        {
            inner = {canister = Principal.fromActor(inner.canister); key = inner.key};
            outer = {canister = Principal.fromActor(outer.canister); key = outer.key};
        };
    };

    public shared({caller}) func deleteInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async () {
        checkCaller(caller);

        await* Nac.deleteInner({innerSuperDB = superDB; innerKey; sk});
    };

    public query func scanLimitInner({innerKey: Nac.InnerSubDBKey; lowerBound: Nac.SK; upperBound: Nac.SK; dir: BTree.Direction; limit: Nat})
        : async BTree.ScanLimitResult<Text, Nac.AttributeValue>
    {
        Nac.scanLimitInner({innerSuperDB = superDB; innerKey; lowerBound; upperBound; dir; limit});
    };

    public shared func scanLimitOuter({outerKey: Nac.OuterSubDBKey; lowerBound: Nac.SK; upperBound: Nac.SK; dir: BTree.Direction; limit: Nat})
        : async BTree.ScanLimitResult<Text, Nac.AttributeValue>
    {
        let ?{canister = part; key = innerKey} = Nac.getInner({outerKey; superDB}) else {
            Debug.trap("no sub-DB");
        };
        let part2: Partition = actor(Principal.toText(Principal.fromActor(part)));
        await part2.scanLimitInner({innerKey; lowerBound; upperBound; dir; limit});
    };

    public composite query func scanLimitOuterComposite({outerKey: Nac.OuterSubDBKey; lowerBound: Nac.SK; upperBound: Nac.SK; dir: BTree.Direction; limit: Nat})
        : async BTree.ScanLimitResult<Text, Nac.AttributeValue>
    {
        let ?{canister = part; key = innerKey} = Nac.getInner({outerKey; superDB}) else {
            Debug.trap("no sub-DB");
        };
        let part2: Partition = actor(Principal.toText(Principal.fromActor(part)));
        await part2.scanLimitInner({innerKey; lowerBound; upperBound; dir; limit});
    };

    public query func scanSubDBs(): async [(Nac.OuterSubDBKey, {canister: Principal; key: Nac.InnerSubDBKey})] {
        type T1 = (Nac.OuterSubDBKey, Nac.InnerPair);
        type T2 = (Nac.OuterSubDBKey, {canister: Principal; key: Nac.InnerSubDBKey});
        let array: [T1] = Nac.scanSubDBs({superDB});
        let iter = Iter.map(array.vals(), func ((outerKey, {canister = inner; key = innerKey}): T1): T2 {
            (outerKey, {canister = Principal.fromActor(inner); key = innerKey});
        });
        Iter.toArray(iter);
    };

    public query func getByInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async ?Nac.AttributeValue {
        Nac.getByInner({superDB; innerKey; sk});
    };

    public query func hasByInner({innerKey: Nac.InnerSubDBKey; sk: Nac.SK}): async Bool {
        Nac.hasByInner({superDB; innerKey; sk});
    };

    public shared func getByOuter({outerKey: Nac.OuterSubDBKey; sk: Nac.SK}): async ?Nac.AttributeValue {
        await* Nac.getByOuter({outerSuperDB = superDB; outerKey; sk});
    };

    public shared func hasByOuter({outerKey: Nac.OuterSubDBKey; sk: Nac.SK}): async Bool {
        await* Nac.hasByOuter({outerSuperDB = superDB; outerKey; sk});
    };

    public shared func hasSubDBByOuter(options: {outerKey: Nac.OuterSubDBKey}): async Bool {
        await* Nac.hasSubDBByOuter({outerSuperDB = superDB; outerKey = options.outerKey});
    };

    public query func hasSubDBByInner(options: {innerKey: Nac.InnerSubDBKey}): async Bool {
        Nac.hasSubDBByInner({innerSuperDB = superDB; innerKey = options.innerKey});
    };

    public shared func subDBSizeByOuter({outerKey: Nac.OuterSubDBKey}): async ?Nat {
        await* Nac.subDBSizeByOuter({outerSuperDB = superDB; outerKey});
    };

    public query func subDBSizeByInner({innerKey: Nac.InnerSubDBKey}): async ?Nat {
        Nac.subDBSizeByInner({superDB; innerKey});
    };

    public shared func startInsertingImpl({
        innerKey: Nac.InnerSubDBKey;
        sk: Nac.SK;
        value: Nac.AttributeValue;
    }): async () {
        checkCaller(caller);

        await* Nac.startInsertingImpl({
            innerKey;
            sk;
            value;
            innerSuperDB = superDB;
        });
    };

    // TODO: These...
    public shared func getSubDBUserDataOuter(options: {outerKey: Nac.OuterSubDBKey}) : async ?Text {
        await* Nac.getSubDBUserDataOuter({outerSuperDB = superDB; outerKey = options.outerKey});
    };

    // TODO: .., two functions should have similar arguments
    public func getSubDBUserDataInner(options: {innerKey: Nac.InnerSubDBKey}) : async ?Text {
        Nac.getSubDBUserDataInner({superDB; subDBKey = options.innerKey});
    };

    // TODO: Add this function to the public interface in NacDB?
    public query func getInner(options: {outerKey: Nac.OuterSubDBKey}) : async ?{canister: Principal; key: Nac.InnerSubDBKey} {
        do ? {
            let {canister; key} = Nac.getInner({superDB; outerKey = options.outerKey})!;
            {canister = Principal.fromActor(canister); key};
        };
    };

    public shared({caller}) func deleteSubDBOuter({outerKey: Nac.OuterSubDBKey}) : async () {
        checkCaller(caller);
        await* Nac.deleteSubDBOuter({superDB; outerKey});
    };

    public shared func rawDeleteSubDB({innerKey: Nac.InnerSubDBKey}): async () {
        checkCaller(caller);

        Nac.rawDeleteSubDB(superDB, innerKey);
    };

    public query func rawGetSubDB({innerKey: Nac.InnerSubDBKey}): async ?{map: [(Nac.SK, Nac.AttributeValue)]; userData: Text} {
        Nac.rawGetSubDB(superDB, innerKey);
    };

    public shared func subDBSizeOuterImpl(options: {outerKey: Nac.OuterSubDBKey}): async ?Nat {
        await* Nac.subDBSizeOuterImpl({outerSuperDB = superDB; outerKey = options.outerKey}, DBConfig.dbOptions);
    };

    // TODO: Remove superfluous functions from above.
}