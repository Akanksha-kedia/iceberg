"""Read the table written by pyiceberg_write_example.py, including its
snapshot history, and show a simple time-travel read.

Usage:
    pip install "pyiceberg[s3fs]"
    python pyiceberg_write_example.py   # first
    python pyiceberg_read_example.py
"""

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

table = catalog.load_table("db.pyiceberg_employees")

print("Current snapshot:")
df = table.scan().to_pandas()
print(df)

print("\nAll snapshots:")
for snap in table.history():
    print(snap)

first_snapshot_id = table.history()[0].snapshot_id
print(f"\nTime-travel read as of first snapshot ({first_snapshot_id}):")
df_first = table.scan(snapshot_id=first_snapshot_id).to_pandas()
print(df_first)
