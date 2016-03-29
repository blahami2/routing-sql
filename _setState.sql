-- Function: public."_setState"()

DROP FUNCTION IF EXISTS public."075363380323b4799196ff5108cc951d"();
DROP TYPE IF EXISTS rel_way;

CREATE TYPE rel_way AS (linestring geometry, sequence_id integer);

CREATE OR REPLACE FUNCTION public."075363380323b4799196ff5108cc951d"()
  RETURNS void AS
$BODY$
DECLARE
	way ways;
	relation relations;
	rel_member relation_members;
	edge edges_routing;
	linestring geometry;
	area geometry;
	area_approx geometry;
	member_id integer;
	x_min integer;
	x_max integer;
	y_min integer;
	y_max integer;
	counter integer := 0;
	total integer := 0;
	used_members integer[];
	relation_way rel_way;
BEGIN

UPDATE edges_routing SET is_inside = false;

FOR relation IN (SELECT * FROM relations WHERE (tags->'boundary' = 'administrative' AND to_number(tags->'admin_level','99') = 2 AND tags->'ISO3166-1:alpha2' IS NOT NULL)) LOOP
	area := null;
	used_members := null;
	FOR member_id IN (SELECT rm.relation_id FROM relation_members AS rm JOIN ways AS w ON rm.member_id = w.id WHERE rm.relation_id = relation.id) LOOP
--		RAISE NOTICE 'member id = %', member_id;
		FOR relation_way IN (SELECT w.linestring, rm.sequence_id FROM relation_members AS rm JOIN ways AS w ON rm.member_id = w.id WHERE (rm.relation_id = relation.id AND ((used_members @> ARRAY[rm.sequence_id]) IS NULL OR (used_members @> ARRAY[rm.sequence_id]) IS FALSE)
		)) LOOP
			IF relation_way.linestring IS NULL THEN
			ELSE
--				RAISE NOTICE '% contains % = %',used_members,relation_way.sequence_id,(used_members @> ARRAY[relation_way.sequence_id]) ;
--				IF used_members @> ARRAY[relation_way.sequence_id] THEN
--				ELSE
					IF area IS NULL THEN
		--				RAISE NOTICE 'way: %', way;
						area := relation_way.linestring;
						used_members := array_append(used_members,relation_way.sequence_id);
					ELSE
						IF ST_Equals(ST_EndPoint(area), ST_StartPoint(relation_way.linestring)) THEN
							area := ST_MakeLine(area, relation_way.linestring);
							used_members := array_append(used_members,relation_way.sequence_id);
						ELSE 
							IF ST_Equals(ST_EndPoint(area), ST_EndPoint(relation_way.linestring)) THEN
								area := ST_MakeLine(area, ST_Reverse(relation_way.linestring));
								used_members := array_append(used_members,relation_way.sequence_id);
							END IF;
						END IF;
					END IF;
--				END IF;
			END IF;
		END LOOP;
	END LOOP;
--	RAISE NOTICE 'used = %', used_members;
	area := ST_AddPoint(area, ST_StartPoint(area));
	IF ST_NPoints(area) >= 4 THEN
		area := ST_MakePolygon(area);
--		RAISE NOTICE 'area name = %', relation.tags->'name';
--		RAISE NOTICE 'area = %', ST_AsText(area);
		x_min := (ST_XMin(area)*10000000)::integer;
		x_max := (ST_XMax(area)*10000000)::integer;
		y_min := (ST_YMin(area)*10000000)::integer;
		y_max := (ST_YMax(area)*10000000)::integer;
	--	RAISE NOTICE '[%,%][%,%]', x_min, y_min, x_max, y_max;
		counter := 0;
	--	FOR edge IN (SELECT * FROM edges_routing WHERE (
	--		x_min <= edges_routing.source_lon AND edges_routing.source_lon <= x_max 
	--		AND y_min <= edges_routing.source_lat AND edges_routing.source_lat <= y_max 
	--		AND x_min <= edges_routing.target_lon AND edges_routing.target_lon <= x_max 
	--		AND y_min <= edges_routing.target_lat AND edges_routing.target_lat <= y_max
	--		AND ST_Within(edges_routing.geom, area) 
--			AND ST_Contains(area, ST_StartPoint(edge.geom)) AND ST_Contains(area, ST_EndPoint(edge.geom))
	--	)) LOOP
			--IF (x_min <= edge.source_lon AND edge.source_lon <= x_max AND y_min <= edge.source_lat AND edge.source_lat <= y_max AND x_min <= edge.target_lon AND edge.target_lon <= x_max AND y_min <= edge.target_lat AND edge.target_lat <= y_max) THEN
			--	RAISE NOTICE 'is in box';
				
	--			IF (
	--				
	--				ST_Contains(area, ST_StartPoint(edge.geom)) AND ST_Contains(area, ST_EndPoint(edge.geom))
	--			) THEN
					UPDATE edges_routing SET state = relation.tags->'ISO3166-1:alpha2' WHERE (
			x_min <= edges_routing.source_lon AND edges_routing.source_lon <= x_max 
			AND y_min <= edges_routing.source_lat AND edges_routing.source_lat <= y_max 
			AND x_min <= edges_routing.target_lon AND edges_routing.target_lon <= x_max 
			AND y_min <= edges_routing.target_lat AND edges_routing.target_lat <= y_max
			AND ST_Within(edges_routing.geom, area)); 
	--			END IF;
				
			--END IF;
	--		counter := counter + 1;
	--	END LOOP;
--		RAISE NOTICE 'operations = %',counter;
		total := total + counter;
	ELSE
--		RAISE NOTICE 'area = %', ST_AsText(area);
	END IF;
END LOOP;
--RAISE NOTICE 'operations total: %', total;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."075363380323b4799196ff5108cc951d"()
  OWNER TO postgres;


SELECT public."075363380323b4799196ff5108cc951d"();

DROP TYPE rel_way;
DROP FUNCTION public."075363380323b4799196ff5108cc951d"();