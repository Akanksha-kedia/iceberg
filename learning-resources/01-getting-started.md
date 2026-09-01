# 1. Getting Started

## What you need

- JDK 17 or 21
- Python 3.9+ (only if you want to follow the PyIceberg examples)
- Docker + Docker Compose (only for the local playground in `scripts/`)

## Building this repo

Apache Iceberg is built with Gradle:

```bash
./gradlew build
```

Skip tests for a faster local build:

```bash
./gradlew build -x test -x integrationTest
```

Fix code style before committing:

```bash
./gradlew spotlessApply
```

Fix code style across every supported Spark/Hive/Flink version (slower,
but what CI actually checks):

```bash
./gradlew spotlessApply -DallModules
```

## Your first table, without any of this repo's build

You don't need to build Iceberg from source to try it — the Spark runtime
jar plus PySpark is enough. This mirrors `scripts/setup-local-spark-iceberg.sh`
in this folder, which automates the same steps.

```bash
pip install pyspark==3.5.1
```

```python
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("iceberg-getting-started")
    .config("spark.jars.packages", "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.6.1")
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.local.type", "hadoop")
    .config("spark.sql.catalog.local.warehouse", "file:///tmp/iceberg-warehouse")
    .getOrCreate()
)

spark.sql("CREATE NAMESPACE IF NOT EXISTS local.db")
spark.sql("CREATE TABLE local.db.employees (id INT, name STRING) USING iceberg")
spark.sql("INSERT INTO local.db.employees VALUES (14, 'james'), (15, 'john')")
spark.sql("SELECT * FROM local.db.employees").show()
```

That's a fully working Iceberg table on local disk: real metadata files,
real manifests, real snapshots — just backed by a `hadoop`-type catalog
instead of Hive/Glue/REST, which is enough to see everything in
[Core Concepts](02-core-concepts.md) in action.

## Next

- [Core Concepts](02-core-concepts.md) if you want to understand what just
  happened under `/tmp/iceberg-warehouse`.
- `scripts/README.md` if you'd rather skip straight to a Docker-based
  playground with a real REST catalog instead of the `hadoop` catalog type.
