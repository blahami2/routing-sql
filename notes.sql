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

-- CONCAT
CONCAT('str1','str2');

-- CROSS-DATABASE INSERT
INSERT INTO target_db.target_table (target_column*)
SELECT (source_columnt*) FROM source_db.source_table;

-- PERFORMANCE
-- extract.sql execution - 4s, COUNT 2s
-- creating ways view - 0.067s
-- extract.sql execution using ways view - 4.1s, COUNT 2.2s (variable 3s)

-- FIND CLOSEST VALID NODE
SELECT DISTINCT ST_Distance(ST_GeomFromText('POINT(14.422163 50.099210)',4326),n.geom) AS dist, n.*, ST_AsText(n.geom)
FROM nodes_data_routing n
ORDER BY dist ASC
LIMIT 1;

-- FIND 
SELECT *
FROM nodes_view n
JOIN edges_view e ON (e.source_id = n.id OR e.target_id = n.id)
WHERE 4 IN (
	SELECT COUNT(nv.*)
	FROM nodes_view nv
	JOIN edges_view ev ON (ev.source_id = nv.id OR ev.target_id = nv.id)
	WHERE nv.id = n.id
	GROUP BY n.id
)
LIMIT 50;

