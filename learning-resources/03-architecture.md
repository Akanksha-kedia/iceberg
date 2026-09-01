# 3. Architecture

```
Catalog  →  Metadata file (vN.metadata.json)  →  Manifest list (snap-*.avro)  →  Manifest files (*.avro)  →  Data files (*.parquet / *.orc / *.avro)
```

## Catalog

The catalog's only job is to hold a **single, atomically-updatable pointer**
from a table identifier to its current metadata file. Every commit is:

1. Read the current metadata file (via the catalog's pointer).
2. Build a brand-new metadata file reflecting the change (new snapshot,
   new schema, new partition spec — whatever changed), referencing the
   previous metadata file as its parent.
3. Ask the catalog to atomically swap its pointer from the old metadata
   file to the new one, conditioned on the pointer still being what was
   read in step 1 (optimistic concurrency).

If step 3 fails because someone else committed first, the writer retries
from step 1 against the new current state — it does not silently overwrite
the other writer's commit.

Catalog implementations differ in *how* they store that pointer (a Hive
Metastore row, a DynamoDB/Glue entry, a row in a JDBC table, a Nessie
commit, a file in the REST catalog's backing store) but the contract is
identical, which is what lets the same table be read by Spark, Flink, and
Trino simultaneously without stepping on each other.

## Metadata file

A JSON document containing:

- `schema` (current, plus every historical schema by ID)
- `partition-spec` (current, plus every historical spec by ID)
- `current-snapshot-id`
- `snapshots` — list of `{snapshot-id, timestamp-ms, manifest-list, parent-snapshot-id, summary}`
- `properties` — table-level config (target file size, compression, etc.)

## Manifest list

An Avro file listing every **manifest file** that belongs to one snapshot,
with a summary per manifest (added/existing/deleted file counts, partition
value ranges covered). This is the first thing an engine reads after
resolving the metadata file's current snapshot — it decides which manifest
files are even worth opening for a given query's filters.

## Manifest files

Avro files, one row per data file, containing:

- File path, file format, file size
- Partition values for that file
- Row count
- Per-column value counts, null counts, and min/max bounds

This is where file-level pruning happens — a manifest entry whose
column min/max can't possibly satisfy a query's `WHERE` clause means the
corresponding data file is skipped entirely, without opening it.

## Data files

Plain Parquet, ORC, or Avro files — Iceberg imposes no format of its own on
the actual rows. A single table can mix formats across snapshots (e.g. if
you migrate an existing ORC Hive table into Iceberg and later write new
data as Parquet); the manifest entry for each file records its format so
readers know how to open it.

## Putting it together: one `INSERT`

Running `INSERT INTO local.db.employees VALUES (14, 'james')` does, in
order:

1. Write a new Parquet data file with that row.
2. Write a new manifest file listing that data file (plus, depending on
   the commit's manifest-merge settings, either references to prior
   manifests or newly rewritten ones).
3. Write a new manifest list referencing that manifest (and any carried-
   forward manifests from the previous snapshot).
4. Write a new metadata file whose `current-snapshot-id` points at a new
   snapshot entry referencing that manifest list.
5. Atomically swap the catalog's pointer to the new metadata file.

Nothing from before step 1 was modified — which is exactly why time
travel and rollback are just "point the catalog pointer somewhere else,"
not a data-copying operation.

## Next

[Catalogs](04-catalogs.md) covers the concrete configuration for each
catalog implementation mentioned above.
