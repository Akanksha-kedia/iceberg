#!/usr/bin/env bash
# Sets up a local (no Docker) PySpark + Iceberg environment using a
# `hadoop`-type catalog on local disk, then runs sql/basics.sql against it.
#
# Usage: ./setup-local-spark-iceberg.sh

set -euo pipefail

ICEBERG_VERSION="1.6.1"
SPARK_VERSION="3.5"
SCALA_VERSION="2.12"
WAREHOUSE_DIR="/tmp/iceberg-warehouse"

echo "==> Installing PySpark ${SPARK_VERSION}.x"
pip install --quiet "pyspark==${SPARK_VERSION}.1"

echo "==> Warehouse directory: ${WAREHOUSE_DIR}"
mkdir -p "${WAREHOUSE_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Launching spark-sql with the Iceberg runtime + local hadoop catalog"
spark-sql \
  --packages "org.apache.iceberg:iceberg-spark-runtime-${SPARK_VERSION}_${SCALA_VERSION}:${ICEBERG_VERSION}" \
  --conf "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" \
  --conf "spark.sql.catalog.demo=org.apache.iceberg.spark.SparkCatalog" \
  --conf "spark.sql.catalog.demo.type=hadoop" \
  --conf "spark.sql.catalog.demo.warehouse=file://${WAREHOUSE_DIR}" \
  -f "${SCRIPT_DIR}/sql/basics.sql"

echo "==> Done. Table files are under ${WAREHOUSE_DIR}"
