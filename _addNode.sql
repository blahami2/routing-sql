DROP FUNCTION IF EXISTS public."_addNode"(node_osm_id bigint, way_osm_id bigint);

CREATE OR REPLACE FUNCTION _addNode(node_osm_id bigint, way_osm_id bigint) 
RETURNS void
AS 
$$
DECLARE
	data_key bigint;
	data1_key bigint;
	data2_key bigint;
    point geometry;
    subway1 geometry;
    subway2 geometry;
    edge edges_view%rowtype;
    single_edge edges_routing%rowtype;
    src bigint;
    dest bigint;
    mid bigint;
BEGIN
SELECT n.geom INTO point
	FROM nodes n
	WHERE n.id = node_osm_id;
-- INSERT INTO nodes_data_routing (osm_id, state, geom) VALUES (node_osm_id, 'CZ', point) RETURNING id INTO data_key;
RAISE NOTICE 'INSERT INTO nodes_data_routing (osm_id, state, geom) VALUES (%, %, %);', node_osm_id, 'CZ', point;

SELECT * INTO edge
FROM edges_view e
WHERE e.osm_id = way_osm_id AND
e.data_id IN (
	SELECT e.data_id
	FROM edges_view e
	ORDER BY e.geom <-> point
	LIMIT 1);

IF edge IS NULL THEN
	RAISE NOTICE 'edge is null for: %, %', node_osm_id, way_osm_id;
ELSE	
	-- SPLIT edges
	-- INSERT edge data
	RAISE NOTICE 'edge: %', edge; 
	subway1 := ST_LineSubstring(edge.geom, 0, ST_LineLocatePoint(edge.geom, point));
	RAISE NOTICE 'subway1 = %', ST_AsText(subway1); 
	subway2 := ST_LineSubstring(edge.geom, ST_LineLocatePoint(edge.geom, point), 1);
	RAISE NOTICE 'subway2 = %', ST_AsText(subway2); 
--	INSERT INTO edges_data_routing (osm_id, is_paid, length, road_type, state, geom, source_lon, source_lat, target_lon, target_lat)
--		VALUES (way_osm_id, edge.is_paid, ST_Length(subway1, true)/1000, edge.road_type, edge.state, subway1, ST_X(ST_StartPoint(subway1)) * 10000000, ST_Y(ST_StartPoint(subway1)) * 10000000, ST_X(ST_EndPoint(subway1)) * 10000000, ST_Y(ST_EndPoint(subway1)) * 10000000) 
--		RETURNING id INTO data1_key;
	RAISE NOTICE 'INSERT INTO edges_data_routing (osm_id, is_paid, length, road_type, state, geom, source_lon, source_lat, target_lon, target_lat)
		VALUES (%, %, %, %, %, %, %, %, %, %) 
		RETURNING id INTO data1_key',way_osm_id, edge.is_paid, ST_Length(subway1, true) / 1000, edge.road_type, edge.state, subway1, ST_X(ST_StartPoint(subway1)) * 10000000, ST_Y(ST_StartPoint(subway1)) * 10000000, ST_X(ST_EndPoint(subway1)) * 10000000, ST_Y(ST_EndPoint(subway1)) * 10000000; 
--	INSERT INTO edges_data_routing (osm_id, is_paid, length, road_type, state, geom, source_lon, source_lat, target_lon, target_lat)
--		VALUES (way_osm_id, edge.is_paid, ST_Length(subway2, true)/1000, edge.road_type, edge.state, subway2, ST_X(ST_StartPoint(subway2)) * 10000000, ST_Y(ST_StartPoint(subway2)) * 10000000, ST_X(ST_EndPoint(subway2)) * 10000000, ST_Y(ST_EndPoint(subway2)) * 10000000) 
--		RETURNING id INTO data2_key;
	RAISE NOTICE 'INSERT INTO edges_data_routing (osm_id, is_paid, length, road_type, state, geom, source_lon, source_lat, target_lon, target_lat)
		VALUES (%, %, %, %, %, %, %, %, %, %) 
		RETURNING id INTO data1_key',way_osm_id, edge.is_paid, ST_Length(subway2, true) / 1000, edge.road_type, edge.state, subway2, ST_X(ST_StartPoint(subway2)) * 10000000, ST_Y(ST_StartPoint(subway2)) * 10000000, ST_X(ST_EndPoint(subway2)) * 10000000, ST_Y(ST_EndPoint(subway2)) * 10000000;
	FOR single_edge IN (SELECT * 
		FROM edges_routing e 
		WHERE e.data_id = edge.data_id) LOOP
		-- INSERT
		-- INSERT INTO nodes_routing (data_id) VALUES (data_key) RETURNING id INTO mid;
		RAISE NOTICE 'INSERT INTO nodes_routing (data_id) VALUES (%) RETURNING id INTO mid;', data_key;
		-- INSERT edges
		IF single_edge.is_forward IS TRUE THEN
			-- source is source, target is target mid
			-- source is mid, target is target
			-- INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (data1_key, single_edge.speed, single_edge.is_forward, single_edge.source_id, mid);
			RAISE NOTICE 'INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (%, %, %, %, %);', data1_key, single_edge.speed, single_edge.is_forward, single_edge.source_id, mid;
			-- INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (data2_key, single_edge.speed, single_edge.is_forward, mid, single_edge.target_id);
			RAISE NOTICE 'INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (%, %, %, %, %);', data2_key, single_edge.speed, single_edge.is_forward, mid, single_edge.target_id;
		ELSE
			-- INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (data2_key, single_edge.speed, single_edge.is_forward, single_edge.source_id, mid);
			RAISE NOTICE 'INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (%, %, %, %, %);', data2_key, single_edge.speed, single_edge.is_forward, single_edge.source_id, mid;
			-- INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (data1_key, single_edge.speed, single_edge.is_forward, mid, single_edge.target_id);
			RAISE NOTICE 'INSERT INTO edges_routing (data_id, speed, is_forward, source_id, target_id) VALUES (%, %, %, %, %);', data1_key, single_edge.speed, single_edge.is_forward, mid, single_edge.target_id;
		END IF;
	END LOOP;
	-- remove old edge
	-- DELETE FROM edges_routing e WHERE e.data_id = edge.data_id;
	RAISE NOTICE 'DELETE FROM edges_routing e WHERE e.data_id = %;', edge.data_id;
	-- DELETE FROM edges_data_routing e WHERE e.id = edge.data_id;
	RAISE NOTICE 'DELETE FROM edges_data_routing e WHERE e.id = %;', edge.data_id; 
END IF;
END;
$$ LANGUAGE plpgsql;

SELECT _addNode(2110461885::bigint, 76821631::bigint);

