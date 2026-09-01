# 11. FAQ

**Does Iceberg support nested data (structs, arrays, maps)?**
Yes, natively, including schema evolution on nested fields — adding a field
inside a struct is still a metadata-only change. See
[Data Types](09-data-types.md).

**How does Iceberg handle concurrent writers?**
Optimistic concurrency: a writer builds its new metadata file against a
known base snapshot, then attempts an atomic compare-and-swap of the
catalog's pointer. If another writer's commit landed first, the losing
writer retries by rebasing onto the new current snapshot instead of
overwriting it. See [Architecture](03-architecture.md).

**Is Iceberg always faster than a plain Hive/Parquet table?**
For anything with a meaningful number of partitions or files, usually yes
— pruning happens from manifest-file statistics instead of a filesystem
listing, and it can prune on column min/max values a directory structure
alone can't express. For a tiny, single-file table the difference is
negligible either way.

**Is Iceberg tied to a particular cloud or storage system?**
No — it needs a `FileIO` implementation for wherever the data lives (S3,
GCS, ADLS, HDFS, local disk) and a catalog for the metadata pointer. See
[Catalogs](04-catalogs.md).

**Can a schema change happen with zero downtime?**
Yes — schema changes are metadata-only commits. Readers and writers are
never blocked, and in-flight queries keep the schema/snapshot they started
with.

**What happens if a write job crashes mid-write?**
Nothing — it never got far enough to swap the catalog pointer, so the
table's current snapshot is unaffected. The half-written data/manifest
files it left behind become orphans, cleaned up later by
`remove_orphan_files` ([Maintenance](07-maintenance-procedures.md)).

**Does Iceberg have its own access control?**
No — access control is delegated entirely to what's underneath: the
catalog (Hive Metastore/Glue/REST authorization) and the storage layer (S3
bucket policy, HDFS ACLs, etc.). Iceberg has no separate permission model
of its own.

**Do I need Spark to use Iceberg?**
No — [PyIceberg](https://py.iceberg.apache.org/) reads (and increasingly
writes) Iceberg tables without any JVM at all, and there are Go, Rust, and
C++ implementations too. Spark/Flink/Trino/Hive are the common *engines*
for querying/writing, not a requirement of the format itself.

**How do I know if a table needs maintenance?**
Query its [metadata tables](08-metadata-tables.md) — `files` for file-size/
count health, `snapshots`/`history` for how much historical state has
piled up. See [Maintenance](07-maintenance-procedures.md) for the specific
procedures and a suggested schedule.

**Where does this leave Delta Lake and Hudi?**
All three solve the same core problem (safe, ACID, evolvable tables over
files in a data lake) with different design centers — see
[Comparisons](10-comparisons.md).
