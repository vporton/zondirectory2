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