-- Function: public."_divideWay"(ways)

DROP FUNCTION public."_divideWay"(ways);

CREATE OR REPLACE FUNCTION public."_divideWay"(IN ways ways)
  RETURNS TABLE(osm_id bigint, is_paid boolean, is_oneway boolean, is_inside boolean, speed_forward integer, speed_backward integer, length double precision, road_type integer, state character, geom geometry, source_id bigint, target_id bigint) AS
$BODY$DECLARE
--	CREATE TYPE edge_type AS TABLE of edges_routing%rowtype;
	node_id bigint;
	counter integer;
	source_rec nodes_routing%rowtype;
	target_rec nodes_routing%rowtype;
	node_rec nodes_routing%rowtype;
--	edge_list edge_type; 
BEGIN
	counter := 1;
	FOREACH node_id IN ARRAY ways.nodes LOOP
		SELECT * INTO node_rec FROM nodes_routing WHERE nodes_routing.osm_id = node_id;
		IF node_rec IS NULL THEN
		ELSE
			target_rec := node_rec;
			RAISE NOTICE 'osm id = %, id = %', node_rec.osm_id,node_rec.id;
			IF source_rec IS NULL THEN
			ELSE
				RAISE NOTICE 'source = %',source_rec.id;
				RETURN QUERY SELECT	ways.id::bigint,false, false, false, 1,1,1.0::double precision,1::integer,'CZ'::character(2),ST_SetSRID(ST_MakePoint(1,1),4326),source_rec.id, target_rec.id;
				counter := counter + 1;
			END IF;
			source_rec := node_rec;
		END IF;
		--IF EXISTS(SELECT * FROM nodes_routing AS nodes WHERE nodes.osm_id = node_id) THEN
		--END IF;
	END LOOP;
	RETURN;
--	RETURN edge_list;
END;
--RAISE NOTICE 'i want to print % and %', var1,var2;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public."_divideWay"(ways)
  OWNER TO postgres;
