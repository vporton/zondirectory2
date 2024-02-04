import CanDBIndex "canister:CanDBIndex";
import Types "mo:passport-client-dfinity/lib/Types";
import V "mo:passport-client-dfinity/lib/Verifier";
import Time "mo:base/Time";
import lib "./lib";
import Conf "../../config";

actor Personhood {
    /// Shared ///

    public shared({caller}) func scoreBySignedEthereumAddress({address: Text; signature: Text; nonce: Text}): async () {
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.scoreBySignedEthereumAddress({
            address;
            signature;
            nonce;
            config = Conf.configScorer;
            transform = removeHTTPHeaders;
        });
        let score = V.extractItemScoreFromBody(body);
        await CanDBIndex.setVotingData(?caller, { // TODO: Provide partition hint.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address; // FIXME: Store separately.
            config = Conf.configScorer;
        });
    };

    public shared({caller}) func submitSignedEthereumAddressForScore({address: Text; signature: Text; nonce: Text}): async () {
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.submitSignedEthereumAddressForScore({
            address;
            signature;
            nonce;
            config = Conf.configScorer;
            transform = removeHTTPHeaders;
        });
        let score = V.extractItemScoreFromBody(body);
        await CanDBIndex.setVotingData(?caller, { // TODO: Provide partition hint, not `null`.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address; // FIXME: Store separately.
            config = Conf.configScorer;
        });
    };

    public shared func getEthereumSigningMessage(): async {message: Text; nonce: Text} {
        await* V.getEthereumSigningMessage({transform = removeHTTPHeaders; config = Conf.configScorer});
    };

    public shared query func removeHTTPHeaders(args: Types.TransformArgs): async Types.HttpResponsePayload {
        V.removeHTTPHeaders(args);
    };
}