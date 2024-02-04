import Types "mo:passport-client-dfinity/lib/Types";
import V "mo:passport-client-dfinity/lib/Verifier";
import lib "./lib";
import Conf "../../config";

actor Personhood {
    func setVotingData(caller: Principal, partitionId: ?Principal, voting: VotingScore): async* () {
        let sk = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
        // TODO: Add Hint to CanDBMulti
        ignore await CanDBIndex.putAttributeNoDuplicates("user", {
            sk;
            key = "v";
            value = serializeVoting(voting);
        },
        );
    };

    func getVotingData(map: CM.CanisterMap, caller: Principal, partitionId: ?Principal): async* ?VotingScore {
        let part: CanDBPartition.CanDBPartition = actor(Principal.toText(partitionId));
        let sk = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
        // TODO: Add Hint to CanDBMulti
        let res = await part.getAttributeByHint(map, pk, partitionId, {sk; key = "v"});
        do ? { deserializeVoting(res!) };
    };

    /// Shared ///

    public shared({caller}) func scoreBySignedEthereumAddress({address: Text; signature: Text; nonce: Text;}): async Text {
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.scoreBySignedEthereumAddress({
            address;
            signature;
            nonce;
            scorerId = Conf.scorerId;
            transform = removeHTTPHeaders;
        });
        let score = extractItemScoreFromBody(body);
        await* setVotingData(caller, null, { // TODO: Provide partition hint, not `null`.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address;
        });
    };

    public shared func submitSignedEthereumAddressForScore({address: Text; signature: Text; nonce: Text;}): async Text {
        // A real app would store the verified address somewhere instead of just returning the score to frontend.
        // Use `extractItemScoreFromBody` or `extractItemScoreFromJSON` to extract score.
        let body = await* V.submitSignedEthereumAddressForScore({
            address;
            signature;
            nonce;
            scorerId = Conf.scorerId;
            transform = removeHTTPHeaders;
        });
        let score = extractItemScoreFromBody(body);
        await* setVotingData(caller, null, { // TODO: Provide partition hint, not `null`.
            points = score;
            lastChecked = Time.now();
            ethereumAddress = address;
        });
    };

    public shared func getEthereumSigningMessage(): async {message: Text; nonce: Text} {
        await* V.getEthereumSigningMessage({transform = removeHTTPHeaders});
    };

    public shared query func removeHTTPHeaders(args: Types.TransformArgs): async Types.HttpResponsePayload {
        V.removeHTTPHeaders(args);
    };
}