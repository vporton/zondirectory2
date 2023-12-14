## CanDB database structure

### "u/" - Principal -> User
- Attribute `"u"` - `User` record.
- (Unused) Attribute `"s"` - set to true if anti-sybil checking passed.
### "i/" - ID -> Item
- Attribute `"i"` - `Item` record.
- Attribute `"s"` - `Streams` record.
- Attribute `"t"` - post's text.
TODO: Should have separate attribute post text.
### "a/" - user -> <buyer affiliate>/<seller affiliate>
### [TODO: seems superfluous] "r/<CATEGORY>/<ITEM>" - which items were addeded to which categories (both time and votes streams)

## NacDB database structure
* time/time: category -> sub-items
* time/time: category -> sub-categories
* time/time: item -> comments
* votes/votes: category -> sub-items
* votes/votes: category -> sub-categories
* votes/votes: item -> comments
* paid/time: category -> sub-items
* paid/time: category -> sub-categories
* paid/time: item -> comments

The `time/time` relations need to be rewritten using `NacDBReorder` in order to
be deleteable.

## Misc

TODO:
When creating a new user (`u/`) record, must reliably check that there are no
records for the same user before it.