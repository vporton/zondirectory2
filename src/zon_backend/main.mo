import IndexCanister "../storage/IndexCanister";
import PST "../zon_pst";
import DBPartition "../storage/DBPartition";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Entity "mo:candb/Entity";
import BTree "mo:btree/BTree";
import RBT "mo:stable-rbtree/StableRBTree";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import xNat "mo:xtendedNumbers/NatX";
import Buffer "mo:base/Buffer";
import Token "mo:icrc1/ICRC1/Canisters/Token";
import Int "mo:base/Int";
import fractions "./fractions";
import HashMap "mo:base/HashMap";
import Nat8 "mo:base/Nat8";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Int64 "mo:base/Int64";
import Nat64 "mo:base/Nat64";
import ICRC1Types "mo:icrc1/ICRC1/Types";

actor ZonBackend {
  /// External Canisters ///

  let nativeIPCToken = "ryjl3-tyaaa-aaaaa-aaaba-cai"; // native NNS ICP token.
  // let wrappedICPCanisterId = "o5d6i-5aaaa-aaaah-qbz2q-cai"; // https://github.com/C3-Protocol/wicp_docs
  // let wrappedICPCanisterId = "utozz-siaaa-aaaam-qaaxq-cai"; // https://dank.ooo/wicp/ (seem to have less UX)
  // Also consider using https://github.com/dfinity/examples/tree/master/motoko/invoice-canister
  // or https://github.com/research-ag/motoko-lib/blob/main/src/TokenHandler.mo

  let phoneNumberVerificationCanisterId = "gzqxf-kqaaa-aaaak-qakba-cai"; // https://docs.nfid.one/developer/credentials/mobile-phone-number-credential

  /// Some Global Variables ///

  stable var index: ?IndexCanister.IndexCanister = null;
  stable var pst: ?PST.PST = null;
  stable var ledger: Token.Token = actor(nativeIPCToken);

  // "s/" - anti-sybil
  // "u/" - Principal -> User
  // "i/" - ID -> Item
  // "a/" - user -> <buyer affiliate>/<seller affiliate>
  // "v/" - <parent>/<votes> -> <child>
  stable var firstDB: ?DBPartition.DBPartition = null; // ID -> Item
  // TODO: Avoid duplicate user nick names.

  stable var maxId: Nat64 = 0;

  stable var founder: ?Principal = null;

  /// Initialization ///

  public shared({ caller }) func init(subaccount : ?ICRC1Types.Subaccount) {
    founder := ?caller;
    if (pst == null) {
      pst := ?(await PST.PST({ owner = Principal.fromActor(ZonBackend); subaccount = subaccount }));
    };
    if (index == null) {
      index := ?(await IndexCanister.IndexCanister([Principal.fromActor(ZonBackend)]));
    };
    switch (index) {
      case (?index) {
        if (firstDB == null) {
          firstDB := await index.createDBPartition("only");
        };
      };
      case (null) {}
    };
  };

  /// Shares ///

  stable var salesOwnersShare = fractions.fdiv(1, 10); // 10%
  stable var upvotesOwnersShare = fractions.fdiv(1, 2); //50%
  stable var uploadOwnersShare = fractions.fdiv(3, 20); // 15%
  stable var buyerAffiliateShare = fractions.fdiv(1, 10); // 10%
  stable var sellerAffiliateShare = fractions.fdiv(3, 20); // 15%

  public query func getSalesOwnersShare(): async fractions.Fraction { salesOwnersShare };
  public query func getUpvotesOwnersShare(): async fractions.Fraction { upvotesOwnersShare };
  public query func getUploadOwnersShare(): async fractions.Fraction { uploadOwnersShare };
  public query func getBuyerAffiliateShare(): async fractions.Fraction { buyerAffiliateShare };
  public query func getSellerAffiliateShare(): async fractions.Fraction { sellerAffiliateShare };

  public shared({caller = caller}) func setSalesOwnersShare(_share: fractions.Fraction) {
    if (onlyMainOwner(caller)) {
      salesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUpvotesOwnersShare(_share: fractions.Fraction) {
    if (onlyMainOwner(caller)) {
      upvotesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUploadOwnersShare(_share: fractions.Fraction) {
    if (onlyMainOwner(caller)) {
      uploadOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setBuyerAffiliateShare(_share: fractions.Fraction) {
    if (onlyMainOwner(caller)) {
      buyerAffiliateShare := _share;
    };
  };

  public shared({caller = caller}) func setSellerAffiliateShare(_share: fractions.Fraction) {
    if (onlyMainOwner(caller)) {
      sellerAffiliateShare := _share;
    };
  };

  /// Owners ///

  func onlyMainOwner(caller: Principal): Bool {
    if (?caller == founder) {
      true;
    } else {
      Debug.trap("not the main owner");
    }
  };

  public shared({caller = caller}) func setMainOwner(_founder: Principal) {
    if (onlyMainOwner(caller)) {
      founder := ?_founder;
    }
  };

  public shared({caller = caller}) func removeMainOwner() {
    if (onlyMainOwner(caller)) {
      founder := null;
    }
  };

  /// Users ///

  func checkSybil(sybilCanister: Principal, user: Principal): async () {
    var db: DBPartition.DBPartition = actor(Principal.toText(sybilCanister));
    switch (await db.get({sk = "s/" # Principal.toText(user)})) {
      case (null) {
        Debug.trap("not verified user");
      };
      case _ {};
    };
  };

  // anti-Sybil verification
  public shared({caller}) func verifyUser(sybilCanister: Principal): async () {
    let verifyActor = actor(phoneNumberVerificationCanisterId): actor {
      is_phone_number_approved(principal: Text) : async Bool;
    };
    if (await verifyActor.is_phone_number_approved(Principal.toText(caller))) {
      var db: DBPartition.DBPartition = actor(Principal.toText(sybilCanister));
      await db.put({sk = "s/" # Principal.toText(caller); attributes = [("v", #bool true)]});
    } else {
      Debug.trap("cannot verify phone number");
    };
  };

  type User = {
    locale: Text;
    nick: Text;
    title: Text;
    description: Text;
    link : Text;
  };

  func serializeUserAttr(user: User): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(5);
    buf.add(#text (user.locale));
    buf.add(#text (user.nick));
    buf.add(#text (user.title));
    buf.add(#text (user.description));
    buf.add(#text (user.link));
    #tuple (Buffer.toArray(buf));
  };

  func serializeUser(user: User): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeUserAttr(user))];
  };

  func deserializeUserAttr(attr: Entity.AttributeValue): User {
    var locale = "";
    var nick = "";
    var title = "";
    var description = "";
    var link = "";
    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        while (pos < arr.size()) {
          switch (pos) {
            case (0) {
              switch (arr[pos]) {
                case (#text v) {
                  locale := v;
                };
                case _ { break r false };
              };
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false };
              };
            };
            case (2) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false };
              };
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false };
              };
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  link := v;
                };
                case _ { break r false };
              };
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
      Debug.trap("wrong user format");
    };
    {
      locale = locale;
      nick = nick;
      title = title;
      description = description;
      link = link;
    };    
  };

  func deserializeUser(map: Entity.AttributeMap): User {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeUserAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  // TODO: `removeItemOwner`

  public shared({caller = caller}) func setUserData(canisterId: Principal, _user: User, sybilCanisterId: Principal) {
    await checkSybil(sybilCanisterId, caller);
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    await db.put({sk = key; attributes = serializeUser(_user)});
  };

  // TODO: Should also remove all his/her items?
  public shared({caller = caller}) func removeUser(canisterId: Principal) {
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };

  /// Items ///

  type ItemWithoutOwner = {
    price: Nat;
    locale: Text;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #message : (); // TODO: Implement
      #post : ();
      #ownedCategory : ();
      #communalCategory : ();
    };
  };


  // TODO: Add `license` field?
  // TODO: Images.
  // TODO: Upload files.
  // TODO: Item version.
  type Item = {
    creator: Principal;
    item: ItemWithoutOwner;
  };

  func onlyItemOwner(caller: Principal, _item: Item): Bool {
    if (caller == _item.creator) {
      true;
    } else {
      Debug.trap("not the item owner");
    };
  };

  let ITEM_TYPE_LINK = 0;
  let ITEM_TYPE_MESSAGE = 1;
  let ITEM_TYPE_POST = 2;
  let ITEM_TYPE_OWNED_CATEGORY = 3;
  let ITEM_TYPE_COMMUNAL_CATEGORY = 4;

  func serializeItemAttr(item: Item): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int (switch (item.item.details) {
      case (#link v) { ITEM_TYPE_LINK };
      case (#message) { ITEM_TYPE_MESSAGE };
      case (#post) { ITEM_TYPE_POST };
      case (#ownedCategory) { ITEM_TYPE_OWNED_CATEGORY };
      case (#communalCategory) { ITEM_TYPE_COMMUNAL_CATEGORY };
    }));
    buf.add(#text (Principal.toText(item.creator)));
    buf.add(#int (item.item.price));
    buf.add(#text (item.item.locale));
    buf.add(#text (item.item.title));
    buf.add(#text (item.item.description));
    switch (item.item.details) {
      case (#link v) {
        buf.add(#text v);
      };
      case _ {};
    };
    #tuple (Buffer.toArray(buf));
  };

  func serializeItem(item: Item): [(Entity.AttributeKey, Entity.AttributeValue)] {
    [("v", serializeItemAttr(item))];
  };

  func deserializeItemAttr(attr: Entity.AttributeValue): Item {
    var kind: Int = 0;
    var creator: ?Principal = null;
    var price = 0;
    var locale = "";
    var nick = "";
    var title = "";
    var description = "";
    var details: {#none; #link; #message; #post; #ownedCategory; #communalCategory} = #none;
    var link = "";
    let res = label r: Bool switch (attr) {
      case (#tuple arr) {
        var pos = 0;
        var num = 0;
        while (pos < arr.size()) {
          switch (num) {
            case (0) {
              switch (arr[pos]) {
                case (#int v) {
                  kind := v;
                };
                case _ { break r false };
              };
              pos += 1;
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  creator := ?Principal.fromText(v);
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (2) {
              switch (arr[pos]) {
                case (#int v) {
                  price := Int.abs(v);
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  locale := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (5) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case (6) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false; }
              };
              pos += 1;
            };
            case (7) {
              switch (arr[pos]) {
                case (#text v) {
                  link := v;
                };
                case _ { break r false; };
              };
              pos += 1;
            };
            case _ { break r false; };
          };
          num += 1;
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
          case (0) { #link link };
          case (1) { #message };
          case (2) { #post };
          case (3) { #ownedCategory };
          case (4) { #communalCategory };
          case _ { Debug.trap("wrong item format"); }
        };
      };
    };    
  };

  func deserializeItem(map: Entity.AttributeMap): Item {
    let v = RBT.get(map, Text.compare, "v");
    switch (v) {
      case (?v) { deserializeItemAttr(v) };
      case _ { Debug.trap("map not found") };
    };    
  };

  public shared({caller = caller}) func createItemData(canisterId: Principal, _item: ItemWithoutOwner, sybilCanisterId: Principal) {
    await checkSybil(sybilCanisterId, caller);
    let item2 = { creator = caller; item = _item; };
    let _itemId = maxId;
    maxId += 1;
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    await db.put({sk = key; attributes = serializeItem(item2)});
  };

  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller = caller}) func setItemData(canisterId: Principal, _itemId: Nat64, item: ItemWithoutOwner) {
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr.attributes);
        if (caller != oldItem.creator) {
          Debug.trap("can't change item owner");
        };
        let _item = { item = item; creator = caller };
        if (_item.item.details != oldItem.item.details) {
          Debug.trap("can't change item type");
        };
        if (oldItem.item.details == #communalCategory) {
          Debug.trap("can't edit communal category");
        };
        if (onlyItemOwner(caller, oldItem)) {
          await db.put({sk = key; attributes = serializeItem(_item)});
        };
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Also remove voting data.
  public shared({caller = caller}) func removeItem(canisterId: Principal, _itemId: Nat64) {
    var db: DBPartition.DBPartition = actor(Principal.toText(canisterId));
    let key = "i/" # Nat.toText(xNat.from64ToNat(_itemId)); // TODO: Should use binary encoding.
    switch (await db.get({sk = key})) {
      case (?oldItemRepr) {
        let oldItem = deserializeItem(oldItemRepr.attributes);
        if (oldItem.item.details == #communalCategory) {
          Debug.trap("it's communal")
        };
        if (onlyItemOwner(caller, oldItem)) {
          await db.delete({sk = key});
        };
      };
      case _ { Debug.trap("no item") };
    };
  };

  // TODO: Set maximum lengths on user nick, chirp length, etc.?

  /// Incoming Payments ///

  type IncomingPayment = {
    kind: { #payment; #donation };
    itemId: Int; // TODO: Enough `Nat64`.
    amount: Nat;
    var time: ?Time.Time;
  };

  // func serializePaymentAttr(payment: IncomingPayment): Entity.AttributeValue {
  //   var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(3);
  //   buf.add(#int (switch (payment.kind) {
  //     case (#payment) { 0 };
  //     case (#donation) { 1 };
  //   }));
  //   buf.add(#int (payment.itemId));
  //   buf.add(#int (payment.amount));
  //   #tuple (Buffer.toArray(buf));
  // };

  // func serializePayment(payment: IncomingPayment): [(Entity.AttributeKey, Entity.AttributeValue)] {
  //   [("v", serializePaymentAttr(payment))];
  // };

  // func deserializePaymentAttr(attr: Entity.AttributeValue): IncomingPayment {
  //   var kind: { #payment; #donation } = #payment;
  //   var itemId: Int = 0;
  //   var amount = 0;
  //   let res = label r: Bool switch (attr) {
  //     case (#tuple arr) {
  //       var pos = 0;
  //       while (pos < arr.size()) {
  //         switch (pos) {
  //           case (0) {
  //             switch (arr[pos]) {
  //               case (#int v) {
  //                 switch (v) {
  //                   case (0) { kind := #payment; };
  //                   case (1) { kind := #donation; };
  //                   case _ { break r false };
  //                 }
  //               };
  //               case _ { break r false };
  //             };
  //           };
  //           case (1) {
  //             switch (arr[pos]) {
  //               case (#int v) {
  //                 itemId := v;
  //               };
  //               case _ { break r false };
  //             };
  //           };
  //           case (2) {
  //             switch (arr[pos]) {
  //               case (#int v) {
  //                 amount := Int.abs(v);
  //               };
  //               case _ { break r false };
  //             };
  //           };
  //           case _ { break r false; };
  //         };
  //         pos += 1;
  //       };
  //       true;
  //     };
  //     case _ {
  //       false;
  //     };
  //   };
  //   if (not res) {
  //     Debug.trap("wrong user format");
  //   };
  //   {
  //     kind = kind;
  //     itemId = itemId;
  //     amount = amount;
  //   };    
  // };

  // func deserializePayment(map: Entity.AttributeMap): IncomingPayment {
  //   let v = RBT.get(map, Text.compare, "v");
  //   switch (v) {
  //     case (?v) { deserializePaymentAttr(v) };
  //     case _ { Debug.trap("map not found") };
  //   };    
  // };

  stable var currentPayments: BTree.BTree<Principal, IncomingPayment> = BTree.init<Principal, IncomingPayment>(null); // TODO: Delete old ones.
  stable var ourDebts: BTree.BTree<Principal, OutgoingPayment> = BTree.init<Principal, OutgoingPayment>(null); // TODO: subaccounts?

  public query func getOurDebt(user: Principal): async Nat {
    switch (BTree.get(ourDebts, Principal.compare, user)) {
      case (?debt) { debt.amount };
      case (null) { 0 };
    };
  };

  func indebt(to: Principal, amount: Nat) {
    if (amount == 0) {
      return;
    };
    ignore BTree.update<Principal, OutgoingPayment>(ourDebts, Principal.compare, to, func (old: ?OutgoingPayment): OutgoingPayment {
      let sum = switch (old) {
        case (?old) { old.amount + amount };
        case (null) { amount };
      };
      { amount = sum; var time = null };
    });
  };

  // TODO: On non-existent payment it proceeds successful. Is it OK?
  func processPayment(paymentCanisterId: Principal, userId: Principal, _buyerAffiliate: ?Principal, _sellerAffiliate: ?Principal): async () {
    var db: DBPartition.DBPartition = actor(Principal.toText(paymentCanisterId));
    switch (BTree.get<Principal, IncomingPayment>(currentPayments, Principal.compare, userId)) {
      case (?payment) {
        let itemKey = "i/" # Int.toText(payment.itemId);
        switch (await db.get({sk = itemKey})) {
          case (?itemRepr) {
            let item = deserializeItem(itemRepr.attributes);
            let time = switch (payment.time) {
              case (?time) { time };
              case (null) {
                let time = Time.now();
                payment.time := ?time;
                ignore BTree.insert<Principal, IncomingPayment>(currentPayments, Principal.compare, userId, payment);
                time;
              };
            };
            let result = await ledger.icrc1_transfer({
              from_subaccount = ?Principal.toBlob(userId);
              to = {owner = Principal.fromActor(ZonBackend); subaccount = null};
              amount = payment.amount;
              fee = null;
              memo = null;
              created_at_time = ?Nat64.fromNat(Int.abs(time)); // idempotent
            });
            switch (result) {
              case (#Ok _ or #Err (#Duplicate _)) {};
              case _ { Debug.trap("can't pay") };
            };
            let _shareholdersShare = fractions.mul(payment.amount, salesOwnersShare);
            recalculateShareholdersDebt(Int.abs(_shareholdersShare), _buyerAffiliate, _sellerAffiliate); // TODO: abs() is a hack.
            let toAuthor = payment.amount - _shareholdersShare;
            indebt(item.creator, Int.abs(toAuthor)); // TODO: abs() is a hack.
          };
          case (null) {};
        };
        ignore BTree.delete<Principal, IncomingPayment>(currentPayments, Principal.compare, userId);
      };
      case (null) {};
    };
  };

  /// Dividents and Withdrawals ///

  var totalDividends = 0;
  var totalDividendsPaid = 0; // actually paid sum
  // TODO: Set a heavy transfer fee of the PST to ensure that `lastTotalDivedends` doesn't take much memory.
  stable var lastTotalDivedends: BTree.BTree<Principal, Nat> = BTree.init<Principal, Nat>(null); // TODO: subaccounts?

  // TODO: subaccount?
  func _dividendsOwing(_account: Principal): async Nat {
    let lastTotal = switch (BTree.get(lastTotalDivedends, Principal.compare, _account)) {
      case (?value) { value };
      case (null) { 0 };
    };
    let _newDividends = totalDividends - lastTotal;
    let ?pst2 = pst else { Debug.trap("no PST"); };
    // rounding down
    let balance = await pst2.icrc1_balance_of({owner = _account; subaccount = null});
    let total = await pst2.icrc1_total_supply();
    balance * _newDividends / total;
  };

  func recalculateShareholdersDebt(_amount: Nat, _buyerAffiliate: ?Principal, _sellerAffiliate: ?Principal) {
    // Affiliates are delivered by frontend.
    // address payable _buyerAffiliate = affiliates[msg.sender];
    // address payable _sellerAffiliate = affiliates[_author];
    var _shareHoldersAmount = _amount;
    switch (_buyerAffiliate) {
      case (?_buyerAffiliate) {
        let _buyerAffiliateAmount = Int.abs(fractions.mul(_amount, buyerAffiliateShare));
        indebt(_buyerAffiliate, _buyerAffiliateAmount);
        if (_shareHoldersAmount < _buyerAffiliateAmount) {
          Debug.trap("negative amount to pay");
        };
        _shareHoldersAmount -= _buyerAffiliateAmount;
      };
      case (null) {};
    };
    switch (_sellerAffiliate) {
      case (?_sellerAffiliate) {
        let _sellerAffiliateAmount = Int.abs(fractions.mul(_amount, sellerAffiliateShare));
        indebt(_sellerAffiliate, _sellerAffiliateAmount);
        if (_shareHoldersAmount < _sellerAffiliateAmount) {
          Debug.trap("negative amount to pay");
        };
        _shareHoldersAmount -= _sellerAffiliateAmount;
      };
      case (null) {};
    };
    totalDividends += _shareHoldersAmount;
  };

  /// Outgoing Payments ///

  type OutgoingPayment = {
    amount: Nat;
    var time: ?Time.Time;
  };

  public shared({caller = caller}) func payout() {
    switch (BTree.get<Principal, OutgoingPayment>(ourDebts, Principal.compare, caller)) {
      case (?payment) {
        let time = switch (payment.time) {
          case (?time) { time };
          case (null) {
            let time = Time.now();
            payment.time := ?time;
            time;
          }
        };
        let fee = await ledger.icrc1_fee();
        let result = await ledger.icrc1_transfer({
          from_subaccount = null;
          to = {owner = caller; subaccount = null}; // TODO: subaccount
          amount = payment.amount - fee;
          fee = null;
          memo = null;
          created_at_time = ?Nat64.fromNat(Int.abs(time)); // idempotent
        });
        ignore BTree.delete<Principal, OutgoingPayment>(ourDebts, Principal.compare, caller);
      };
      case (null) {};
    }
  };

  /// Affiliates ///

  public shared({caller}) func setAffiliate(canister: Principal, buyerAffiliate: ?Principal, sellerAffiliate: ?Principal): async () {
    var db: DBPartition.DBPartition = actor(Principal.toText(canister));
    if (buyerAffiliate == null and sellerAffiliate == null) {
      await db.delete({sk = "a/" # Principal.toText(caller)});
    };
    let buyerAffiliateStr = switch (buyerAffiliate) {
      case (?user) { Principal.toText(user) };
      case (null) { "" }
    };
    let sellerAffiliateStr = switch (sellerAffiliate) {
      case (?user) { Principal.toText(user) };
      case (null) { "" }
    };
    await db.put({sk = "a/" # Principal.toText(caller); attributes = [("v", #text (buyerAffiliateStr # "/" # sellerAffiliateStr))]});
  }
};
