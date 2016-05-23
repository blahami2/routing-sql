DROP FUNCTION IF EXISTS public."find_node"(longitude double precision, latitude double precision);

CREATE OR REPLACE FUNCTION find_node(longitude double precision, latitude double precision) 
RETURNS TABLE (data_id bigint, osm_id bigint, speed integer, is_paid boolean, length double precision, road_type integer, geom geometry, out_point bigint, out_distance double precision)
AS 
$$
DECLARE
    point geometry;
    closest_node nodes_view%rowtype; 
    closest_point geometry;
    edge edges_view%rowtype;
BEGIN

point := ST_GeomFromText(concat('POINT(',longitude, ' ', latitude, ')'),4326);
-- check if it is not a valid node, return this if so
SELECT n INTO closest_node FROM nodes_view n WHERE ST_Equals(
      ST_SnapToGrid(point, 0.000001),
      ST_SnapToGrid(n.geom, 0.000001)
   );
IF closest_node IS NOT NULL THEN
--	RAISE NOTICE '%', ST_AsText(closest_point);
	out_point := closest_node.id;
	out_distance := 0;
	RETURN NEXT;
ELSE
	FOR edge IN (
		SELECT *
		FROM edges_view e
		WHERE e.data_id IN (
		SELECT e.data_id
		FROM edges_view e
		ORDER BY e.geom <-> point
		LIMIT 1)) LOOP
		data_id := edge.data_id;
		osm_id := edge.osm_id;
		speed := edge.speed;
		is_paid := edge.is_paid;
		length := edge.length;
		road_type := edge.road_type;
		geom := edge.geom;

		closest_point := ST_ClosestPoint(edge.geom, point);
		SELECT n INTO closest_node FROM nodes_view n WHERE n.id = edge.target_id;
    out_point := closest_node.id;
		IF ST_Equals(
			ST_SnapToGrid(out_point, 0.000001),
			ST_SnapToGrid(ST_StartPoint(edge.geom), 0.000001)
		) THEN
			out_distance := ST_Length(ST_LineSubstring(edge.geom, 0, ST_LineLocatePoint(edge.geom, closest_point)), true);
		ELSE
			out_distance := ST_Length(ST_LineSubstring(edge.geom, ST_LineLocatePoint(edge.geom, closest_point), 1), true);
		END IF;
		RETURN NEXT;
	END LOOP;
END IF;

--RAISE NOTICE '%', ST_AsText(point);
END;
$$ LANGUAGE plpgsql;

--SELECT *, ST_AsText(out_point) FROM public."find_node"(14.418987, 50.102421);
