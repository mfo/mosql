# TODO : rake notes

```
lib/mosql/row.rb:
  * [  2] [TODO] spec Row modeling
  * [ 28] [FIXME] safe loopup for pkey

lib/mosql/schema.rb:
  * [188] [TODO] spec fetch_nested_attribute
  * [189] [TODO] spec fetch parent value
  * [236] [TODO] spec row usage [ensure schema root/parent, ns root/parent etc...]
  * [316] [TODO] spec copy column skip $serial as well as $timestamp. Digg PG default sequence value
  * [336] [TODO] spec usage of objs[Row...]

lib/mosql/sql.rb:
  * [ 29] [TODO] spec table for row
  * [ 34] [TODO] spec extract row extract is done with a Row

lib/mosql/streamer.rb:
  * [ 51] [TODO] spec cols zipping with rows
  * [132] [TODO] spec batch behaviour
```

# Document : news props for nested schema

```
sharypic_development:
  events:
    :meta:
      :table: facts_event_creations
      :extra_props: false

    :columns:
    - dimensions_event_id:
      :source: _id
      :type: TEXT
    - dimensions_user_id:
      :source: owner_id
      :type: TEXT
    - created_at: DATE
    - updated_at: DATE

    :nested:
      invitations:
        :meta:
          :table: facts_invitations
          :extra_props: false

        :columns:
          - id:
            :source: '$serial'
            :type: 'SERIAL'
          - dimensions_event_id:
            :source: $parent id
            :type: TEXT
          - dimensions_invitation_id:
            :source: '$nested invitations[]._id'
            :type: TEXT
```