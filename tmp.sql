SELECT ST_Split(e.geom,ST_GeomFromText('POINT(14.422163 50.044210)',4326) )
FROM edges_view e
WHERE e.data_id IN (
SELECT e.data_id
FROM edges_view e
ORDER BY e.geom <-> ST_GeomFromText('POINT(14.422163 50.099210)',4326)
LIMIT 1);



SELECT ST_AsText(e.geom), ST_AsText(ST_ClosestPoint(e.geom, ST_GeomFromText('POINT(14.4794727 50.0926140)',4326)))--ST_Split(e.geom, ST_ClosestPoint(e.geom, ST_GeomFromText('POINT(14.4794727 50.0926140)',4326)))
FROM edges_view e
WHERE e.data_id IN (
SELECT e.data_id
FROM edges_view e
ORDER BY e.geom <-> ST_GeomFromText('POINT(14.4794727 50.0926140)',4326)
LIMIT 1);

SELECT ST_AsText(ST_Split(ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326), ST_GeomFromText('POINT(14.4795584045074 50.0926436507864)',4326)));

SELECT ST_AsText(ST_LineSubstring (ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),0,ST_LineLocatePoint(ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),ST_GeomFromText('POINT(14.4795584045074 50.0926436507864)',4326))));


SELECT ST_AsText(ST_LineSubstring (ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),ST_LineLocatePoint(ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),ST_GeomFromText('POINT(14.4795584045074 50.0926436507864)',4326)),1));

--SELECT ST_Length(ST_LineSubstring (ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),ST_LineLocatePoint(ST_GeomFromText('LINESTRING(14.4797048 50.0922205,14.4795213 50.0927509)',4326),ST_GeomFromText('POINT(14.4795584045074 50.0926436507864)',4326)),1), true);

--CREATE OR REPLACE VIEW name AS
--;
DROP FUNCTION IF EXISTS public."find_node"(longitude double precision, latitude double precision);

CREATE OR REPLACE FUNCTION find_node(longitude double precision, latitude double precision) 
RETURNS TABLE (out_point geometry, out_distance double precision)
AS 
$$
DECLARE
    var real;
    point geometry;
    closest_point geometry;
    edge edges_view%rowtype;
BEGIN

point := ST_GeomFromText(concat('POINT(',longitude, ' ', latitude, ')'),4326);
RAISE NOTICE '%', ST_AsText(point);
SELECT * INTO edge 
	FROM edges_view e
	WHERE e.data_id IN (
	SELECT e.data_id
	FROM edges_view e
	ORDER BY e.geom <-> ST_GeomFromText('POINT(14.4794727 50.0926140)',4326)
	LIMIT 1);
RAISE NOTICE 'edge: %', edge;
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

SELECT public."find_node"(14.4794727, 50.0926140);


