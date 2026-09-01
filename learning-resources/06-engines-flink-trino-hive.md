# 6. Flink, Trino, Hive

## Flink

```sql
CREATE CATALOG rest_catalog WITH (
  'type' = 'iceberg',
  'catalog-impl' = 'org.apache.iceberg.rest.RESTCatalog',
  'uri' = 'http://localhost:8181',
  'warehouse' = 's3://warehouse'
);

USE CATALOG rest_catalog;

CREATE TABLE db.employees (id INT, name STRING) WITH ('format-version' = '2');

INSERT INTO db.employees VALUES (14, 'james'), (15, 'john');

-- streaming read starting from the current snapshot
SELECT * FROM db.employees /*+ OPTIONS('streaming'='true','monitor-interval'='10s') */;
```

`format-version = '2'` enables row-level deletes (`UPDATE`/`DELETE` write a
delete file instead of rewriting the whole data file), which most
streaming-write pipelines rely on. Flink is commonly used as the *writer*
into an Iceberg table (continuous ingestion), while batch engines like
Spark/Trino do the heavy analytical reads.

## Trino

Trino has no Iceberg-specific runtime to install — the catalog is a plain
properties file:

```properties
# etc/catalog/iceberg.properties
connector.name=iceberg
iceberg.catalog.type=rest
iceberg.rest-catalog.uri=http://localhost:8181
iceberg.rest-catalog.warehouse=s3://warehouse
```

```sql
CREATE TABLE iceberg.db.employees (id INTEGER, name VARCHAR)
WITH (format = 'PARQUET', partitioning = ARRAY['bucket(id, 8)']);

SELECT * FROM iceberg.db.employees FOR VERSION AS OF 8947839283579;
SELECT * FROM iceberg.db.employees FOR TIMESTAMP AS OF TIMESTAMP '2024-01-01 00:00:00';

CALL iceberg.system.rewrite_data_files('db', 'employees');
```

## Hive

Iceberg tables are queryable from Hive via `HiveIcebergStorageHandler`:

```sql
CREATE TABLE db.employees (id INT, name STRING)
STORED BY ICEBERG
TBLPROPERTIES ('iceberg.catalog'='hive_catalog');

INSERT INTO db.employees VALUES (14, 'james'), (15, 'john');
```

This is the path most relevant if you're migrating an existing
Hive-Metastore-backed warehouse to Iceberg incrementally — tables can be
converted with `CALL system.migrate(...)` (Spark) while staying queryable
from Hive throughout.

## Picking an engine per job

| Job shape | Reasonable default |
|---|---|
| Continuous/streaming ingestion into a table | Flink |
| Interactive/ad-hoc SQL analytics | Trino/Presto |
| Batch ETL, heavier transformations, ML feature pipelines | Spark |
| Existing Hive-based BI tooling that must keep working during migration | Hive (via `HiveIcebergStorageHandler`) |

None of these are exclusive — the whole point of a shared table format is
that the same table is valid input/output for all four at once.

## Next

[Maintenance](07-maintenance-procedures.md) for keeping a table healthy
under sustained write load, regardless of which engine is writing.
