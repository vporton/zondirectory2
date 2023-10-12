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
* `itemsTimeOrder`: category -> sub-items
* `categoriesTimeOrder`: category -> sub-categories, item -> replies
* `categoriesInvTimeOrder`: category -> super-categories, reply -> items (to be implemented)

## Misc

TODO:
When creating a new user (`u/`) record, must reliably check that there are no
records for the same user before it.