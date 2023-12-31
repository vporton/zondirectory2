## CanDB database structure

### "u/" - Principal -> User
- Attribute `"u"`: `"u"` - `User` record, `"v"` - Karma struct.
- (Unused) Attribute `"s"` - set to true if anti-sybil checking passed.
### "i/" - ID -> Item
- Attribute `"i"` - `Item` record.
- Attribute `"st"` (time), `"sv"` (votes), `"sp"` (paid) - `Streams` record.
- Attribute `"srt"` (time), `"srv"` (votes), `"srp"` (paid) - `Streams` record, reverse order.
- Attribute `"t"` - post's text.
TODO: Should have separate attribute post text.
### "a/" - user -> <buyer affiliate>/<seller affiliate>
### "v/<principal>/<parent>/<child>"
- Attribute `"v"` -  `#int +-1` - votes
### "w/<parent>/<child>"
- Attribute `"v"` - `#tuple [#int <VOTES UP>, #int <VOTES DOWN>]`

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

FIXME: The `time/time` relations need to be rewritten using `NacDBReorder` in order to
be deleteable.

Allowed number of votes:
- 10 per day
- additional 5 votes (not per day) for each message