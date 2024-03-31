import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import order "canister:order";

import Entity "mo:candb/Entity";

import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";
import MyCycles "mo:nacdb/Cycles";

import UserModule "modules/user";
import ItemModule "modules/item";
import DBConfig "../libs/configs/db.config";
// import ICRC1Types "mo:icrc1/ICRC1/Types";

shared actor class ZonBackend() = this {
  /// External Canisters ///

  /// Some Global Variables ///

  // See ARCHITECTURE.md for database structure

  // TODO: Avoid duplicate user nick names.

  stable var maxId: Nat = 0;

  stable var founder: ?Principal = null;

  /// Initialization ///

  stable var initialized: Bool = false;

  public shared({ caller }) func init(): async () {
    ignore MyCycles.topUpCycles<system>(DBConfig.dbOptions.partitionCycles);

    if (initialized) {
      Debug.trap("already initialized");
    };

    founder := ?caller;

    initialized := true;
  };

  /// Owners ///

  func onlyMainOwner(caller: Principal) {
    if (?caller != founder) {
      Debug.trap("not the main owner");
    }
  };

  public shared({caller}) func setMainOwner(_founder: Principal) {
    onlyMainOwner(caller);

    founder := ?_founder;
  };

  // TODO: probably, superfluous.
  public shared({caller}) func removeMainOwner() {
    onlyMainOwner(caller);
    
    founder := null;
  };

  

  /// Items  public APIs///

  stable var rootItem: ?(CanDBPartition.CanDBPartition, Nat) = null;

  public shared({caller}) func setRootItem(part: Principal, id: Nat)
    : async ()
  {
    onlyMainOwner(caller);

    rootItem := ?(actor(Principal.toText(part)), id);
  };

  public query func getRootItem(): async ?(Principal, Nat) {
    do ? {
      let (part, n) = rootItem!;
      (Principal.fromActor(part), n);
    };
  };

  public shared({caller}) func createItemData(item: ItemModule.ItemWithoutOwner): async (Principal, Nat)
  {
    await ItemModule.createItemData(item);
  };


  // We don't check that owner exists: If a user lost his/her item, that's his/her problem, not ours.
  public shared({caller}) func setItemData(canisterId: Principal, _itemId: Nat, item: ItemModule.ItemWithoutOwner) {
    await ItemModule.setItemData(canisterId,_itemId,item);
  };

  public shared({caller}) func setPostText(canisterId: Principal, _itemId: Nat, text: Text) {
    await ItemModule.setPostText(canisterId,_itemId,text);
  };

  // TODO: Also remove voting data.
  public shared({caller}) func removeItem(canisterId: Principal, _itemId: Nat) {
    await ItemModule.removeItem(canisterId,_itemId);
  };


  /// Vote Endpoints ///
  /// Auth Endpoints ///
  /// Folder/Category Endpoints ///
  /// Payment Endpoints ///
  /// Order Endpoints ///
  /// Affiliate Endpoints ///

  // TODO: Set maximum lengths on user nick, chirp length, etc.

  /// Affiliates ///

  // public shared({caller}) func setAffiliate(canister: Principal, buyerAffiliate: ?Principal, sellerAffiliate: ?Principal): async () {
  //   var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canister));
  //   if (buyerAffiliate == null and sellerAffiliate == null) {
  //     await db.delete({sk = "a/" # Principal.toText(caller)});
  //   };
  //   let buyerAffiliateStr = switch (buyerAffiliate) {
  //     case (?user) { Principal.toText(user) };
  //     case (null) { "" }
  //   };
  //   let sellerAffiliateStr = switch (sellerAffiliate) {
  //     case (?user) { Principal.toText(user) };
  //     case (null) { "" }
  //   };
  //   // await db.put({sk = "a/" # Principal.toText(caller); attributes = [("v", #text (buyerAffiliateStr # "/" # sellerAffiliateStr))]});
  // };

  public shared func get_trusted_origins(): async [Text] {
    return [];
  };
}
