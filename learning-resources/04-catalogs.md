# 4. Catalogs

All examples use Spark's `spark.sql.catalog.<name>.*` property namespace;
the same underlying properties carry over to Flink's `CREATE CATALOG` and
Trino's `etc/catalog/*.properties` (see
[Flink, Trino, Hive](06-engines-flink-trino-hive.md)).

## Hadoop catalog — simplest, filesystem-only

```
spark.sql.catalog.local = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.local.type = hadoop
spark.sql.catalog.local.warehouse = file:///tmp/iceberg-warehouse
```

Good for local dev and this repo's `scripts/` playground. Not safe for
concurrent writers across separate processes/machines — atomicity relies on
the filesystem's rename semantics, which object stores like plain S3
historically didn't guarantee (S3 has since added conditional writes that
close this gap, but it's still not the default recommendation for
production multi-writer setups).

## Hive Metastore catalog

```
spark.sql.catalog.hive_cat = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.hive_cat.type = hive
spark.sql.catalog.hive_cat.uri = thrift://<hms-host>:9083
spark.sql.catalog.hive_cat.warehouse = hdfs:///warehouse/tablespace/managed/hive
```

Tables are stored as Hive Metastore table entries tagged
`table_type=ICEBERG`, so table-listing tools that only understand Hive
still see them; only Iceberg-aware engines read/write them correctly.

## AWS Glue catalog

```
spark.sql.catalog.glue_cat = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.glue_cat.catalog-impl = org.apache.iceberg.aws.glue.GlueCatalog
spark.sql.catalog.glue_cat.warehouse = s3://<bucket>/warehouse
spark.sql.catalog.glue_cat.io-impl = org.apache.iceberg.aws.s3.S3FileIO
```

## JDBC catalog

```
spark.sql.catalog.jdbc_cat = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.jdbc_cat.catalog-impl = org.apache.iceberg.jdbc.JdbcCatalog
spark.sql.catalog.jdbc_cat.uri = jdbc:postgresql://<host>:5432/iceberg_catalog
spark.sql.catalog.jdbc_cat.jdbc.user = <user>
spark.sql.catalog.jdbc_cat.jdbc.password = <password>
spark.sql.catalog.jdbc_cat.warehouse = s3://<bucket>/warehouse
```

Any JDBC-reachable database becomes the pointer store — useful when you
want a real transactional catalog without standing up Hive Metastore or the
REST catalog service.

## REST catalog

```
spark.sql.catalog.rest_cat = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.rest_cat.catalog-impl = org.apache.iceberg.rest.RESTCatalog
spark.sql.catalog.rest_cat.uri = http://localhost:8181
spark.sql.catalog.rest_cat.warehouse = s3://warehouse
```

The REST catalog spec is engine-agnostic by design — this is the
integration point most managed catalog platforms expose (Iceberg's
reference REST server, and REST-compatible catalogs from various vendors),
so one config often works unchanged across Spark, Flink, and Trino. The
`scripts/docker-compose.yml` playground in this folder runs the reference
REST catalog server against MinIO.

## Nessie catalog

```
spark.sql.catalog.nessie_cat = org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.nessie_cat.catalog-impl = org.apache.iceberg.nessie.NessieCatalog
spark.sql.catalog.nessie_cat.uri = http://<nessie-host>:19120/api/v2
spark.sql.catalog.nessie_cat.ref = main
spark.sql.catalog.nessie_cat.warehouse = s3://<bucket>/warehouse
```

Adds git-like branches/tags across the whole catalog (not just one table),
which makes multi-table transactions and "test a pipeline change on a
branch before merging to main" workflows possible.

## Choosing one

| If you need... | Use |
|---|---|
| Quick local testing, single process | Hadoop |
| Already running Hive Metastore | Hive |
| On AWS, want managed catalog | Glue |
| Have a database, no interest in standing up Hive/REST | JDBC |
| Multi-engine, vendor-neutral | REST |
| Multi-table transactions / branching workflows | Nessie |

## Next

[Spark](05-engines-spark.md) for the DataFrame API and the SQL extension
procedures.
