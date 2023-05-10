import IndexCanister "../storage/IndexCanister";
import PST "../zon_pst";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";

// TODO: Also make the founder's account an owner?
actor ZonBackend {
  type EntryKind = { #NONE; #DOWNLOADS; #LINK; #CATEGORY; }; // TODO: letter case
  type LinkKind = { #Link; #Message };

  stable var index: ?Principal = null;
  stable var pst: ?Principal = null;

  public shared({ caller }) func init() {
    founder := ?caller;
    if (index == null) {
      index := ?Principal.fromActor(await IndexCanister.IndexCanister([Principal.fromActor(ZonBackend)]));
    };
    if (pst == null) {
      // FIXME: `null` subaccount?
      pst := ?Principal.fromActor(await PST.PST({ owner = Principal.fromActor(ZonBackend); subaccount = null }));
    };
  };

  stable var salesOwnersShare = 0.1;
  stable var upvotesOwnersShare = 0.5;
  stable var uploadOwnersShare = 0.15;
  stable var buyerAffiliateShare = 0.1;
  stable var sellerAffiliateShare = 0.15;

  public query func getSalesOwnersShare(): async Float { salesOwnersShare };
  public query func getUpvotesOwnersShare(): async Float { upvotesOwnersShare };
  public query func getUploadOwnersShare(): async Float { uploadOwnersShare };
  public query func getBuyerAffiliateShare(): async Float { buyerAffiliateShare };
  public query func getSellerAffiliateShare(): async Float { sellerAffiliateShare };

  stable var maxId: Nat64 = 0;

  // TODO: Here an below: subaccount?
  stable var founder: ?Principal = null;

  type Item = {
    owner: Principal;
    price: Nat;
    title: Text;
    description: Text;
    details: {
      #link : Text;
      #post : Text;
    };
  };

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

  public shared({caller = caller}) func setSalesOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      salesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUpvotesOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      upvotesOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setUploadOwnersShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      uploadOwnersShare := _share;
    };
  };

  public shared({caller = caller}) func setBuyerAffiliateShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      buyerAffiliateShare := _share;
    };
  };

  public shared({caller = caller}) func setSellerAffiliateShare(_share: Float) {
    if (onlyMainOwner(caller)) {
      sellerAffiliateShare := _share;
    };
  };
};
