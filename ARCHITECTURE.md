## CanDB database structure

### "u/" - Principal -> User
- Attribute `"u"`: `"u"` - `User` record.
- Attribute `"v"` - `VotingInfo`.
### "i/" - ID -> Item
- Attribute `"i"` - `Item` record.
- Attribute `"st"` (time), `"sv"` (votes) - `Streams` record.
- Attribute `"srt"` (time), `"srv"` (votes) - `Streams` record, reverse order.
- Attribute `"t"` - post's text.
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

Allowed number of votes:
- 10 per day
- additional 5 votes (not per day) for each message