import Cycles "mo:base/ExperimentalCycles";
import JSON "mo:json.mo";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Itertools "mo:itertools/Iter";
import Types "HttpTypes";
import Config "../libs/configs/ai.config";

module {
    // TODO: The below code is too specialized. Possibly, generalize it.

    let prompt = "Classify the following message as spam or hate speech (answer \"yes\") or not spam (answer \"no\"). Answer only \"yes\" or \"no\" and nothing else. The message follows:\n\n";

    // TODO: Cache the return value.
    private func fullPrompt(): Text {
        JSON.show(#Object([
            ("model", #String("gpt-3.5-turbo")),
            ("max_tokens", #Number(1)), // answer: yes or no
            ("temperature", #Number(0)),
            ("messages", #Array([
                #Object([("role", #String("system")), ("content", #String("You are an automated email filter."))]),
                #Object([("role", #String("user")), ("content", #String(prompt))]),
            ])),
        ]));
    };

    // The management canister (used internally).
    let ic : Types.IC = actor ("aaaaa-aa");

    /// Obtain a response from Gitcoin Passport API and check that it's OK.
    private func obtainSuccessfulResponse(request: Types.HttpRequestArgs): async* Text {
        Cycles.add<system>(40_000_000); // FIXME
        let response: Types.HttpResponsePayload = await ic.http_request(request);
        if (response.status != 200) {
            Debug.trap("AI HTTP response code " # Nat.toText(response.status))
        };
        let ?body = Text.decodeUtf8(Blob.fromArray(response.body)) else {
            Debug.trap("AI response is not UTF-8");
        };
        body;
    };

    /// Obtain a response from Gitcoin Passport API and convert it to JSON.
    private func obtainSuccessfulJSONResponse(request: Types.HttpRequestArgs): async* JSON.JSON {
        let body = await* obtainSuccessfulResponse(request);
        let ?json = JSON.parse(body) else {
            Debug.trap("AI response is not JSON");
        };
        json;
    };

    /// To be passed as `transform` argument of other functions in this module.
    public func removeHTTPHeaders(args: Types.TransformArgs): Types.HttpResponsePayload {
        {
            status = args.response.status;
            headers = [];
            body = args.response.body;
        };
    };

    private func requestAI<system>(
        textToCheck: Text,
        transform: shared query Types.TransformArgs -> async Types.HttpResponsePayload,
    ): async* JSON.JSON {
        let body = Blob.toArray(Text.encodeUtf8(fullPrompt() # textToCheck));
        let request : Types.HttpRequestArgs = {
            body = ?body;
            headers = [
                {name = "Authorization"; value = "Bearer " # Config.openaiApiKey},
                {name = "X-My-Security"; value = Config.cloudfrontSecurityKey},
            ];
            max_response_bytes = ?10000;
            method = #get;
            url = Config.openaiApiUrl # "v1/chat/completions";
            transform = ?{
                function = transform;
                context = ""; // Blob.fromArray([]);
            };
        };
        await* obtainSuccessfulJSONResponse(request);
    };

    private func getJSONSubObject(json: JSON.JSON, name: Text): JSON.JSON {
        let #Object(pairs) = json else {
            Debug.trap("Not JSON object type.");
        };
        for (pair in pairs.vals()) {
            if (pair.0 == name) {
                return pair.1;
            };
        };
        Debug.trap("No JSON subobject: " # name);
    };

    /// `completion.choices[0].message.content`
    private func obtainAICompletion(
        textToCheck: Text,
        transform: shared query Types.TransformArgs -> async Types.HttpResponsePayload,
    ): async* Text {
        let json = await* requestAI(textToCheck, transform);
        let completion = getJSONSubObject(json, "completion");
        let choices = getJSONSubObject(completion, "choices");
        let #Array(choicesArr) = choices else {
            Debug.trap("Not JSON array.");
        };
        let choice = choicesArr[0];
        let message = getJSONSubObject(choice, "message");
        let content = getJSONSubObject(message, "content");
        let #String(contentText) = content else {
            Debug.trap("JSON: not text.");
        };
        contentText;
    };

    /// Result `true` means spam.
    public func checkSpam(
        textToCheck: Text,
        transform: shared query Types.TransformArgs -> async Types.HttpResponsePayload,
    ): async* Bool {
        let res = await* obtainAICompletion(textToCheck, transform);
        Text.toLowercase(Text.fromIter(Itertools.take(res.chars(), 3))) == "yes";
    };
}