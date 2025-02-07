## CanDB database structure

### "u/" - Principal -> User
- Attribute `"u"`: `"u"` - `User` record.
- Attribute `"v"` - `VotingInfo`.
- Attribute `"t"` user's time stream.
- Attribute `"p"` user's score.
### "e/" - Ethereum address -> Principal
- Attribute "p" - Principal
### "i/" - ID -> Item
- Attribute `"i"` - `Item` record.
- Attribute `"st"` (time), `"sv"` (votes) - `Streams` record.
- Attribute `"rst"` (time), `"rsv"` (votes) - `Streams` record, reverse order.
- Attribute `"t"` - post's text.
### "r/" - ID -> Virtual item
- Attribute `"i"` - `ItemVariant` record.
### "a/" - user -> <buyer affiliate>/<seller affiliate>
### "v/<principal>/<parent>/<child>"
- Attribute `"v"` -  `#int +-1` - votes
### "w/<parent>/<child>"
- Attribute `"v"` - `#tuple [#int <VOTES UP>, #int <VOTES DOWN>]`

### Variant votes:

For streams of variants re-voting up should remove the previous vote up.
We also should remove old up votes (after 15 new votes).
However, we should not remove old down votes.

### "b/<item>/<user>"
- attribute `"v"` - `ItemVariant` that was voted up
### "d/<item>/<user>/<item-variant>"
- attribute `"v"` - `()` (votes down)

## NacDB database structure
* time/time: folder -> sub-items
* time/time: folder -> sub-folders
* time/time: item -> comments
* votes/votes: folder -> sub-items
* votes/votes: folder -> sub-folders
* votes/votes: item -> comments

Allowed number of votes:

- unlimited

Allowed creation of child/parent relations

- 4 for each message, but not more than 20 total (to avoid market for accounts with many points)