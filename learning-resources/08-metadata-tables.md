# 8. Metadata Tables

Every Iceberg table exposes a family of read-only metadata tables, queryable
with plain SQL as `<catalog>.<db>.<table>.<metadata_table>`. These are the
fastest way to answer "what's actually going on with this table" without
external tooling.

## `snapshots`

```sql
SELECT * FROM local.db.employees.snapshots;
```

Columns: `committed_at`, `snapshot_id`, `parent_id`, `operation`
(`append`/`overwrite`/`delete`/`replace`), `manifest_list`, `summary` (a
map with things like `added-data-files`, `added-records`,
`total-data-files`).

## `history`

```sql
SELECT * FROM local.db.employees.history;
```

Columns: `made_current_at`, `snapshot_id`, `parent_id`, `is_current_ancestor`.
Distinguishes "this snapshot existed" from "this snapshot was ever the
table's current pointer" — relevant after a rollback, where a snapshot can
exist without being an ancestor of the current one.

## `files`

```sql
SELECT * FROM local.db.employees.files;
```

One row per data file **in the current snapshot**: `file_path`,
`file_format`, `record_count`, `file_size_in_bytes`, `column_sizes`,
`value_counts`, `null_value_counts`, `lower_bounds`, `upper_bounds`,
`partition`.

A quick compaction-need check:

```sql
SELECT count(*) AS file_count,
       sum(file_size_in_bytes) AS total_bytes,
       avg(file_size_in_bytes) AS avg_file_bytes
FROM local.db.employees.files;
```

A low `avg_file_bytes` with a high `file_count` relative to `total_bytes`
is the signature of needing `rewrite_data_files`
([Maintenance](07-maintenance-procedures.md)).

## `all_data_files`

Same shape as `files`, but across every snapshot, including files later
removed by compaction or row-level deletes. Useful for auditing what
`expire_snapshots`/`remove_orphan_files` would actually clean up.

## `manifests`

```sql
SELECT * FROM local.db.employees.manifests;
```

One row per manifest file in the current snapshot: `path`, `length`,
`partition_spec_id`, `added_data_files_count`, `existing_data_files_count`,
`deleted_data_files_count`.

## `partitions`

```sql
SELECT * FROM local.db.employees.partitions;
```

One row per distinct partition value present in the table: partition
column values, `record_count`, `file_count`, plus per-partition size stats.
Good for spotting a skewed partition (one partition with far more files/
rows than the rest) before it becomes a query hotspot.

## `refs`

```sql
SELECT * FROM local.db.employees.refs;
```

Branches and tags (if any are in use) with their current snapshot and
retention settings — most relevant on catalogs that support branching,
like Nessie, or when using Iceberg's branch/tag APIs directly.

## Next

[Data Types](09-data-types.md) for the full type system these tables'
column stats are built from.
