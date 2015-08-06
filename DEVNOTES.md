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

# Mongo Replicaset

## How To Replset [2.14]

http://docs.mongodb.org/v2.4/reference/replica-configuration/

## Create mongo conf files:

### vi /usr/local/etc/mongod.conf
```
dbpath = /usr/local/var/mongodb

# Append logs to /usr/local/var/log/mongodb/mongo.log
logpath = /usr/local/var/log/mongodb/mongo.log
logappend = true

# Only accept local connections
bind_ip = 127.0.0.1
port = 27017

fork = true
replSet = rs0
```

### vi /usr/local/etc/mongod_replset.conf
```
dbpath = /usr/local/var/mongodb/rset

bind_ip = 127.0.0.1
port = 27018

replSet = rs0
fork = true

logpath = /usr/local/var/log/mongodb/rset.log
logappend = true
```

## run processes
```
$ mongod --config /usr/local/etc/mongo.conf
$ mongod --config /usr/local/etc/mongod_replset.conf
```

## Setup replset in mongo conosle
```
$ mongo
> var rsconfig = {"_id":"rs0","members":[{"_id":1,"host":"127.0.0.1:27017"},{"_id":2,"host":"127.0.0.1:27018"}]};
> rs.initiate(rsconfig);
```
