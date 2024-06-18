import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import CyclesSimple "mo:cycles-simple";

shared({caller = initialOwner}) actor class Battery() = this {
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

    stable var initialized = false;

    public shared({caller}) func init(_owners: [Principal]) : async () {
        checkCaller(caller);
        if (initialized) {
            Debug.trap("already initialized");
        };

        owners := _owners;

        CyclesSimple.insertCanisterKind(battery, "can", {
            threshold = 3_000_000_000_000;
            installAmount = 1_000_000_000_000;
        });
        CyclesSimple.insertCanisterKind(battery, "nac", {
            threshold = 3_000_000_000_000;
            installAmount = 1_000_000_000_000;
        });
        initTimer<system>();

        initialized := true;
    };

    system func postupgrade() {
        initTimer<system>();
    };

    func initTimer<system>() {
        timer := ?(Timer.recurringTimer<system>(#seconds 3600, topUpAllCanisters));
    };

    stable let battery = CyclesSimple.newBattery();

    stable var timer: ?Timer.TimerId = null;

    public shared func addCanDBPartition(principal: Principal) {
        CyclesSimple.addCanister(battery, principal, "can");
    };

    public shared func addNacDBPartition(principal: Principal) {
        CyclesSimple.addCanister(battery, principal, "nac");
    };

    private func topUpAllCanisters(): async () {
        await* CyclesSimple.topUpAllCanisters(battery);
    };

    system func inspect({
        caller : Principal;
    }): Bool {
        checkCaller(caller);
        true;
    }
}