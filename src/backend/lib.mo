import xNat "mo:xtendedNumbers/NatX";
import Nac "mo:nacdb/NacDB";
import NacDBPartition "../storage/NacDBPartition";
import RBT "mo:stable-rbtree/StableRBTree";
import Entity "mo:candb/Entity";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Reorder "mo:NacDBReorder/Reorder";
import config "../../config";

module {
  // let phoneNumberVerificationCanisterId = "gzqxf-kqaaa-aaaak-qakba-cai"; // https://docs.nfid.one/developer/credentials/mobile-phone-number-credential

  // We will use that "-XXX" < "XXX" for any hex number XXX.

  func _toLowerHexDigit(v: Nat): Char {
    Char.fromNat32(Nat32.fromNat(
      if (v < 10) {
        Nat32.toNat(Char.toNat32('0')) + v;
      } else {
        Nat32.toNat(Char.toNat32('a')) - 10 + v;
      }
    ));
  };

  func _fromLowerHexDigit(c: Char): Nat {
    Nat32.toNat(
      if (c <= '9') {
        Char.toNat32(c) - Char.toNat32('0');
      } else {
        Char.toNat32(c) - (Char.toNat32('a') - 10);
      }
    );
  };

  func encodeBlob(g: Blob): Text {
    var result = "";
    for (b in g.vals()) {
      let b2 = Nat8.toNat(b);
      result #= Text.fromChar(_toLowerHexDigit(b2 / 16)) # Text.fromChar(_toLowerHexDigit(b2 % 16));
    };
    result;
  };

  func decodeBlob(t: Text): Blob {
    let buf = Buffer.Buffer<Nat8>(t.size() / 2);
    let c = t.chars();
    label r loop {
      let ?upper = c.next() else {
        break r;
      };
      let ?lower = c.next() else {
        Debug.trap("decodeBlob: wrong hex number");
      };
      let b = Nat8.fromNat(_fromLowerHexDigit(upper) * 16 + _fromLowerHexDigit(lower));
      buf.add(b);
    };
    Blob.fromArray(Buffer.toArray(buf));
  };

  public func encodeNat(n: Nat): Text {
    var n64 = Nat64.fromNat(n);
    let buf = Buffer.Buffer<Nat8>(8);
    for (i in Iter.range(0, 7)) {
      buf.add(Nat8.fromNat(Nat64.toNat(n64 % 256)));
      n64 >>= 8;
    };
    let blob = Blob.fromArray(Array.reverse(Buffer.toArray(buf)));
    encodeBlob(blob);
  };

  public func decodeNat(t: Text): Nat {
    let blob = decodeBlob(t);
    var result: Nat64 = 0;
    for (b in blob.vals()) {
      result <<= 8;
      result += xNat.from8To64(b);
    };
    Nat64.toNat(result);
  };

  // For integers less than 2**64 have the same lexigraphical sort order as the argument.
  public func encodeInt(n: Int): Text {
    assert n < 2**64;
    if (n >= 0) {
      encodeNat(Int.abs(n));
    } else {
      "-" # encodeNat(2**64 - Int.abs(n));
    };
  };

  public func decodeInt(t: Text): Int {
    let iter = t.chars();
    if (iter.next() == ?'-') {
      -(2**64 - decodeNat(Text.fromIter(iter)));
    } else {
      decodeNat(t);
    }
  };

  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_OWNED_CATEGORY = 3; // TODO: Rename.

  public type ItemKind = {
    #link;
    #message;
    #post;
    #ownedCategory; // TODO: Rename.
  };

  public type ItemData = {
    price: Float;
    locale: Text;
    title: Text;
    description: Text;
    link: ?Text;
    // save post text separately
  };

  public type ItemOwnership = {
    #owned: ItemData;
    #communal;
  };

  public type ItemWithoutCreator = {
    kind: ItemKind;
    ownership: ItemOwnership;
  };

  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Item version.
  public type Item = {
    creator: Principal;
    item: ItemWithoutCreator;
  };

  // TODO: Add support for it later. For now do WITHOUT communal items.
  // We can use either this struct or ItemData with always `#owned`.
  // public type CommunalChoice = {
  //   creator: Principal;
  //   item: ItemData;
  // };

  // TODO: Does it make sense to keep `Streams` in lib?
  public type StreamsLinks = Nat;
  public let STREAM_LINK_SUBITEMS: StreamsLinks = 0; // category <-> sub-items
  public let STREAM_LINK_SUBCATEGORIES: StreamsLinks = 1; // category <-> sub-categories
  public let STREAM_LINK_COMMENTS: StreamsLinks = 2; // item <-> comments
  public let STREAM_LINK_MAX: StreamsLinks = STREAM_LINK_COMMENTS;

  public type Streams = [?Reorder.Order];

  // TODO: messy order of the below functions

  public func serializeItem(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(7); // TODO: Check the number.
    buf.add(#int 0); // version
    buf.add(#int (switch (item.item.kind) {
      case (#link) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post) { ITEM_TYPE_POST };
      case (#ownedCategory) { ITEM_TYPE_OWNED_CATEGORY };
    }));
    buf.add(#text(Principal.toText(item.creator)));
    switch (item.item.ownership) {
      case (#owned v) {
        buf.add(#bool false);
        buf.add(#float(v.price));
        buf.add(#text(v.locale));
        buf.add(#text(v.title));
        buf.add(#text(v.description));
        switch (v.link) {
          case (?t) {
            buf.add(#text t);
          };
          case null {
            buf.add(#text "");
          }
        };
      };
      case (#communal) {
        buf.add(#bool true);
      }
    };
    #tuple(Buffer.toArray(buf));
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

  public func deserializeItem(attr: Entity.AttributeValue): Item {
    var kind: Nat = 0;
    var owned: Bool = false;
    var creator: ?Principal = null;
    var price = 0.0;
    var locale = "";
    var title = "";
    var description = "";
    var details: {#link; #message; #post; #ownedCategory} = #link; // arbitrary value
    var link = "";

    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        switch (arr[pos]) {
          case (#int v) {
            assert v == 0;
          };
          case _ { break r false };
        };
        pos += 1;
        switch (arr[pos]) {
          case (#int v) {
            kind := Int.abs(v);
          };
          case _ { break r false };
        };
        pos += 1;
        switch (arr[pos]) {
          case (#text v) {
            creator := ?Principal.fromText(v);
          };
          case _ { break r false; };
        };
        pos += 1;
        switch (arr[pos]) {
          case (#bool v) {
            owned := v;
          };
          case _ { break r false };
        };
        pos += 1;
        if (owned) {
          switch (arr[pos]) {
            case (#float v) {
              price := v;
            };
            case _ { break r false; };
          };
          pos += 1;
          switch (arr[pos]) {
            case (#text v) {
              locale := v;
            };
            case _ { break r false; };
          };
          pos += 1;
          switch (arr[pos]) {
            case (#text v) {
              title := v;
            };
            case _ { break r false; };
          };
          pos += 1;
          switch (arr[pos]) {
            case (#text v) {
              description := v;
            };
            case _ { break r false; }
          };
          pos += 1;
          switch (arr[pos]) {
            case (#text v) {
              link := v;
            };
            case _ { break r false; }
          };
          pos += 1;
        };

        true;
      };
      case _ {
        false;
      };
    };
    if (not res) {
      Debug.trap("wrong item format");
    };
    let ?creator2 = creator else { Debug.trap("creator2: programming error"); };
    let ownership = if (owned) {
      #owned {
        price = price;
        locale = locale;
        title = title;
        description = description;
        link = if (link == "") { null } else { ?link };
      };
    } else {
      #communal
    };
    {
      creator = creator2;
      item = {
        kind = switch (kind) {
          case (0) { #link };
          case (1) { #message };
          case (2) { #post };
          case (3) { #ownedCategory };
          case _ { Debug.trap("wrong item format"); }
        };
        ownership;
      };
    };
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

  public type Karma = {
    earnedVotes: Nat;
    remainingBonusVotes: Nat;
    lastBonusUpdated: Time.Time;
  };

  public func serializeKarma(karma: Karma): Entity.AttributeValue {
    #tuple([
      #int(0), // version
      #int(karma.earnedVotes),
      #int(karma.remainingBonusVotes),
      #int(karma.lastBonusUpdated),
    ]);
  };

  public func deserializeKarma(attr: Entity.AttributeValue): Karma {
    let res = label r {
      switch (attr) {
        case (#tuple arr) {
          let a: [var Nat] = Array.tabulateVar<Nat>(3, func _ = 0);
          switch (arr[0]) {
            case (#int v) {
              assert v == 0;
            };
            case _ { Debug.trap("Wrong karma version"); };
          };
          for (i in Iter.range(0,2)) {
            switch (arr[i+1]) {
              case (#int elt) {
                a[i] := Int.abs(elt);
              };
              case _ { break r; };
            };
            return {
              earnedVotes = a[0];
              remainingBonusVotes = a[1];
              lastBonusUpdated = a[2];
            };
          };
        };
        case _ { break r; };
      };
    };
    Debug.trap("wrong votes format");
  };

  public func onlyItemOwner(caller: Principal, _item: Item) {
    if (caller != _item.creator) {
      Debug.trap("not the item owner");
    };
  };

  public func checkSybil(user: Principal): async* () {
    if (config.skipSybil) {
      return;
    };
    // TODO:
    // let verifyActor = actor(phoneNumberVerificationCanisterId): actor {
    //   is_phone_number_approved(principal: Text) : async Bool;
    // };
    // if (not(await verifyActor.is_phone_number_approved(Principal.toText(user)))) {
    //   Debug.trap("cannot verify phone number");
    // };
  };
}