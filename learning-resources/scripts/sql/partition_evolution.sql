-- learning-resources/scripts/sql/partition_evolution.sql
-- Demonstrates changing a partition spec without rewriting existing data.
-- Run basics.sql first.

-- start unpartitioned, then partition by month of hire_date going forward
ALTER TABLE demo.db.employees ADD PARTITION FIELD month(hire_date);

SELECT * FROM demo.db.employees.partitions;

INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES
  (18, 'wei', DATE '2024-02-20', 88000);

-- old rows keep the old (unpartitioned) spec; new rows use the new spec —
-- both are valid and the planner is spec-aware across both
SELECT * FROM demo.db.employees.partitions;

-- switch to a finer granularity going forward
ALTER TABLE demo.db.employees REPLACE PARTITION FIELD month(hire_date) WITH day(hire_date);

INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES
  (19, 'noor', DATE '2024-03-05', 91000);

SELECT * FROM demo.db.employees.partitions;

-- table now has 3 historical partition specs in play; none of them
-- required rewriting a single existing data file
SELECT * FROM demo.db.employees.metadata_log_entries;
