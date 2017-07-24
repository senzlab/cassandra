# cassandra with lucene

Dockerized cassandra with lucene plugin. The purpose of this cassandra project
is to keep documents with full text serach functionality

We are creating REST API againt this document storage.

# cassandra usage

## create table
```sql
-- create keyspace with replication 1
CREATE KEYSPACE senz WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 1}

-- create keyspace with replication 3
CREATE KEYSPACE senz WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3}

-- create table
use senz
CREATE TABLE documents (id INT PRIMARY KEY, name TEXT, docType TEXT, date TEXT, partyName TEXT, orgNo TEXT, vatNo TEXT)
```

## search query
```sql
-- insert document
INSERT INTO documents (id, name, docType, date, partyName, orgNo, vatNO) VALUES (1, 'eranga', 'INVOICE', '2017/07/25', 'telia', '4422333', '783333')

-- search document
SELECT * from documents
SELECT * FROM documents where id = 1

-- this query will fail since no index for name
SELECT * FROM documents where name = 'eranga'
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
}
```

## lucene query
```sql
-- with one field match
SELECT * FROM documents WHERE expr(documents_index, '{
    query : {type:"match", field:"name", value:"eranga"}
}')

-- with multiple field match
SELECT * FROM documents WHERE expr(documents_index, '{
    query : [
        {type:"match", field:"name", value:"eranga"},
        {type:"match", field:"doctype", value:"invoice"}
    ]
}')

-- with wildcard filter
SELECT * FROM documents WHERE expr(documents_index, '{
    filter: [
        {type: "wildcard", field:"name", value:"eraga"},
        {type: "wildcard", field:"doctype", value:"INVOICE"},
        {type: "wildcard", field:"partyname", value:"*"},
        {type: "wildcard", field:"orgno", value:"*"}
    ]
}')
```

# REST API usage

## API end points
```
dev.localhost:8080/api/v1/documents
dev.localhost:8080/api/v1/documents/1
dev.localhost:8080/api/v1/documents?name=eranga
dev.localhost:8080/api/v1/documents?name=eraga&orgNo=6881
```

## create document
```
# http POST
curl \
    -H "Content-Type: application/json" \
    -X POST http://localhost:8080/api/v1/documents \
    -d '{
        "name": "telia",
        "id": 3,
        "date": "2017/08/13",
        "docType": "INVOICE",
        "partyInfo": {
            "id": 2,
            "name": "eranga",
            "orgNo": "688812",
            "vatNo": "231122"
        }
    }'
```
