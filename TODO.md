- Scalable architecture to store phone numbers for Sybil.

- Store the total number of likes of an item. It is needed to sort items when autocomplete.
  It should sort immediately when a new like is added/removed.

- Keep statistics: How (total and daily) many items a user posted, how much his/her items were upvoted, etc.

- Is an item considered as a folder for replies to it?

- We need separate order for subcategories and rest items.

- Store post text separately, not to retrieve/save it every time, when accessing an item.

- Should we differentiate between category items and comments to the category?

- Repeating failed NacDB and other operations.

- Use https://github.com/aviate-labs/encoding.mo for base-32/base64 instead of my hex encoding?

- Separate stream for each locale/language?

- Should we pay to owner of an owned category, if somebody purchased an ad in it?

- Offshift the modifications of objects to CanDB partition actors, to avoid (de)serialization.
  Use `AttributeMap` capabilities to avoid (de)serialization on every modification.

- Rename category -> folder.

- Should use owned or communal folder for comments stream of a post?

- The CycleOps team has built https://cycleops.dev/ to power automated cycles top-ups with notifications for IC applications.

- Calculate the amount of cycles to upload to every canister.

- [Accept cycles from a wallet](https://internetcomputer.org/docs/current/developer-docs/backend/motoko/simple-cycles).

- [`await*` vs `await`](https://forum.dfinity.org/t/what-is-await-with-asterisk/19887/4)

- `canister_inspect_message`: https://internetcomputer.org/docs/current/motoko/main/message-inspection.
  Also rate-limit API.

- The current code allows to write to an "alien" canister. Possible solution is to use one CanDB with key prefixes.

- Improve performance by using `var` in structs to write directly to a struct rather than to intermediary variables.

- Payments with other tokens than IPC.

- Google Analytics

- https://github.com/dfinity/sdk/blob/master/CHANGELOG.md (`dfx deps`)

- Remove superfluous imports.

- `StableBuffer` vs `stable-buffer`.

- Consider re-partitioning CanDB to avoid too much parallelism.

- Remove dependency on NacDB.
