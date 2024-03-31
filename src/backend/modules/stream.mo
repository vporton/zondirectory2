import Entity "mo:candb/Entity";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import NacDBIndex "canister:NacDBIndex";
import Reorder "mo:nacdb-reorder/Reorder";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../../storage/CanDBPartition";

import { deserializeItem; addItemToList } = "item";
import Modifers "../libs/helpers/modifiers.helper"

module {
 // TODO: Does it make sense to keep `Streams` in lib?
  public type StreamsLinks = Nat;
  public let STREAM_LINK_SUBITEMS: StreamsLinks = 0; // folder <-> sub-items
  public let STREAM_LINK_SUBFOLDERS: StreamsLinks = 1; // folder <-> sub-folders
  public let STREAM_LINK_COMMENTS: StreamsLinks = 2; // item <-> comments
  public let STREAM_LINK_MAX: StreamsLinks = STREAM_LINK_COMMENTS;

  public type Streams = [?Reorder.Order];
  stable var initialized: Bool = false;

  // stable var rng: Prng.Seiran128 = Prng.Seiran128(); // WARNING: This is not a cryptographically secure pseudorandom number generator.
  stable let guidGen = GUID.init(Array.tabulate<Nat8>(16, func _ = 0));

  stable let orderer = Reorder.createOrderer({queueLengths = 20});
   let guid = GUID.nextGuid(guidGen);

    // TODO: race condition
    await* Reorder.add(guid, NacDBIndex, orderer, {
      order = theSubDB;
      key = timeScanSK;
      value = scanItemInfo;
      hardCap = DBConfig.dbOptions.hardCap;
    });


  
  public query func getStreams(itemId: Nat, kind: Text): async ?Streams {
    // TODO: Duplicate code
    if (kind != "st" and kind != "rst" and kind != "sv" and kind != "rsv") {
      Debug.trap("wrong streams");
    };
    let data = CanDBPartition.getAttribute({sk = "i/" # Nat.toText(itemId)}, kind);
    do ? { deserializeStreams(data!) };
  };

  public func serializeStreams(streams: Streams): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(18);
    for(item in streams.vals()) {
      switch (item) {
        case (?r) {
          buf.add(#text(Principal.toText(Principal.fromActor(r.order.0))));
          buf.add(#int(r.order.1));
          buf.add(#text(Principal.toText(Principal.fromActor(r.reverse.0))));
          buf.add(#int(r.reverse.1));
        };
        case null {
          buf.add(#int(-1));
        }
      }
    };
    #tuple(Buffer.toArray(buf));
  };

 
  public func deserializeStreams(attr: Entity.AttributeValue): Streams {
    let s = Buffer.Buffer<?Reorder.Order>(36);
    let #tuple arr = attr else {
      Debug.trap("programming error");
    };
    var i = 0;
    label w while (i != Array.size(arr)) {
      if (arr[i] == #int(-1)) {
        s.add(null);
        i += 1;
        continue w;
      };
      switch (arr[i], arr[i+1], arr[i+2], arr[i+3]) {
        case (#text c0, #int i0, #text c1, #int i1) {
          i += 4;
          s.add(
            ?{ order = (actor(c0), Int.abs(i0)); reverse = (actor(c1), Int.abs(i1)) },
          );
        };
        case _ {
          Debug.trap("programming error");
        }
      };
    };

    Buffer.toArray(s);
  };

  /// `key1` and `key2` are like `"st"` and `"rst"`
  public func addToStreams(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool, // FIXME: Use it.
    links: StreamsLinks,
    itemId1: CanDBPartition.CanDBPartition,
    key1: Text,
    key2: Text,
    side: { #beginning; #end; #zero },
  ): async* () {
    // Put into the beginning of time order.
    let streams1 = await* itemsStream(catId, key1);
    let streams2 = await* itemsStream(itemId, key2);
    let streamsVar1: [var ?Reorder.Order] = switch (streams1) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let streamsVar2: [var ?Reorder.Order] = switch (streams2) {
      case (?streams) { Array.thaw(streams) };
      case null { [var null, null, null]};
    };
    let streams1t = switch (streams1) {
      case (?t) { t[links] };
      case (null) { null };
    };
    let stream1 = switch (streams1t) {
      case (?stream) { stream };
      case null {
        let v = await* Reorder.createOrder(GUID.nextGuid(guidGen), NacDBIndex, orderer, ?10000);
        streamsVar1[links] := ?v;
        v;
      };
    };
    let streams2t = switch (streams2) {
      case (?t) { t[links] };
      case (null) { null };
    };
    let stream2 = switch (streams2t) {
      case (?stream) { stream };
      case null {
        let v = await* Reorder.createOrder(GUID.nextGuid(guidGen), NacDBIndex, orderer, ?10000);
        streamsVar2[links] := ?v;
        v;
      };
    };
    await* addItemToList(stream1, itemId, side);
    await* addItemToList(stream2, catId, side);
    let itemData1 = serializeStreams(Array.freeze(streamsVar1));
    let itemData2 = serializeStreams(Array.freeze(streamsVar2));
    await itemId1.putAttribute({ sk = "i/" # Nat.toText(catId.1); key = key1; value = itemData1 });
    await itemId1.putAttribute({ sk = "i/" # Nat.toText(itemId.1); key = key2; value = itemData2 });
  };


    /// Removes a stream
  /// TODO: Race condition on removing first links in only one direction. Check for more race conditions.
  func _removeStream(kind: Text, itemId: (Principal, Nat)): async* () {
    let directStream = await* itemsStream(itemId, kind);
    switch (directStream) {
      case (?directStream) {
        for (index in directStream.keys()) {
          switch (directStream[index]) {
            case (?directOrder) {
              let value = Nat.toText(itemId.1) # "@" # Principal.toText(itemId.0);
              let reverseKind = if (kind.chars().next() == ?'r') {
                let iter = kind.chars();
                ignore iter.next();
                Text.fromIter(iter);
              } else {
                "r" # kind;
              };
              // Delete links pointing to us:
              // TODO: If more than 100_000?
              let result = await directOrder.order.0.scanLimitOuter({outerKey = directOrder.order.1; lowerBound = ""; upperBound = "x"; dir = #fwd; limit = 100_000});
              for (p in result.results.vals()) {
                let #text q = p.1 else {
                  Debug.trap("order: programming error");
                };
                // TODO: Extract this to a function:
                let words = Text.split(q, #char '@'); // a bit inefficient
                let w1o = words.next();
                let w2o = words.next();
                let (?w1, ?w2) = (w1o, w2o) else {
                  Debug.trap("order: programming error");
                };
                let ?w1i = Nat.fromText(w1) else {
                  Debug.trap("order: programming error");
                };
                let reverseStream = await* itemsStream((Principal.fromText(w2), w1i), reverseKind);
                switch (reverseStream) {
                  case (?reverseStream) {
                    switch (reverseStream[index]) {
                      case (?reverseOrder) {
                        Debug.print("q=" # q # ", parent=" # debug_show(w1i) # "@" # w2 # ", kind=" # reverseKind);
                        await* Reorder.delete(GUID.nextGuid(guidGen), NacDBIndex, orderer, { order = reverseOrder; value });
                      };
                      case null {};
                    };
                  };
                  case null {};
                };
              };
              // Delete our own sub-DB (before deleting the item itself):
              await directOrder.order.0.deleteSubDBOuter({outerKey = directOrder.order.1});
            };
            case null {};
          }
        };
      };
      case null {};
    };

  };

 public func removeStream(kind: Text, itemId: (Principal, Nat)): async* () {
       await _removeStream(kind,itemId);
  }

 public func getStreamLinks(/*catId: (Principal, Nat),*/ itemId: (Principal, Nat), comment: Bool)
    : async* StreamsLinks
  {
    // let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));
    // TODO: Ensure that item data is readed once per `addItemToFolder` call.
    let ?childItemData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, "i") else {
      // TODO: Keep doing for other folders after a trap?
      Debug.trap("cannot get child item");
    };
    let childItem = deserializeItem(childItemData);

    if (comment) {
      STREAM_LINK_COMMENTS;
    } else {
      switch (childItem.item.details) {
        case (#folder) { STREAM_LINK_SUBFOLDERS };
        case _ { STREAM_LINK_SUBITEMS };
      };
    };
  };

  /// `key1` and `key2` are like `"st"` and `"rst"`
  /// TODO: No need to return an option type
 public func itemsStream(itemId: (Principal, Nat), key2: Text)
    : async* ?Streams
  {
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    let streamsData = await itemId1.getAttribute({sk = "i/" # Nat.toText(itemId.1)}, key2);
    let streams = switch (streamsData) {
      case (?data) {
          deserializeStreams(data);
      };
      case null {
        [null, null, null];
      };
    };
    ?streams;
  };

}