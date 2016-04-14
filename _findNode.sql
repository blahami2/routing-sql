DROP FUNCTION IF EXISTS public."find_node"(longitude double precision, latitude double precision);

CREATE OR REPLACE FUNCTION find_node(longitude double precision, latitude double precision) 
RETURNS TABLE (id bigint, data_id bigint, osm_id bigint, speed integer, is_paid boolean, length double precision, road_type integer, geom geometry, out_point geometry, out_distance double precision)
AS 
$$
DECLARE
    var real;
    point geometry;
    closest_point geometry;
    edge edges_view%rowtype;
BEGIN

point := ST_GeomFromText(concat('POINT(',longitude, ' ', latitude, ')'),4326);
-- check if it is not a valid node, return this if so

--RAISE NOTICE '%', ST_AsText(point);
SELECT * INTO edge 
	FROM edges_view e
	WHERE e.data_id IN (
	SELECT e.data_id
	FROM edges_view e
	ORDER BY e.geom <-> point
	LIMIT 1);
--RAISE NOTICE 'edge: %', out_edge;
id := edge.id;
data_id := edge.data_id;
osm_id := edge.osm_id;
speed := edge.speed;
is_paid := edge.is_paid;
length := edge.length;
road_type := edge.road_type;
geom := edge.geom;

closest_point := ST_ClosestPoint(edge.geom, point);
out_point := ST_StartPoint(edge.geom);
out_distance := ST_Length(ST_LineSubstring(edge.geom, 0, ST_LineLocatePoint(edge.geom, closest_point)), true);
RETURN NEXT;
out_point := ST_EndPoint(edge.geom);
out_distance := ST_Length(ST_LineSubstring(edge.geom, ST_LineLocatePoint(edge.geom, closest_point), 1), true);
RETURN NEXT;
--    RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public."find_node"(50.0926140, 14.4794727);
