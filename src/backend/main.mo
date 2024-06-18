import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../storage/CanDBPartition";

shared({caller = initialOwner}) actor class ZonBackend() = this {
  stable var owners = [initialOwner];

  func checkCaller(caller: Principal) {
    if (Array.find(owners, func(e: Principal): Bool { e == caller; }) == null) {
      Debug.trap("item: not allowed");
    }
  };

  public shared({caller = caller}) func setOwners(_owners: [Principal]): async () {
    checkCaller(caller);

    owners := _owners;
  };

  public query func getOwners(): async [Principal] { owners };

  stable var initialized: Bool = false;

  /// External Canisters ///

  // See ARCHITECTURE.md for database structure

  // TODO: Avoid duplicate user nick names.

  stable var founder: ?Principal = null;

  /// Initialization ///

  public shared({ caller }) func init(): async () {
    checkCaller(caller);

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

  /// Items ///

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

  public shared func getUserScore(user: Principal, hint: ?Principal): async ?(Principal, Nat) {
    let sk = "u/" # Principal.toText(user);
    let ?(part, v) = await CanDBIndex.getAttributeByHint("user", hint, {sk; subkey = "p"}) else {
      return null;
    };
    switch (v) {
      case (?(#int n)) ?(part, Int.abs(n));
      case _ null;
    };
  };

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

  // What is it?
  // public shared func get_trusted_origins(): async [Text] {
  //   return [];
  // };

  system func inspect({
    // arg : Blob;
    caller : Principal;
    msg :
      {
        #getOwners : () -> ();
        #getRootItem : () -> ();
        #getUserScore : () -> (Principal, ?Principal);
        #init : () -> ();
        #removeMainOwner : () -> ();
        #setMainOwner : () -> Principal;
        #setOwners : () -> [Principal];
        #setRootItem : () -> (Principal, Nat)
      }
  }): Bool {
    switch (msg) {
      case (#getOwners _ or #getRootItem _ or #getUserScore _) {
        false; // query only
      };
      case _ {
        checkCaller(caller);
        true;
      };
    };
  };
}
