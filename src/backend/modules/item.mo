import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

import order "canister:order";
import Itertools "mo:itertools/Iter";
import xNat "mo:xtendedNumbers/NatX";
import Entity "mo:candb/Entity";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../../storage/CanDBPartition";
import Nac "mo:nacdb/NacDB";
import GUID "mo:nacdb/GUID";
import NacDBIndex "canister:NacDBIndex";
import Reorder "mo:nacdb-reorder/Reorder";

import StreamModule "stream";



module{

 // FIXME: Communal will be a boolean flag, in order to deal with communal links and posts.
  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_FOLDER = 3;
  
  // FIXME: Communal will be a boolean flag, in order to deal with communal links and posts.
  public type ItemWithoutOwner = {
    communal: Bool;
    // #owned : {
      price: Float;
      locale: Text;
      title: Text;
      description: Text;
      details: {
        #link : Text;
        #message : ();
        #post : (); // save post text separately
        #folder : ();
      };
    // };
    // #communal : {
    //   votesStream: Reorder.Order;
    // };
  };

  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Item version.
  public type Item = {
    creator: Principal;
    item: ItemWithoutOwner;
  };

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
  };

public query func getItem(itemId: Nat): async ?Item {
    let data = CanDBPartition.getAttribute({sk = "i/" # Nat.toText(itemId)}, "i");
    do ? { deserializeItem(data!) };
  };


 public shared({caller}) func createItemData(item: ItemWithoutOwner)
    : async (Principal, Nat)
  {
    let item2: Item = { creator = caller; item; };
    let itemId = maxId;
    maxId += 1;
    let key = "i/" # Nat.toText(itemId);
    let canisterId = await CanDBIndex.putAttributeWithPossibleDuplicate(
      "main", { sk = key; key = "i"; value = serializeItem(item2) }
    );
    (canisterId, itemId);
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, _itemId: Nat, item: ItemWithoutOwner) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        let _item: Item = { item = item; creator = caller; var streams = null; };
        if (_item.item.details != oldItem.item.details) {
          Debug.trap("can't change item type");
        };
        if (oldItem.item.communal) {
          Debug.trap("can't edit communal folder");
        };
        onlyItemOwner(caller, oldItem);
        await db.putAttribute({sk = key; key = "i"; value = serializeItem(_item)});
      };
      case _ { Debug.trap("no item") };
    };
  };

  public shared({caller}) func setPostText(canisterId: Principal, _itemId: Nat, text: Text) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId); // TODO: better encoding
    switch (await db.getAttribute({sk = key}, "i")) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        onlyItemOwner(caller, oldItem);
        switch(oldItem.item.details) {
          case (#post) {};
          case _ { Debug.trap("not a post"); };
        };
        await db.putAttribute({ sk = key; key = "t"; value = #text(text) });
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Also remove voting data.
  public shared({caller}) func removeItem(canisterId: Principal, _itemId: Nat) {
    // We first remove links, then the item itself, in order to avoid race conditions when displaying.
    await order.removeItemLinks((canisterId, _itemId));
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(_itemId);
    let ?oldItemRepr = await db.getAttribute({sk = key}, "i") else {
      Debug.trap("no item");
    };
    let oldItem = deserializeItem(oldItemRepr);
    if (oldItem.item.communal) {
      Debug.trap("it's communal");
    };
    onlyItemOwner(caller, oldItem);
    await db.delete({sk = key});
  };



 // TODO: messy order of the below functions

  public func serializeItem(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(8);
    buf.add(#int 0); // version
    buf.add(#bool(item.item.communal));
    buf.add(#int (switch (item.item.details) {
      case (#link v) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post _) { ITEM_TYPE_POST };
      case (#folder) { ITEM_TYPE_FOLDER };
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
      case _ {};
    };
    #tuple(Buffer.toArray(buf));
  };

 public func deserializeItem(attr: Entity.AttributeValue): Item {
    var kind: Nat = 0;
    var creator: ?Principal = null;
    var communal = false;
    var price = 0.0;
    var locale = "";
    var title = "";
    var description = "";
    var details: {#none; #link; #message; #post; #folder} = #none;
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
          case (#bool v) {
            communal := v;
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
        if (kind == ITEM_TYPE_LINK) {
          switch (arr[pos]) {
            case (#text v) {
              link := v;
            };
            case _ { break r false; };
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
    {
      creator = creator2;
      item = {
        communal = communal;
        price = price;
        locale = locale;
        title = title;
        description = description;
        details = switch (kind) {
          case (0) { #link link };
          case (1) { #message };
          case (2) { #post };
          case (3) { #folder };
          case _ { Debug.trap("wrong item format"); }
        };
      };
    };
  };



 public func onlyItemOwner(caller: Principal, _item: Item) {
    if (caller != _item.creator) {
      Debug.trap("not the item owner");
    };
  };


  
 public func addItemToList(theSubDB: Reorder.Order, itemToAdd: (Principal, Nat), side: { #beginning; #end; #zero }): async* () {
    let scanItemInfo = Nat.toText(itemToAdd.1) # "@" # Principal.toText(itemToAdd.0);
    let theSubDB2: Nac.OuterCanister = theSubDB.order.0;
    if (await theSubDB2.hasByOuter({outerKey = theSubDB.reverse.1; sk = scanItemInfo})) {
      return; // prevent duplicate
    };
    // TODO: race

    let timeScanSK = if (side == #zero) {
      0;
    } else {
      let scanResult = await theSubDB2.scanLimitOuter({
        dir = if (side == #end) { #bwd } else { #fwd };
        outerKey = theSubDB.order.1;
        lowerBound = "";
        upperBound = "x";
        limit = 1;
        ascending = ?(if (side == #end) { false } else { true });
      });
      let timeScanSK = if (scanResult.results.size() == 0) { // empty list
        0;
      } else {
        let t = scanResult.results[0].0;
        let n = decodeInt(Text.fromIter(Itertools.takeWhile(t.chars(), func (c: Char): Bool { c != '#' })));
        if (side == #end) { n + 1 } else { n - 1 };
      };
      timeScanSK;
    };
    
 
  // Public API //

  public shared({caller}) func addItemToFolder(
    catId: (Principal, Nat),
    itemId: (Principal, Nat),
    comment: Bool,
    side: { #beginning; #end }, // ignored unless adding to an owned folder
  ): async () {
    let catId1: CanDBPartition.CanDBPartition = actor(Principal.toText(catId.0));
    let itemId1: CanDBPartition.CanDBPartition = actor(Principal.toText(itemId.0));

    // TODO: Race condition when adding an item.
    // TODO: Ensure that it is retrieved once.
    let ?folderItemData = await catId1.getAttribute({sk = "i/" # Nat.toText(catId.1)}, "i") else {
      Debug.trap("cannot get folder item");
    };
    let folderItem = deserializeItem(folderItemData);

    if (not folderItem.item.communal) { // TODO: Remove `folderItem.item.details == #folder and`?
      onlyItemOwner(caller, folderItem);
    };
    if (folderItem.item.details != #folder and not comment) {
      Debug.trap("not a folder");
    };
    let links = await* StreamModule.getStreamLinks(itemId, comment);
    await* StreamModule.addToStreams(catId, itemId, comment, links, itemId1, "st", "rst", #beginning);
    if (folderItem.item.details == #folder) {
      await* StreamModule.addToStreams(catId, itemId, comment, links, itemId1, "sv", "rsv", side);
    } else {
      await* StreamModule.addToStreams(catId, itemId, comment, links, itemId1, "sv", "rsv", #end);
    };
  };


  
  public shared({caller}) func removeItemLinks(itemId: (Principal, Nat)): async () {
    // checkCaller(caller); // FIXME: Uncomment.
    await* _removeItemLinks(itemId);
  };

  func _removeItemLinks(itemId: (Principal, Nat)): async* () {
    // FIXME: Also delete the other end.
    await* StreamModule.removeStream("st", itemId);
    await* StreamModule.removeStream("sv", itemId);
    await* StreamModule.removeStream("rst", itemId);
    await* StreamModule.removeStream("rsv", itemId);
    // await* StreamModule.removeStream("stc", itemId);
    // await* StreamModule.removeStream("vsc", itemId);
    // await* StreamModule.removeStream("rstc", itemId);
    // await* StreamModule.removeStream("rsvc", itemId);
  };



}