import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import RateLimit "rateLimit";
import CanDBIndex "canister:CanDBIndex";
import ic_eth "canister:ic_eth";
import Types "mo:passport-client/lib/Types";
import V "mo:passport-client/lib/Verifier";
import PassportConfig "../libs/configs/stage/passport.config";

actor Personhood {
    let updateRequests = RateLimit.newRequests();

    /// Shared ///

    // TODO: canister hint for ethereumAddress
    func controlEthereumAddress(caller: Principal, address: Text): async* () {
        let callerText = Principal.toText(caller);
        // TODO: race:
        let pa = await CanDBIndex.getFirstAttribute("user", { sk = address; subkey = "p" });
        switch (pa) {
            case (?(_p, ?#text a)) {
                if (a != callerText) {
                    Debug.trap("attempt to use other's Ethereum address");
                }
            };
            case _ {
                // TODO: Optimize performance:
                ignore await CanDBIndex.putAttributeNoDuplicates(
                    "user",
                    null, // TODO
                    { sk = address; subkey = "p"; value = #text callerText },
                );
            };
        };
    };

    // TODO: This function is unused
    public shared({caller}) func scoreBySignedEthereumAddress({address: Text; signature: Text; nonce: Text}): async Text {
        await* controlEthereumAddress(caller, address);
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.scoreBySignedEthereumAddress({
            ic_eth;
            address;
            signature;
            nonce;
            config = PassportConfig.configScorer;
            transform = removeHTTPHeaders;
        });
        let score = V.extractItemScoreFromBody(body);
        await CanDBIndex.setVotingData(caller, null, { // TODO: Provide partition hint.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address;
            config = PassportConfig.configScorer;
        });
        body;
    };

    public shared({caller}) func submitSignedEthereumAddressForScore({address: Text; signature: Text; nonce: Text}): async Text {
        await* controlEthereumAddress(caller, address);
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.submitSignedEthereumAddressForScore({
            ic_eth;
            address;
            signature;
            nonce;
            config = PassportConfig.configScorer;
            transform = removeHTTPHeaders;
        });
        let score = V.extractItemScoreFromBody(body);
        await CanDBIndex.setVotingData(caller, null, { // TODO: Provide partition hint, not `null`.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address;
            config = PassportConfig.configScorer;
        });
        body;
    };

    public shared func getEthereumSigningMessage(): async {message: Text; nonce: Text} {
        await* V.getEthereumSigningMessage({transform = removeHTTPHeaders; config = PassportConfig.configScorer});
    };

    public shared query func removeHTTPHeaders(args: Types.TransformArgs): async Types.HttpResponsePayload {
        V.removeHTTPHeaders(args);
    };

  system func inspect({
    // arg : Blob;
    caller : Principal;
    msg :
      {
        #getEthereumSigningMessage : () -> ();
        #removeHTTPHeaders : () -> Types.TransformArgs;
        #scoreBySignedEthereumAddress :
          () -> {address : Text; nonce : Text; signature : Text};
        #submitSignedEthereumAddressForScore :
          () -> {address : Text; nonce : Text; signature : Text}
      }
  }): Bool {
    switch (msg) {
        case (#removeHTTPHeaders _) { false }; // query-only
        case _ {
            RateLimit.checkRequest(updateRequests, caller);
            true;
        }
    };
  };
}