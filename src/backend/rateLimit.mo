/// Module for rate-limiting ICP requests.

import RBTree "mo:base/RBTree";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Debug "mo:base/Debug";

module {
    public type Entry = {
        var requests: Nat;
    };

    public type Requests = {
        var princes: HashMap.HashMap<Principal, Entry>;
        var times: RBTree.RBTree<Time.Time, HashMap.HashMap<Principal, ()>>;
        var marker: Time.Time;
    };
    
    public func newRequests(): Requests {
        {
            var princes = HashMap.HashMap(0, Principal.equal, Principal.hash);
            var times = RBTree.RBTree(Int.compare);
            var marker = 0;
        };
    };

    public func checkRequest(requests: Requests, caller: Principal) {
        let now = Time.now();
        if (now - requests.marker >= 60_000_000_000) { // 60 sec; TODO: Make configurable.
            requests.marker := now;
            requests.princes := HashMap.HashMap(0, Principal.equal, Principal.hash);
            requests.times := RBTree.RBTree(Int.compare);
        };
        while (requests.princes.size() >= 150) { // TODO: Make configurable.
            let ?(time, submap) = requests.times.entries().next() else {
                Debug.trap("programming error");
            };
            let ?(principal, ()) = submap.entries().next() else {
                Debug.trap("programming error");
            };
            requests.princes.delete(principal);
            if (submap.size() == 1) {
                requests.times.delete(time);
            } else {
                submap.delete(principal);
            };
        };

        let entry = requests.princes.get(caller);
        switch (entry) {
            case (?entry) {
                entry.requests += 1;
                if (entry.requests > 140) { // TODO: Make configurable.
                    Debug.trap("too many requests");
                };
            };
            case null {
                requests.princes.put(caller, {var requests = 1});
                switch (requests.times.get(now)) {
                    case (?submap) {
                        submap.put(caller, ());
                    };
                    case null {
                        let submap = HashMap.HashMap<Principal, ()>(1, Principal.equal, Principal.hash);
                        submap.put(caller, ());
                        requests.times.put(now, submap);
                    };
                }
            }
        }
    }
}