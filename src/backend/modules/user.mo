import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";

import Entity "mo:candb/Entity";

import CanDBIndex "canister:CanDBIndex";
import CanDBPartition "../../storage/CanDBPartition";

module UserModule{
    /// Users ///

  type User = {
    locale: Text;
    nick: Text;
    title: Text;
    description: Text;
    // TODO: long description
    link : Text;
  };

  func serializeUser(user: User): Entity.AttributeValue {
    var buf = Buffer.Buffer<Entity.AttributeValuePrimitive>(6);
    buf.add(#int 0); // version
    buf.add(#text (user.locale));
    buf.add(#text (user.nick));
    buf.add(#text (user.title));
    buf.add(#text (user.description));
    buf.add(#text (user.link));
    #tuple (Buffer.toArray(buf));
  };

  func deserializeUser(attr: Entity.AttributeValue): User {
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
                case (#int v) {
                  assert v == 0; // version
                };
                case _ { break r false };
              };
            };
            case (1) {
              switch (arr[pos]) {
                case (#text v) {
                  locale := v;
                };
                case _ { break r false };
              };
            };
            case (2) {
              switch (arr[pos]) {
                case (#text v) {
                  nick := v;
                };
                case _ { break r false };
              };
            };
            case (3) {
              switch (arr[pos]) {
                case (#text v) {
                  title := v;
                };
                case _ { break r false };
              };
            };
            case (4) {
              switch (arr[pos]) {
                case (#text v) {
                  description := v;
                };
                case _ { break r false };
              };
            };
            case (5) {
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

  public shared({caller}) func setUserData(partitionId: ?Principal, _user: User) {
    let key = "u/" # Principal.toText(caller); // TODO: Should use binary encoding.
    // TODO: Add Hint to CanDBMulti
    ignore await CanDBIndex.putAttributeNoDuplicates("user", {
        sk = key;
        key = "u";
        value = serializeUser(_user);
      },
    );
  };

  // TODO: Should also remove all his/her items?
  public shared({caller}) func removeUser(canisterId: Principal) {
    var db: CanDBPartition.CanDBPartition = actor(Principal.toText(canisterId));
    let key = "u/" # Principal.toText(caller);
    await db.delete({sk = key});
  };
}