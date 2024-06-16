import Http "mo:join-proxy-motoko";
import Types "mo:join-proxy-motoko/HttpTypes";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";

shared({caller = initialOwner}) actor class HttpCaller() = this {
    stable var owners = [initialOwner];

    func checkCaller(caller: Principal) {
        if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
            Debug.trap("item: not allowed");
        }
    };

    public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
        checkCaller(caller);

        owners := _owners;
    };

    public query func getOwners(): async [Principal] { owners };

    stable var initialized: Bool = false;

    public shared({ caller }) func init(_owners: [Principal]): async () { // FIXME: Initialize in Makefile.
        checkCaller(caller);
        if (initialized) {
            Debug.trap("already initialized");
        };

        owners := _owners;
        requestsCheckerValue := ?(Http.newHttpRequestsChecker());

        initialized := true;
    };

    stable var requestsCheckerValue: ?Http.HttpRequestsChecker = null;

    private func requestsChecker(): Http.HttpRequestsChecker {
        let ?v = requestsCheckerValue else {
            Debug.trap("module 'call' not initialized")
        };
        v;
    };

    public shared func callHttp(
        request: Http.WrappedHttpRequest,
        params: {timeout: Nat; max_response_bytes: ?Nat64; cycles: Nat}
    ): async Types.HttpResponsePayload {
        Cycles.add<system>(params.cycles);
        await* Http.checkedHttpRequestWrapped(requestsChecker(), request, ?{ function = transform; context = "" }, params);
    };

    /// This function is needed even, if you use `inspect`, because
    /// `inspect` is basically a query call and query calls can be forged by a malicious replica.
    public shared func checkRequest(hash: Blob): async () {
        if (not Http.checkHttpRequest(requestsChecker(), hash)) {
            Debug.trap("hacked or timed out HTTP request");
        }
    };

    public query func transform(args: Types.TransformArgs): async Types.HttpResponsePayload {
        {
            status = args.response.status;
            headers = [];
            body = args.response.body;
        };
    };

    system func inspect({
        // caller : Principal;
        // arg : Blob;
        msg : {
            #callHttp :
            () ->
                (Http.WrappedHttpRequest,
                {cycles : Nat; max_response_bytes : ?Nat64; timeout : Nat});
            #checkRequest : () -> Blob;
            #getOwners : () -> ();
            #init : () -> [Principal];
            #setOwners : () -> [Principal];
            #transform : () -> Types.TransformArgs
        }
    }) : Bool {
        switch (msg) {
            case (#checkRequest hash) {
                Http.checkHttpRequest(requestsChecker(), hash());
            };
            case _ {
                // Should here check permissions:
                true;
            }
        };
    };
}