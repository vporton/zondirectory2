import Http "mo:join-proxy-motoko";
import JSON "mo:json.mo/JSON";
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
import RBTree "mo:base/RBTree";
import Nat64 "mo:base/Nat64";
import Bool "mo:base/Bool";
import Option "mo:base/Option";
import Itertools "mo:itertools/Iter";
import Types "HttpTypes";
import CanDBPartition "../storage/CanDBPartition";
import Call "canister:call";
import Config "../libs/configs/stage/ai.config";
import lib "lib";

module {
    // TODO: The below code is too specialized. Possibly, generalize it.

    let promptBase = "Classify the following message as spam, hate speech, illegal content, or threats (answer \"yes\") or none of these (answer \"no\"). Answer only \"yes\" or \"no\" and nothing else. The message follows:\n\n";

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

    private func jsonEncodeString(s: Text): Text {
        // TODO: Rename variables in this function.
        let prompt2Parts = Iter.map(s.chars(), func (c: Char): Text {
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
        prompt3;
    };

    // TODO: Cache the return value.
    private func fullPrompt(textToCheck: Text): Text {
        let prompt = jsonEncodeString(promptBase # textToCheck);
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

    func obtainSuccessfulResponse(
        url: Text,
        headers: RBTree.RBTree<Text, [Text]>,
        abody: Text,
        params: {timeout: Nat; max_response_bytes: ?Nat64; cycles: Nat}
    ) : async* Text {
        let res = await Call.callHttp(
            {
                url;
                headers = headers.share();
                body = Text.encodeUtf8(abody);
                method = #post;
            },
            params,
        );
        let ?body = Text.decodeUtf8(res.body) else {
            Debug.trap("non UTF-8 response");
        };
        if (res.status != 200) {
            Debug.trap("invalid response from proxy: " # body);
        };
        body;
    };

    /// Obtain a response from Gitcoin Passport API and convert it to JSON.
    private func obtainSuccessfulJSONResponse(
        url: Text,
        headers: RBTree.RBTree<Text, [Text]>,
        abody: Text,
        params: {timeout: Nat; max_response_bytes: ?Nat64; cycles: Nat}
    ): async* JSON.JSON {
        let body = await* obtainSuccessfulResponse(url, headers, abody, params);
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

    private func aiCompletion<system>(
        textToCheck: Text,
    ): async* JSON.JSON {
        let bodyText = fullPrompt(textToCheck);
        let headers = Http.headersNew();
        for (h in Config.openaiRequestHeaders.vals()) {
            headers.put(h.name, [h.value]);
        };
        await* obtainSuccessfulJSONResponse(
            Config.openaiUrlBase # "v1/chat/completions",
            headers,
            bodyText,
            {
                timeout = 60_000_000_000; // 1 min
                max_response_bytes = ?(1564 + Nat64.fromNat(Text.size(bodyText)));
                cycles = 90_000_000;
            },
        );
    };

    public func retrieveAndStoreInVectorDB(itemId: Text, text: Text): async* () {
        let embedding = await* retrieveEmbedding(text);
        await* storeInVectorDB(itemId, embedding);
    };

    private func retrieveEmbedding<system>(
        text: Text,
    ): async* [Float] {
        let headers = Http.headersNew();
        for (h in Config.openaiRequestHeaders.vals()) {
            headers.put(h.name, [h.value]);
        };
        let body = JSON.show(#Object([
            ("input", #String(jsonEncodeString(Text.fromIter(Itertools.take(text.chars(), 750))))),
            ("model", #String("text-embedding-3-small")),
            ("dimensions", #Number(256)),
        ]));
        let jsonRes = await* obtainSuccessfulJSONResponse(
            Config.openaiUrlBase # "v1/embeddings",
            headers,
            body,
            {
                timeout = 60_000_000_000; // 1 min
                max_response_bytes = ?7750;
                cycles = 150_000_000;
            },
        );
        let dataObj = getJSONSubObject(jsonRes, "data");
        let #Array data1 = dataObj else {
            Debug.trap("not a JSON array");
        };
        let embedding = getJSONSubObject(data1[0], "embedding");
        let #Array(embeddingArray) = embedding else {
            Debug.trap("embedding: not JSON array type");
        };
        Iter.toArray(Iter.map(embeddingArray.vals(), func (x: JSON.JSON): Float {
            let #Float(x2) = x else {
                Debug.trap("embedding: not JSON float type");
            };
            x2;
        }));
    };

    private func storeInVectorDB(
        itemId: Text,
        embedding: [Float],
    ): async* () {
        let headers = Http.headersNew();
        for (h in Config.pineconeRequestHeaders.vals()) {
            headers.put(h.name, [h.value]);
        };
        let values = Iter.toArray(Iter.map(embedding.vals(), func (x: Float): JSON.JSON { #Float(x) }));
        let body = JSON.show(#Object([
            ("vectors",
                #Array([ // one element
                    #Object([
                        ("id", #String(itemId)),
                        ("values", #Array(values)),
                    ])
                ])
            ),
        ]));
        let jsonRes = await* obtainSuccessfulJSONResponse(
            Config.pineconeUrlBase # "vectors/upsert",
            headers,
            body,
            {
                timeout = 60_000_000_000; // 1 min
                max_response_bytes = ?7750; // TODO
                cycles = 150_000_000; // TODO
            },
        );        
    };

    /// Return the list of IDs (in current version of one ID) along with their similarity scores.
    private func queryVectorDBForSimilar(vector: [Float]): async* ?[(Text, Float)] {
        let headers = Http.headersNew();
        for (h in Config.pineconeRequestHeaders.vals()) {
            headers.put(h.name, [h.value]);
        };
        let values = Iter.toArray(Iter.map(vector.vals(), func (x: Float): JSON.JSON { #Float(x) }));
        let body = JSON.show(#Object([
            ("vector", #Array(values)),
            ("topK", #Number 1),
        ]));
        let jsonRes = await* obtainSuccessfulJSONResponse(
            Config.pineconeUrlBase # "query",
            headers,
            body,
            {
                timeout = 60_000_000_000; // 1 min
                max_response_bytes = ?7750; // TODO
                cycles = 150_000_000; // TODO
            },
        );
        let matches = getJSONSubObject(jsonRes, "matches");
        let #Array(mathesArr) = matches else {
            Debug.trap("wrong Pinecone search results");
        };
        if (Array.size(mathesArr) == 0) {
            return null;
        };
        let elt = mathesArr[0];
        let #String id = getJSONSubObject(elt, "id") else {
            Debug.trap("wrong vector ID");
        };
        let #Float score = getJSONSubObject(elt, "score") else {
            Debug.trap("score");
        };
        Debug.print("SCORE: " # debug_show(score));
        ?[(id, score)];
    };

    public func smartlyRejectSimilar(text: Text): async* () {
        let ourEmbedding = await* retrieveEmbedding(text);
        let ?similar = await* queryVectorDBForSimilar(ourEmbedding) else {
            return; // OK, because nothing similar
        };
        let (closestId, closestScore) = similar[0];
        if (closestScore < 0.89) {
            return; // OK, because nothing similar
        };
        Debug.trap("too similar to existing message");
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
    private func autoModerator(
        textToCheck: Text,
    ): async* Text {
        let json = await* aiCompletion(textToCheck);
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
    public func checkSpam(
        textToCheck: Text,
    ): async* Bool {
        let res = await* autoModerator(textToCheck);
        Text.toLowercase(Text.fromIter(Itertools.take(res.chars(), 3))) != "yes";
    };
}