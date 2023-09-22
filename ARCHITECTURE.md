## CanDB database structure

### "u/" - Principal -> User
- Attribute `"v"` - `User` record.
- Attribute `"s"` - set to true if anti-sybil checking passed.
### "i/" - ID -> Item
TODO: Should have separate attributes for: item info, post text, streams
### "a/" - user -> <buyer affiliate>/<seller affiliate>
### [TODO: seems superfluous] "r/<CATEGORY>/<ITEM>" - which items were addeded to which categories (both time and votes streams)

## Misc

TODO:
When creating a new user (`u/`) record, must reliably check that there are no
records for the same user before it.