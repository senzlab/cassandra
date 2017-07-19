# cassandra with lucene

Dockerized cassandra with lucene plugin. The purpose of this cassandra project 
is to keep documents with full text serach functionality  

We are creating REST API againt this document storage. 

# cassandra usage

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

# REST API usage 

## API end points
```
dev.localhost:8080/api/v1/documents
dev.localhost:8080/api/v1/documents/1
dev.localhost:8080/api/v1/documents?name=eranga
```

## create document 
```
# http POST 
curl 
    -H "Content-Type: application/json" 
    -X POST http://localhost:8080/api/v1/documents 
    -d 
    '{
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

