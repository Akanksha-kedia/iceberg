# 10. Comparisons

## Iceberg vs. Delta Lake

| | Iceberg | Delta Lake |
|---|---|---|
| Data file formats | Parquet, ORC, Avro | Parquet |
| Change log | Metadata/manifest tree (JSON + Avro) | JSON commit log + periodic Parquet checkpoints |
| Partition evolution | Yes, without rewriting existing data | Historically required a rewrite; improving with liquid clustering |
| Primary engine | Engine-agnostic by design (Spark, Flink, Trino, Hive, ...) | Spark-first; multi-engine support (via Delta Kernel/UniForm) growing |
| Catalog options | Hive, Glue, JDBC, REST, Nessie | Historically Databricks/Hive-centric; Unity Catalog now speaks the Iceberg REST protocol too |
| ACID | Yes | Yes |
| Row-level deletes (v2) | Merge-on-read delete files | Deletion vectors |

Rule of thumb: reach for Iceberg by default when multiple engines need to
read/write the same tables without a single vendor gatekeeping the
integration; Delta Lake remains a strong default in Spark/Databricks-first
pipelines, and the two ecosystems have been converging (Delta's UniForm,
Databricks' Unity Catalog exposing an Iceberg REST endpoint, Databricks'
2024 acquisition of Tabular — one of Iceberg's original creators).

## Iceberg vs. Apache Hudi

| | Iceberg | Hudi |
|---|---|---|
| Design center | Engine-agnostic table spec, strong read compatibility | Low-latency upserts with its own indexing + compaction service |
| Write model | Copy-on-write or merge-on-read (delete files) | Copy-on-write or merge-on-read (its own log format) |
| Indexing | None built-in — pruning comes from manifest stats | Built-in record-level index for fast point lookups/upserts |
| Best fit | Analytical tables read by many engines | CDC-heavy ingestion with frequent upserts and a need for fast point lookups |

Both are viable for CDC-style ingestion. If the workload is upsert-heavy
with a need for fast point lookups by key, Hudi's indexing is a real
advantage; if read compatibility across many query engines matters more
than upsert latency, Iceberg is the simpler choice.

## When *not* to reach for a table format at all

Small, rarely-changing datasets that fit comfortably in a single file (or a
handful of files) don't need any of this — the operational overhead of
snapshots/manifests/catalogs isn't buying you anything a plain Parquet
file or a regular database table wouldn't already give you. Table formats
earn their complexity at the scale where directory listings, partition
management, and safe concurrent writes become genuinely hard problems on
their own.

## Next

[FAQ](11-faq.md) for specific questions this comparison tends to raise.
