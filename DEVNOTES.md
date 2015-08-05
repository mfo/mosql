# TODO : rake notes

```
lib/mosql/row.rb:
  * [  2] [TODO] spec Row modeling
  * [ 33] [FIXME] safe loopup for pkey

lib/mosql/schema.rb:
  * [187] [TODO] spec fetch_nested_attribute
  * [188] [TODO] spec fetch parent value
  * [235] [TODO] spec row usage [ensure schema root/parent, ns root/parent etc...]
  * [315] [TODO] spec copy column skip $serial as well as $timestamp. Digg PG default sequence value
  * [335] [TODO] spec usage of objs[Row...]

lib/mosql/sql.rb:
  * [ 29] [TODO] spec table for row
  * [ 34] [TODO] spec extract row extract is done with a Row
  * [ 39] [TODO] spec upsert nested rows

lib/mosql/streamer.rb:
  * [117] [TODO] spec & doc priority collection mgmt
  * [136] [TODO] spec batch behaviour
```

# Document : news props for nested schema

```

development_db_name:
  events:
    :meta:
      :table: facts_event_creations
      :extra_props: false
      :priority: 1
  
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
          :priority: 2
  
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