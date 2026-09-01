-- learning-resources/scripts/sql/schema_evolution.sql
-- Demonstrates metadata-only schema changes. Run basics.sql first.

-- add a column: old rows read back with NULL for it
ALTER TABLE demo.db.employees ADD COLUMN salary INT;

SELECT * FROM demo.db.employees ORDER BY id;

INSERT INTO demo.db.employees VALUES (17, 'priya', DATE '2023-11-01', 95000);

SELECT * FROM demo.db.employees ORDER BY id;

-- rename a column: field ID is unchanged, old files still resolve correctly
ALTER TABLE demo.db.employees RENAME COLUMN name TO full_name;

SELECT * FROM demo.db.employees ORDER BY id;

-- widen a type: int -> bigint, no rewrite
ALTER TABLE demo.db.employees ALTER COLUMN salary TYPE BIGINT;

DESCRIBE TABLE demo.db.employees;

-- confirm none of this created new data files (it's metadata-only)
SELECT count(*) AS file_count FROM demo.db.employees.files;
