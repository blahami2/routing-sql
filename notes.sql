--ARRAY contains
SELECT * FROM ways WHERE
(3999528190 = ANY(ways.nodes));

-- UNION
SELECT * FROM a
UNION
SELECT * FROM b;

-- VIEW
CREATE VIEW view_name AS
SELECT column_name(s)
FROM table_name
WHERE condition

-- DIFFERENCE
SELECT * FROM a
EXCEPT
SELECT * FROM b;

-- CROSS-DATABASE INSERT
INSERT INTO target_db.target_table (target_column*)
SELECT (source_columnt*) FROM source_db.source_table;

-- PERFORMANCE
-- extract.sql execution - 4s, COUNT 2s
-- creating ways view - 0.067s
-- extract.sql execution using ways view - 4.1s, COUNT 2.2s (variable 3s)