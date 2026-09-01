"""Write a small Iceberg table via PyIceberg against the REST catalog
brought up by docker-compose.yml (no JVM/Spark involved).

Usage:
    pip install "pyiceberg[s3fs]"
    python pyiceberg_write_example.py
"""

import pyarrow as pa

from pyiceberg.catalog import load_catalog

catalog = load_catalog(
    "rest",
    **{
        "type": "rest",
        "uri": "http://localhost:8181",
        "s3.endpoint": "http://localhost:9000",
        "s3.access-key-id": "admin",
        "s3.secret-access-key": "password",
    },
)

catalog.create_namespace_if_not_exists("db")

schema = pa.schema(
    [
        pa.field("id", pa.int32(), nullable=False),
        pa.field("full_name", pa.string()),
        pa.field("salary", pa.int64()),
    ]
)

table = catalog.create_table_if_not_exists("db.pyiceberg_employees", schema=schema)

data = pa.Table.from_pylist(
    [
        {"id": 1, "full_name": "grace", "salary": 102000},
        {"id": 2, "full_name": "amir", "salary": 97000},
    ],
    schema=schema,
)

table.append(data)

print(f"Wrote {data.num_rows} rows. Current snapshot: {table.current_snapshot().snapshot_id}")
