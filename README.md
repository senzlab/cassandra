# dockrize cassandra and lucene

Dockerized cassandra with lucene plugin. The purpose of this cassandra project
is achive full text serach via cassandra with the help of lucene plugin.

## build docker
```docker
docker build --tag erangaeb:cassandra:0.1 .
```

## run single cassandra 

```docker
docker run -d \
-p 9160:9160 \
-p 9042:9042 \
erangaeb/cassandra:0.1
```

## run cassandra cluser(same host)

```docker
# seed node
docker run -d \
--name c1 \
-p 9160:9160 \
-p 9042:9042 \
erangaeb/cassandra:0.1

# other nodes with seed parameter
docker run -d \
--name c2 \
-p 9170:9160 \
-p 9052:9042 \
-e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' c1)" \
erangaeb/cassandra:0.1

docker run -d \
--name c3 \
-p 9180:9160 \
-p 9062:9042 \
-e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' c1)" \
erangaeb/cassandra:0.1
```

## run cassandra cluser(multiple hosts)

```
# host1(seed node)  - 10.4.1.15
# host2             - 10.4.1.16
# host3             - 10.4.1.17

# host1 - seed node
docker run -d \
-e CASSANDRA_BROADCAST_ADDRESS=10.4.1.15 \
-p 7000:7000 \
-p 9042:9042 \
-p 9060:9060 \
erangaeb/cassandra:0.4

# host2 - normal node  
docker run -d \ 
-e CASSANDRA_BROADCAST_ADDRESS=10.4.1.16 \
-e CASSANDRA_SEEDS=10.4.1.15 \
-p 9042:9042 -p 7000:7000 \
-p 9060:9060 \
erangaeb/cassandra:0.4

# host3 - normal node  
docker run -d \ 
-e CASSANDRA_BROADCAST_ADDRESS=10.4.1.17 \
-e CASSANDRA_SEEDS=10.4.1.15 \
-p 9042:9042 -p 7000:7000 \
-p 9060:9060 \
erangaeb/cassandra:0.4
```

# cassandra usage

## create table
```sql
-- create keyspace with replication 1
CREATE KEYSPACE zchain WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 1}

-- create keyspace with replication 3
CREATE KEYSPACE zchain WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3}

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

# cassandra with lucene

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


SELECT * FROM documents WHERE expr(documents_index, '{
    filter: [
        {type: "wildcard", field:"auth_company_id", value:"pagero"},
        {type: "wildcard", field:"document_identifier", value:"INVOICE"}
    ]
}')
```

## lucene with user define types
```sql
-- create address type
CREATE TYPE address (
    country TEXT,
    country_code TEXT,
    town TEXT
)

-- create table with address
CREATE TABLE documents (
    id TEXT PRIMARY KEY,
    name TEXT,
    doctype TEXT,
    sender_address frozen <address>
)

-- create lucene index with udt
CREATE CUSTOM INDEX documents_index ON documents ()
USING 'com.stratio.cassandra.lucene.Index'
WITH OPTIONS = {
   'refresh_seconds': '1',
   'schema': '{
      fields: {
         "id": {type: "integer"},
         "name": {type: "string"},
         "doctype": {type: "string"},
         "sender_address.country": {type: "string"},
         "sender_address.town": {type: "string"}
      }
   }'
}

-- insert data
INSERT INTO documents (id, name, doctype, sender_address) VALUES ('3', 'eranga', 'INVOICE', {country: 'sweden', town: 'goth'})

-- lucen search with udt
SELECT * FROM documents WHERE expr(documents_index, '{
    filter: [
        {type: "wildcard", field:"name", value:"eranga"},
        {type: "wildcard", field:"doctype", value:"INVOICE"},
        {type: "wildcard", field:"sender_address.country", value:"sweden"}
    ]
}')
```
