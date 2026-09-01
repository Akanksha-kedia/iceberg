# 7. Maintenance

Iceberg tables under sustained write load accumulate two things that need
periodic cleanup: small files (from many small commits) and old snapshots
(from time-travel/rollback retention). Neither is automatic by default.

## Compaction: `rewrite_data_files`

```sql
CALL local.system.rewrite_data_files(table => 'db.employees');

-- sort-based compaction, useful when queries filter/sort on a specific column
CALL local.system.rewrite_data_files(
  table => 'db.employees',
  strategy => 'sort',
  sort_order => 'id ASC NULLS LAST'
);

-- bound how large a rewrite job gets, useful for very large tables
CALL local.system.rewrite_data_files(
  table => 'db.employees',
  options => map('max-file-group-size-bytes', '1073741824')
);
```

Symptom that tells you it's time to run this: a high row count in
`SELECT * FROM db.employees.files` relative to total data size — many
small files instead of a few appropriately-sized ones.

## Manifest compaction: `rewrite_manifests`

```sql
CALL local.system.rewrite_manifests(table => 'db.employees');
```

As snapshots accumulate, manifests can fragment too, which slows down
query *planning* (not execution) since more manifest files must be read to
build a scan plan. This is cheaper to run than `rewrite_data_files` and
worth scheduling more frequently.

## Snapshot expiry: `expire_snapshots`

```sql
CALL local.system.expire_snapshots(
  table => 'db.employees',
  older_than => TIMESTAMP '2024-01-01 00:00:00',
  retain_last => 10
);
```

Removes snapshot metadata (and any data/manifest files no longer
referenced by a remaining snapshot) older than the cutoff. `retain_last`
guarantees a minimum number of recent snapshots survive regardless of age,
so you don't accidentally lose the ability to roll back a very recent bad
write.

## Orphan file cleanup: `remove_orphan_files`

```sql
CALL local.system.remove_orphan_files(
  table => 'db.employees',
  older_than => TIMESTAMP '2024-01-01 00:00:00'
);
```

Deletes files sitting in the table's data directory that no snapshot
references at all — typically leftovers from a job that wrote files then
failed before committing. The `older_than` filter avoids deleting files
from a write that's still in flight.

## A reasonable default schedule

| Task | Frequency | Why |
|---|---|---|
| `rewrite_data_files` | Daily, or after each large batch load | Keep file sizes in a healthy range for scan performance |
| `rewrite_manifests` | Daily | Keep planning fast as snapshot count grows |
| `expire_snapshots` | Weekly, with a retention window matching your rollback needs | Bound storage growth from historical snapshots |
| `remove_orphan_files` | Weekly, after `expire_snapshots` | Clean up files that snapshot expiry alone won't catch |

`scripts/sql/maintenance.sql` in this folder has a runnable version of all
four against the local playground, with realistic-looking data to compact.

## Next

[Metadata Tables](08-metadata-tables.md) for how to check whether any of
this is actually needed before you run it.
