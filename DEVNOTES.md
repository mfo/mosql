# TODO : rake notes

```
lib/mosql/row.rb:
  * [  2] [TODO] spec Row modeling
  * [ 28] [FIXME] safe loopup for pkey

lib/mosql/schema.rb:
  * [ 68] [TODO] spec build nested_schema
  * [105] [TODO] spec find nested primary key
  * [108] [TODO] spec serial primary key
  * [193] [TODO] spec fetch_nested_attribute
  * [194] [TODO] spec fetch parent value
  * [241] [TODO] spec row usage
  * [242] [TODO] spec usage with nested row
  * [243] [TODO] spec usage with
  * [244] [TODO] ensure skip serial & $timestamp [might refactor here]
  * [290] [TODO] spec row association
  * [325] [TODO] spec copy column skip $serial as well as $timestamp
  * [345] [TODO] spec usage of objs[Row...]
  * [399] [TODO] spec fin primary_sql_key_for_ns with AUTOINCREMENT [dedup code]

lib/mosql/sql.rb:
  * [ 29] [TODO] spec table for row
  * [ 34] [TODO] spec extract row extract is done with a Row

lib/mosql/streamer.rb:
  * [ 51] [TODO] spec cols zipping with rows
  * [132] [TODO] spec batch behaviour
```