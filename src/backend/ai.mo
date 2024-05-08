import Cycles "mo:base/ExperimentalCycles";
import JSON "mo:json.mo";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import Nat16 "mo:base/Nat16";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Itertools "mo:itertools/Iter";
import Types "HttpTypes";
import Config "../libs/configs/ai.config";
import lib "lib";

module {
    // TODO: The below code is too specialized. Possibly, generalize it.

    let promptBase = "Classify the following message as spam or hate speech (answer \"yes\") or not spam (answer \"no\"). Answer only \"yes\" or \"no\" and nothing else. The message follows:\n\n";

    private func encodeNat16(n: Nat): Text {
        var n16 = Nat16.fromNat(n);
        let buf = Buffer.Buffer<Nat8>(2);
        for (i in Iter.range(0, 1)) {
            buf.add(Nat8.fromNat(Nat16.toNat(n16 % 256)));
            n16 >>= 8;
        };
        let blob = Blob.fromArray(Array.reverse(Buffer.toArray(buf)));
        lib.encodeBlob(blob);
    };

    // TODO: Cache the return value.
    private func fullPrompt(textToCheck: Text): Text {
        let prompt = promptBase # textToCheck;
        let prompt2Parts = Iter.map(prompt.chars(), func (c: Char): Text {
            if (c == '\"') {
                "\\\"";
            } else if (c == '\\') {
                "\\\\";
            } else if (c < ' ') {
                "\\u" # encodeNat16(Nat32.toNat(Char.toNat32(c)));
            } else {
                Text.fromChar(c);
            };
        });
        let prompt2 = Itertools.reduce(prompt2Parts, func (a: Text, b: Text): Text { a # b });
        let ?prompt3 = prompt2 else {
            Debug.trap("programming error");
        };
        JSON.show(#Object([
            ("model", #String("gpt-3.5-turbo")),
            ("max_tokens", #Number(1)), // answer: yes or no
            ("temperature", #Number(0)),
            ("messages", #Array([
                #Object([("role", #String("system")), ("content", #String("You are an automated email filter."))]),
                #Object([("role", #String("user")), ("content", #String(prompt3))]),
            ])),
        ]));
    };

    // The management canister (used internally).
    let ic : Types.IC = actor ("aaaaa-aa");

    /// Obtain a response from Gitcoin Passport API and check that it's OK.
    private func obtainSuccessfulResponse(request: Types.HttpRequestArgs): async* Text {
        Cycles.add<system>(40_000_000); // FIXME
        let response: Types.HttpResponsePayload = await ic.http_request(request);
        let ?body = Text.decodeUtf8(Blob.fromArray(response.body)) else {
            Debug.trap("AI response is not UTF-8");
        };
        if (response.status != 200) {
            Debug.print("AI HTTP response code " # Nat.toText(response.status));
            Debug.print("BODY: " # body);
            Debug.trap("AI HTTP response code " # Nat.toText(response.status));
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
        let bodyText = fullPrompt(textToCheck);
        let body = Blob.toArray(Text.encodeUtf8(bodyText));
        let request : Types.HttpRequestArgs = {
            body = ?body;
            headers = [
                {name = "Content-Type"; value = "application/json"},
                {name = "Authorization"; value = "Bearer " # Config.openaiApiKey},
                {name = "X-JoinProxy-Key"; value = "Bearer " # Config.proxySecurityKey},
            ];
            max_response_bytes = ?10000;
            method = #post;
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

    /// `choices[0].message.content`
    private func obtainAICompletion(
        textToCheck: Text,
        transform: shared query Types.TransformArgs -> async Types.HttpResponsePayload,
    ): async* Text {
        let json = await* requestAI(textToCheck, transform);
        let choices = getJSONSubObject(json, "choices");
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

    /// Result `false` means spam.
    /// FIXME: Limit the length of the text.
    public func checkSpam(
        textToCheck: Text,
        transform: shared query Types.TransformArgs -> async Types.HttpResponsePayload,
    ): async* Bool {
        let res = await* obtainAICompletion(textToCheck, transform);
        Text.toLowercase(Text.fromIter(Itertools.take(res.chars(), 3))) != "yes";
    };
}