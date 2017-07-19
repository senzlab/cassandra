# cassandra with lucene

Dockerized cassandra with lucene plugin.  

# usage

## create table
```sql
-- create keyspace
CREATE KEYSPACE senz WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3};
use senz

-- create table
CREATE TABLE documents (id INT PRIMARY KEY, name TEXT, docType TEXT, date TEXT, partyName TEXT, orgNo TEXT, vatNo TEXT);
```

## create lucene index

```sql
CREATE CUSTOM INDEX documents_index ON documents ()
USING 'com.stratio.cassandra.lucene.Index'
WITH OPTIONS = {
   'refresh_seconds': '1',
   'schema': '{
      fields: {
         id: {type: "integer"},
         name: {type: "string"},
         doctype: {type: "string"},
         orgno: {type: "string"},
         partyname: {type: "string"}
      }
   }'
};
```

## query
```sql
-- with one field match
SELECT * FROM documents WHERE expr(documents_index, '{
    query : {type:"match", field:"name", value:"eranga"}
}');

-- with multiple field match
SELECT * FROM documents WHERE expr(documents_index, '{
    query : [
        {type:"match", field:"name", value:"eranga"},
        {type:"match", field:"doctype", value:"invoice"}
    ]
}');
```
