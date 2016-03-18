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

-- PERFORMANCE
-- extract.sql execution - 4s, COUNT 2s
-- creating ways view - 0.067s
-- extract.sql execution using ways view - 4.1s, COUNT 2.2s