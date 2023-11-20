- Counting number of logged-in users, number of items of various kinds.

- One folder having several editors, like as in Dmoz.

- Race conditions of reading an entry and saving it with a modified subkey.
  Solve by blocking by setting a special attribute.
  But how to reset it reliably?
  The best solution is to move the code to `NacDBPartition` (it can grow 7 times).

- Can a folder be a comment?

- Before deleting an item, delete all links between it and folders.
  All folder/item relations should be reflexive.

- Transforming owned folders to communal.

- Shows a wrong logged-in user's principal.

- Logout on page reload shouldn't happen.

- FIXME in NacDB.

- Join one communal folder to another by a community voting.

- Proper error handling.

- Note that an item was edited if it was edited since inception.

- Check what happens if adding an item to a directory twice.

- Rename categories to folders also in Motoko source.

- Make `init()` methods callable only from the founder account.

- Create items under logged in user, not `defaultAgent`.

- Show "loading" widget, while loading a page.

- Q/A site features like Quora.

- FIXME: calling shared functions of index from partition (NacDB)?

- why don't you use the TS library that @CanScale wrote for upgrades? I normally use that and it has everything you need. Take a look at the Hello CanDB with upgrades ==> https://github.com/ORIGYN-SA/hello-candb/tree/beta/extended_examples/hello_world_with_upgrades
For other projects I have use this library that let you write command line (DFX commands) in a JS type. Take a look: https://github.com/google/zx
Take a look at this example ==> https://gist.github.com/atengberg/7a698218112615517969247f762d92fd --
https://discord.com/channels/990830443521789952/999858362932006984/1157676585802023012

- `checkSybil` should prevent even on localhost to authenticate.

- Remove `candb-client-typescript`.

- Deploy partition canisters from `Makefile`.

- Locale-specific streams.

- No more than one communal category with a given name + locale (requires a centralized registry).
  Locale should be displayed.

- `lib.encodeInt` produces too long identifiers.

- Prevent duplicated messages (how to organize the DB of hashes in multiple canisters?)

- Prevent making a folder its own subfolder.

- It seems that `CanDB{Index,Partition}` have superfluous (not used) shared functions.

- Unittests for (de)serialize.

- Llama-2 canister for moderation.
  https://forum.dfinity.org/t/llama2-c-llm-running-in-a-canister/21991?u=ang

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
