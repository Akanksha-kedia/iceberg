# Scripts

A runnable local playground plus standalone examples referenced from the
docs in `learning-resources/`.

## Local playground (Docker)

`docker-compose.yml` brings up:

- **MinIO** — S3-compatible object storage, as the warehouse backend
- **REST catalog** — Iceberg's reference REST catalog server (Tabular's
  `iceberg-rest-fixture` image), backed by the MinIO bucket
- **Spark** — a PySpark container preconfigured to talk to both

```bash
cd learning-resources/scripts
docker compose up -d
docker compose ps            # wait until all three are healthy
```

Then run any of the SQL scripts against it:

```bash
docker compose exec spark-iceberg spark-sql -f sql/basics.sql
docker compose exec spark-iceberg spark-sql -f sql/schema_evolution.sql
docker compose exec spark-iceberg spark-sql -f sql/partition_evolution.sql
docker compose exec spark-iceberg spark-sql -f sql/time_travel.sql
docker compose exec spark-iceberg spark-sql -f sql/maintenance.sql
```

Or drop into an interactive shell:

```bash
docker compose exec spark-iceberg spark-sql
```

Tear down:

```bash
docker compose down -v
```

## Standalone: no Docker

`setup-local-spark-iceberg.sh` installs PySpark locally and runs
`run_spark_sql_examples.sh`, which walks through `sql/basics.sql` against a
`hadoop`-type catalog on local disk instead of the REST catalog + MinIO
stack — same SQL, no containers.

```bash
./setup-local-spark-iceberg.sh
```

## Python (PyIceberg, no JVM)

`python/pyiceberg_read_example.py` and `python/pyiceberg_write_example.py`
talk to the same REST catalog from the Docker playground, without Spark:

```bash
pip install "pyiceberg[s3fs]"
python python/pyiceberg_write_example.py
python python/pyiceberg_read_example.py
```
