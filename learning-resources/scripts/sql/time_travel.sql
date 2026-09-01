-- learning-resources/scripts/sql/time_travel.sql
-- Demonstrates snapshots, time travel, and rollback. Run basics.sql first.

-- every snapshot so far, oldest to newest
SELECT snapshot_id, committed_at, operation FROM demo.db.employees.snapshots ORDER BY committed_at;

-- capture a snapshot id to travel back to (copy a real value from the
-- query above when running this interactively)
-- SELECT * FROM demo.db.employees VERSION AS OF <snapshot_id>;

-- time travel by timestamp instead of snapshot id
SELECT * FROM demo.db.employees TIMESTAMP AS OF '2024-01-01 00:00:00';

-- make a change we'll want to undo
INSERT INTO demo.db.employees (id, full_name, hire_date, salary) VALUES
  (999, 'bad-row', DATE '2099-01-01', -1);

SELECT * FROM demo.db.employees WHERE id = 999;

-- find the snapshot right before the bad insert and roll back to it
SELECT snapshot_id, committed_at, operation, summary
FROM demo.db.employees.snapshots
ORDER BY committed_at DESC
LIMIT 3;

-- CALL demo.system.rollback_to_snapshot('db.employees', <snapshot_id_before_bad_row>);

-- after rollback, the bad row is gone, but the snapshot that added it
-- still exists in history (is_current_ancestor = false)
-- SELECT * FROM demo.db.employees WHERE id = 999;
-- SELECT * FROM demo.db.employees.history;
