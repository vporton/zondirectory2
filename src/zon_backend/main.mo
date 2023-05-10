import IndexCanister "../storage/IndexCanister";
import PST "../zon_pst";
import Principal "mo:base/Principal";

actor ZonBackend {
  stable var index: ?Principal = null;
  stable var pst: ?Principal = null;
  public shared({ caller }) func init() {
    if (index == null) {
      index := ?Principal.fromActor(await IndexCanister.IndexCanister([Principal.fromActor(ZonBackend)]));
    };
    if (pst == null) {
      // FIXME: `null` subaccount?
      pst := ?Principal.fromActor(await PST.PST({ owner = Principal.fromActor(ZonBackend); subaccount = null }));
    };
  }
};
