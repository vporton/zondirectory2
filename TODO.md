- Optimize Makefile.

- Test (not) adding duplicate entry.

- https://onramper.com to buy ICP

- Not to lose post's text if the network fails.

- Special stream where all the posted items are added.
  FIXME: This stream requires a separate max. number of items than other streams.

- Give investors 15% of the PST, using a blockchain launchpad.
  Preserve some PST in rewards fund, make rewards through a DEX.

- Counting number of logged-in users, number of items of various kinds.

- Download a backup of author's items.

- Don't reload items list when voting not in Voting stream.

- When switching from item view to folders list view, preserve t/v/p radiobuttons value.
  Moreover, store this value in a cookie or local storage.

- Slow loading of vote results.

- One folder having several editors, like as in Dmoz.

- Race conditions of reading an entry and saving it with a modified subkey.
  Solve by blocking by setting a special attribute.
  But how to reset it reliably?
  The best solution is to move the code to `NacDBPartition` (it can grow 7 times).

- "Waiting" overlay widget.

- Can a folder be a comment?

- Option for an owned folder to be ordered by voting?

- Before deleting an item, delete all links between it and folders.

- Transforming owned folders to communal.

- Ask users for phone/email (optionally), for feedback.

- Logout on page reload shouldn't happen.

- Join one communal folder to another by a community voting.

- Prefix text with format specifier (like `text/plain`). Render markdown at client side.

- Proper error handling.

- Note that an item was edited if it was edited since inception.

- Check what happens if adding an item to a directory twice.

- Rename categories to folders also in Motoko source.

- Q/A site features like Quora.

- why don't you use the TS library that @CanScale wrote for upgrades? I normally use that and it has everything you need. Take a look at the Hello CanDB with upgrades ==> https://github.com/ORIGYN-SA/hello-candb/tree/beta/extended_examples/hello_world_with_upgrades
For other projects I have use this library that let you write command line (DFX commands) in a JS type. Take a look: https://github.com/google/zx
Take a look at this example ==> https://gist.github.com/atengberg/7a698218112615517969247f762d92fd --
https://discord.com/channels/990830443521789952/999858362932006984/1157676585802023012

- Remove `candb-client-typescript`.

- No more than one communal category with a given name + locale (requires a centralized registry).
  Locale should be displayed.

- `lib.encodeInt` produces too long identifiers.

- Prevent duplicated messages (how to organize the DB of hashes in multiple canisters?)

- Prevent making a folder its own subfolder.

- It seems that `CanDB{Index,Partition}` have superfluous (not used) shared functions.

- Unittests for (de)serialize.

- Llama-2 canister for moderation.
  https://forum.dfinity.org/t/llama2-c-llm-running-in-a-canister/21991?u=ang

- Keep statistics: How (total and daily) many items a user posted, how much his/her items were upvoted, etc.

- Repeating failed NacDB and other operations.

- Use https://github.com/aviate-labs/encoding.mo for base-32/base64 instead of my hex encoding?

- The CycleOps team has built https://cycleops.dev/ to power automated cycles top-ups with notifications for IC applications.

- Calculate the amount of cycles to upload to every canister.

- [Accept cycles from a wallet](https://internetcomputer.org/docs/current/developer-docs/backend/motoko/simple-cycles).

- `canister_inspect_message`: https://internetcomputer.org/docs/current/motoko/main/message-inspection.
  Also rate-limit API.

- Improve performance by using `var` in structs to write directly to a struct rather than to intermediary variables.

- Payments with other tokens than IPC.

- Google Analytics

- https://github.com/dfinity/sdk/blob/master/CHANGELOG.md (`dfx deps`)

- Remove superfluous imports.

- `StableBuffer` vs `stable-buffer`.

- Consider re-partitioning CanDB to avoid too much parallelism.
