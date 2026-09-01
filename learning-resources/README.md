# Iceberg Learning Resources

A self-contained set of docs and runnable scripts for learning Apache
Iceberg hands-on, from "what is a table format" to running real Spark SQL
against a local REST catalog + MinIO stack.

## Docs

1. [Getting Started](01-getting-started.md) — install, build, and your first table
2. [Core Concepts](02-core-concepts.md) — metadata, snapshots, schema/partition evolution
3. [Architecture](03-architecture.md) — catalog → metadata → manifest → data file
4. [Catalogs](04-catalogs.md) — Hadoop, Hive, Glue, JDBC, REST, Nessie configs
5. [Spark](05-engines-spark.md) — SQL extensions, DataFrame API, procedures
6. [Flink, Trino, Hive](06-engines-flink-trino-hive.md) — other engine integrations
7. [Maintenance](07-maintenance-procedures.md) — compaction, snapshot expiry, orphan file cleanup
8. [Metadata Tables](08-metadata-tables.md) — introspecting a table with plain SQL
9. [Data Types](09-data-types.md) — type reference, field IDs, nested types
10. [Comparisons](10-comparisons.md) — Iceberg vs. Delta Lake vs. Hudi
11. [FAQ](11-faq.md)

## Scripts

`scripts/` has a runnable local playground: a `docker-compose.yml` bringing
up MinIO (S3-compatible storage) and an Iceberg REST catalog, plus SQL and
Python scripts that exercise the concepts in the docs above against that
stack. See `scripts/README.md` for how to run it.
