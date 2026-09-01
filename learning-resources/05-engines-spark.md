# 5. Spark

## Enabling the SQL extensions

Most of what makes Iceberg pleasant in Spark SQL — `ALTER TABLE ... ADD
PARTITION FIELD`, time travel syntax, the `CALL` procedures below — comes
from Iceberg's Spark SQL extensions, not Spark itself:

```
spark.sql.extensions = org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
```

Without it, you still get basic `CREATE TABLE ... USING iceberg` and
`INSERT`/`SELECT`, but not the Iceberg-specific DDL/procedures.

## Two catalog implementations

- `org.apache.iceberg.spark.SparkCatalog` — a catalog that only knows about
  Iceberg tables. Use this when the catalog (Hive/Glue/REST/etc.) is
  dedicated to Iceberg.
- `org.apache.iceberg.spark.SparkSessionCatalog` — wraps Spark's built-in
  session catalog so Iceberg tables and regular Spark/Hive tables coexist
  under the same catalog name. Use this when you're incrementally adopting
  Iceberg inside an existing Hive-backed Spark environment.

## DataFrame API

Iceberg tables are ordinary Spark tables from the DataFrame API's point of
view once the catalog is configured:

```python
df = spark.table("local.db.employees")
df.filter(df.id > 10).write.mode("append").saveAsTable("local.db.employees")

# or the Iceberg-flavored writer, useful when you want branch/tag targeting
df.writeTo("local.db.employees").append()
```

Reading a specific snapshot from the DataFrame API:

```python
spark.read.option("snapshot-id", "8947839283579").table("local.db.employees")
spark.read.option("as-of-timestamp", "1704067200000").table("local.db.employees")
```

## Maintenance procedures (`CALL`)

These require the SQL extensions above.

| Procedure | Purpose |
|---|---|
| `rewrite_data_files` | Compact small files into larger ones (bin-pack, sort, or z-order strategies) |
| `rewrite_manifests` | Compact manifest files so planning stays fast as snapshot count grows |
| `expire_snapshots` | Remove old snapshots (and files no longer referenced by any remaining snapshot) |
| `remove_orphan_files` | Delete data files not referenced by any snapshot — e.g. left over from a failed write |
| `migrate` | Convert an existing Hive/Parquet table in place into an Iceberg table |
| `snapshot` | Create a new Iceberg table pointing at an existing table's data, without touching the original |
| `add_files` | Import existing data files into an Iceberg table's metadata without rewriting them |
| `rollback_to_snapshot` / `set_current_snapshot` | Point the table back at a specific snapshot |
| `cherrypick_snapshot` | Apply a specific snapshot's changes onto the current state |

```sql
CALL local.system.rewrite_data_files('db.employees');

CALL local.system.expire_snapshots(
  table => 'db.employees',
  older_than => TIMESTAMP '2024-01-01 00:00:00'
);

CALL local.system.remove_orphan_files(table => 'db.employees');

CALL local.system.migrate('legacy_hive_db.legacy_table');
```

See `scripts/sql/maintenance.sql` in this folder for a runnable sequence
against the local playground.

## Next

[Flink, Trino, Hive](06-engines-flink-trino-hive.md) for the non-Spark
engine integrations.
