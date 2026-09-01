# 2. Core Concepts

## Why a "table format" at all?

A raw directory of Parquet files has no agreed-upon idea of "what's the
current state of this table." Two engines listing the same directory at
the same moment can see different files if a write is in progress. Iceberg
fixes this by never mutating existing files or listings in place — every
change produces new metadata that atomically replaces a single pointer.

## Snapshots

Every write — insert, update, delete, schema change, even a compaction —
produces a new **snapshot**: a new metadata file, a new manifest list, and
(usually) new manifest/data files, without touching anything from previous
snapshots.

This buys you three things directly:

- **Time travel** — query the table as it looked at any prior snapshot.
- **Rollback** — point the table back at a prior snapshot if a bad write
  needs undoing, without restoring from backup.
- **Isolation** — a reader that started before a commit keeps seeing the
  pre-commit snapshot for the whole query, even if a write commits midway
  through; a writer's in-progress snapshot is invisible to everyone else
  until the commit succeeds.

```sql
-- list every snapshot for a table
SELECT * FROM local.db.employees.snapshots;

-- travel back to a specific snapshot id
SELECT * FROM local.db.employees VERSION AS OF 8947839283579;

-- travel back to a specific point in time
SELECT * FROM local.db.employees TIMESTAMP AS OF '2024-01-01 00:00:00';

-- roll the table back
CALL local.system.rollback_to_snapshot('db.employees', 8947839283579);
```

## Schema evolution

Adding, dropping, renaming, reordering, or widening a column's type is a
**metadata-only** operation — no data file is rewritten. This works because
every field (including nested struct fields) gets a permanent integer
**field ID** the moment it's created. Readers map columns by field ID, not
by name or position, so:

- Renaming a column doesn't break old files — they still resolve the field
  by ID, just now displayed under the new name.
- Reordering columns in a `SELECT *` doesn't require touching data.
- Dropping a column just means new snapshots stop populating that field ID;
  old files' data for it becomes unreachable but the files themselves don't
  need rewriting.

```sql
ALTER TABLE local.db.employees ADD COLUMN salary INT;
ALTER TABLE local.db.employees RENAME COLUMN name TO full_name;
ALTER TABLE local.db.employees ALTER COLUMN salary TYPE BIGINT;
ALTER TABLE local.db.employees DROP COLUMN salary;
```

## Partitioning and partition evolution

A partition spec is a list of **transforms** applied to source columns:

| Transform | Behavior |
|---|---|
| `identity` | Partition by the raw column value |
| `bucket(N, col)` | Hash `col` into `N` buckets — good for high-cardinality columns where you want an even spread |
| `truncate(L, col)` | Group by the first `L` characters/digits of `col` |
| `year(col)` / `month(col)` / `day(col)` / `hour(col)` | Partition a timestamp at the chosen granularity |

Unlike Hive-style partitioning, a table's partition spec can **change over
time** without rewriting existing data:

```sql
ALTER TABLE local.db.employees ADD PARTITION FIELD month(hire_date);
-- later, decide daily granularity is better going forward:
ALTER TABLE local.db.employees REPLACE PARTITION FIELD month(hire_date) WITH day(hire_date);
```

Old data files keep whatever spec they were written under; the query
planner is spec-aware and plans correctly across a table with multiple
historical partition specs in play at once.

## Manifests: why Iceberg scans less data than a Hive table

Instead of listing a directory to find files, an engine reads:

1. The **metadata file** → get the pointer to the current snapshot's
   manifest list.
2. The **manifest list** → get the set of manifest files for this
   snapshot.
3. Each **manifest file** → per-data-file stats: file path, partition
   values, row count, and column-level min/max values.

A query with a `WHERE` filter can discard whole data files at step 3 using
those min/max stats — before opening a single Parquet footer. That's the
main reason Iceberg tables often outperform equivalent Hive/Parquet tables
at scale: partition pruning *and* file-level statistics pruning, both from
metadata that's cheap to read compared to a filesystem listing.

## Next

[Architecture](03-architecture.md) walks through exactly which files get
written to disk when you run the commands above.
