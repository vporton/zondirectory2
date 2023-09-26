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
import CanDBPartition "../storage/CanDBPartition";
import config "../../config";

module {
  // We will use that "-XXX" < "XXX" for any hex number XXX.

  func _toLowerHexDigit(v: Nat): Char {
    Char.fromNat32(Nat32.fromNat(
      if (v < 10) {
        Nat32.toNat(Char.toNat32('0')) + v;
      } else {
        Nat32.toNat(Char.toNat32('a')) + v - 10;
      }
    ));
  };

  func _fromLowerHexDigit(c: Char): Nat {
    Nat32.toNat(
      if (c <= '9') {
        Char.toNat32(c) - Char.toNat32('0');
      } else {
        Char.toNat32(c) - Char.toNat32('a') + 10;
      }
    );
  };

  func encodeBlob(g: Blob): Text {
    var result = ""; // TODO: Optimize, if possible, using a Buffer of pre-calculated size.
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
        Debug.trap("programming error");
      };
      let ?lower = c.next() else {
        break r;
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
      result += Nat64.fromNat(Nat8.toNat(b)); // TODO: possibly inefficient
    };
    Nat64.toNat(result);
  };

  public func encodeInt(n: Int): Text {
    let a = encodeNat(Int.abs(n));
    if (n >= 0) {
      a;
    } else {
      "-" # a;
    };
  };

  public func decodeInt(t: Text): Int {
    let iter = t.chars();
    if (iter.next() == ?'-') {
      -decodeNat(Text.fromIter(iter));
    } else {
      decodeNat(t);
    }
  };

  // TODO: Extract below to a separate module.

  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_OWNED_CATEGORY = 3;
  let ITEM_TYPE_COMMUNAL_CATEGORY = 4;

  public type ItemWithoutOwner = {
    price: Float;
    locale: Text;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #message : ();
      #post : Text;
      #ownedCategory : ();
      #communalCategory : ();
    };
  };

  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Item version.
  // TODO: Rename.
  public type Item = {
    creator: Principal;
    item: ItemWithoutOwner;
  };

  public type Streams = {
    itemsTimeOrderSubDB: (
      Nac.OuterCanister,
      Nac.OuterSubDBKey,
    );
    categoriesTimeOrderSubDB: (
      Nac.OuterCanister,
      Nac.OuterSubDBKey,
    );
    // votesOrderSubDB: ( // TODO
    //   Nac.OuterCanister
    //   Nac.OuterSubDBKey,
    // );
  };

  // TODO: messy order of the below functions

  public func serializeItem(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(5); // TODO: good number?
    buf.add(#int (switch (item.item.details) {
      case (#link v) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post _) { ITEM_TYPE_POST };
      case (#ownedCategory) { ITEM_TYPE_OWNED_CATEGORY };
      case (#communalCategory) { ITEM_TYPE_COMMUNAL_CATEGORY };
    }));
    buf.add(#text(Principal.toText(item.creator)));
    buf.add(#float(item.item.price));
    buf.add(#text(item.item.locale));
    buf.add(#text(item.item.title));
    buf.add(#text(item.item.description));
    switch (item.item.details) {
      case (#link v) {
        buf.add(#text v);
      };
      case (#post v) {
        buf.add(#text v);
      };
      case _ {};
    };
    #tuple(Buffer.toArray(buf));
  };

  public func serializeStreams(streams: Streams): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(4);
    buf.add(#text(Principal.toText(Principal.fromActor(streams.itemsTimeOrderSubDB.0))));
    buf.add(#int(streams.itemsTimeOrderSubDB.1));
    buf.add(#text(Principal.toText(Principal.fromActor(streams.categoriesTimeOrderSubDB.0))));
    buf.add(#int(streams.categoriesTimeOrderSubDB.1));
    #tuple(Buffer.toArray(buf));
  };

  public func deserializeItem(attr: Entity.AttributeValue): Item {
    var kind: Nat = 0;
    var creator: ?Principal = null;
    var price = 0.0;
    var locale = "";
    var nick = "";
    var title = "";
    var description = "";
    var details: {#none; #link; #message; #post; #ownedCategory; #communalCategory} = #none;
    var linkOrText = "";
    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
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
            nick := v;
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
            linkOrText := v;
          };
          case _ { break r false; };
        };
        pos += 1;
        let haveStreams = switch (arr[pos]) {
          case (#bool v) { v };
          case _ { break r false; };
        };
        pos += 1;

        true;
      };
      case _ {
        false;
      };
    };
    if (not res) {
      Debug.trap("wrong item format");
    };
    let ?creator2 = creator else { Debug.trap("programming error"); };
    {
      creator = creator2;
      item = {
        price = price;
        locale = locale;
        nick = nick;
        title = title;
        description = description;
        details = switch (kind) {
          case (0) { #link linkOrText };
          case (1) { #message };
          case (2) { #post linkOrText };
          case (3) { #ownedCategory };
          case (4) { #communalCategory };
          case _ { Debug.trap("wrong item format"); }
        };
      };
    };
  };

  func deserializeStreams(attr: Entity.AttributeValue): Streams {
    label r switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        return {
          itemsTimeOrderSubDB = switch(arr[0], arr[1]) {
            case (#text p, #int n) { (actor(p), Int.abs(n)) };
            case _ { break r; };
          };
          categoriesTimeOrderSubDB = switch(arr[2], arr[3]) {
            case (#text p, #int n) { (actor(p), Int.abs(n)) };
            case _ { break r; };
          };
        };
      };
      case _ {};
    };
    Debug.trap("wrong streams descriptor format");
  };

  public func onlyItemOwner(caller: Principal, _item: Item) {
    if (caller != _item.creator) {
      Debug.trap("not the item owner");
    };
  };

  // TODO: Check that this gives right permissions.
  // `sybilCanister` is determined by frontend code (util/sybil.ts).
  // TODO: `sybilCanister` should have its dedicated PK, to reduce the number of UI calls.
  //       Alternatively, store `sybilCanister` on-chain or somehow.
  public func checkSybil(sybilCanister: Principal, user: Principal): async* () {
    if (config.skipSybil) {
      return;
    };
    // FIXME:
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(sybilCanister));
    switch (await db.getAttribute({sk = "u/" # Principal.toText(user)}, "s")) {
      case (null) {
        Debug.trap("not verified user");
      };
      case _ {};
    };
  };
}