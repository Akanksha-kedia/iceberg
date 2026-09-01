-- learning-resources/scripts/sql/maintenance.sql
-- Demonstrates compaction, snapshot expiry, and orphan file cleanup.
-- Run basics.sql first, and ideally schema_evolution.sql /
-- partition_evolution.sql too, so there's more than one tiny file to compact.

-- generate a bunch of small files to make compaction visible
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES (101, 'a', DATE '2024-01-01', 1);
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES (102, 'b', DATE '2024-01-02', 1);
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES (103, 'c', DATE '2024-01-03', 1);
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES (104, 'd', DATE '2024-01-04', 1);
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES (105, 'e', DATE '2024-01-05', 1);

SELECT count(*) AS file_count_before, avg(file_size_in_bytes) AS avg_bytes_before
FROM demo.db.employees.files;

CALL demo.system.rewrite_data_files(table => 'db.employees');

SELECT count(*) AS file_count_after, avg(file_size_in_bytes) AS avg_bytes_after
FROM demo.db.employees.files;

-- manifest compaction
CALL demo.system.rewrite_manifests(table => 'db.employees');

SELECT count(*) AS manifest_count FROM demo.db.employees.manifests;

-- snapshot expiry — keep at least the 3 most recent regardless of age
CALL demo.system.expire_snapshots(
  table => 'db.employees',
  older_than => TIMESTAMP '2024-06-01 00:00:00',
  retain_last => 3
);

SELECT count(*) AS snapshot_count FROM demo.db.employees.snapshots;

-- clean up anything orphaned by a failed/aborted write
CALL demo.system.remove_orphan_files(table => 'db.employees');
