-- learning-resources/scripts/sql/basics.sql
-- Run against the docker-compose playground:
--   docker compose exec spark-iceberg spark-sql -f sql/basics.sql

CREATE NAMESPACE IF NOT EXISTS demo.db;

CREATE TABLE IF NOT EXISTS demo.db.employees (
  id INT,
  name STRING,
  hire_date DATE
) USING iceberg;

INSERT INTO demo.db.employees VALUES
  (14, 'james', DATE '2021-03-01'),
  (15, 'john',  DATE '2022-07-15'),
  (16, 'ana',   DATE '2023-01-10');

SELECT * FROM demo.db.employees ORDER BY id;

-- basic filtering — pruning happens via manifest-level column stats
SELECT * FROM demo.db.employees WHERE hire_date >= DATE '2022-01-01';

-- delete a row
DELETE FROM demo.db.employees WHERE id = 14;

SELECT * FROM demo.db.employees ORDER BY id;

-- see what that delete actually did to the table's snapshots
SELECT snapshot_id, operation, summary FROM demo.db.employees.snapshots ORDER BY committed_at;
