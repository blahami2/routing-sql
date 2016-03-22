-- Function: public."_determineAdminAreas"()

DROP FUNCTION public."_determineAdminAreas"();

CREATE OR REPLACE FUNCTION public."_determineAdminAreas"()
  RETURNS void AS
$BODY$
DECLARE
	way ways;
	relation relations;
	rel_member relation_members;
	edge edges_routing;
	area geometry;
	area_approx geometry;
	x_min integer;
	x_max integer;
	y_min integer;
	y_max integer;
	counter integer := 0;
	total integer := 0;
BEGIN

FOR relation IN (SELECT * FROM relations WHERE (tags->'boundary' = 'administrative' AND to_number(tags->'admin_level','99') >= 8)) LOOP
	area := null;
	FOR rel_member IN (SELECT * FROM relation_members WHERE relation_members.relation_id = relation.id) LOOP
		SELECT * INTO way FROM ways WHERE ways.id = rel_member.member_id;
		IF way IS NULL THEN
		ELSE
			IF area IS NULL THEN
--				RAISE NOTICE 'way: %', way;
				area := way.linestring;
			ELSE
				area := ST_MakeLine(area, way.linestring);
			END IF;
		END IF;
	END LOOP;
	area := ST_AddPoint(area, ST_StartPoint(area));
	IF ST_NPoints(area) >= 4 THEN
		area := ST_MakePolygon(area);
		RAISE NOTICE 'area name = %', relation.tags->'name';
		RAISE NOTICE 'area = %', ST_AsText(area);
		x_min := (ST_XMin(area)*10000000)::integer;
		x_max := (ST_XMax(area)*10000000)::integer;
		y_min := (ST_YMin(area)*10000000)::integer;
		y_max := (ST_YMax(area)*10000000)::integer;
	--	RAISE NOTICE '[%,%][%,%]', x_min, y_min, x_max, y_max;
		counter := 0;
		FOR edge IN (SELECT * FROM edges_routing WHERE (
			x_min <= edges_routing.source_lon AND edges_routing.source_lon <= x_max 
			AND y_min <= edges_routing.source_lat AND edges_routing.source_lat <= y_max 
			AND x_min <= edges_routing.target_lon AND edges_routing.target_lon <= x_max 
			AND y_min <= edges_routing.target_lat AND edges_routing.target_lat <= y_max
			AND ST_Within(edges_routing.geom, area) 
--			AND ST_Contains(area, ST_StartPoint(edge.geom)) AND ST_Contains(area, ST_EndPoint(edge.geom))
		)) LOOP
			--IF (x_min <= edge.source_lon AND edge.source_lon <= x_max AND y_min <= edge.source_lat AND edge.source_lat <= y_max AND x_min <= edge.target_lon AND edge.target_lon <= x_max AND y_min <= edge.target_lat AND edge.target_lat <= y_max) THEN
			--	RAISE NOTICE 'is in box';
				
	--			IF (
	--				
	--				ST_Contains(area, ST_StartPoint(edge.geom)) AND ST_Contains(area, ST_EndPoint(edge.geom))
	--			) THEN
					UPDATE edges_routing SET is_inside = true WHERE id = edge.id;
	--			END IF;
				
			--END IF;
			counter := counter + 1;
		END LOOP;
		RAISE NOTICE 'operations = %',counter;
		total := total + counter;
	ELSE
		RAISE NOTICE 'area = %', ST_AsText(area);
	END IF;
END LOOP;
RAISE NOTICE 'operations total: %', total;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."_determineAdminAreas"()
  OWNER TO postgres;


SELECT public."_determineAdminAreas"();