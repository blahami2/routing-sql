CREATE OR REPLACE FUNCTION public."_parseSpeedFromMaxspeed"(tags hstore, tag text) RETURNS integer AS $$
BEGIN
  IF exist(tags, tag) THEN -- maxspeed tag
    IF tags->tag SIMILAR TO '(km/h|kmh|kph)' THEN
      RETURN to_number(substring(way.tags->'maxspeed' from '#"%#" (km/h|kmh|kph)' for '#'), '999999999');
    ELSE 
      IF tags->tag SIMILAR TO 'mph' THEN
        RETURN to_number(substring(tags->tag from '#"%#" mph' for '#'), '999999999') * 1.609;
      ELSE
        IF tags->tag SIMILAR TO 'knots' THEN
          RETURN to_number(substring(tags->tag from '#"%#" knots' for '#'), '999999999') * 1.852;   
        ELSE
          IF tags->tag LIKE '%:%' THEN
            RETURN (SELECT tsm.speed_outside FROM traffic_speed_map tsm JOIN traffic_zones tz ON tsm.zone_id = tz.zone_id WHERE (tsm.state = substring(tags->tag from '#"%#":%' for '#') AND tz.name = substring(tags->tag from '%:#"%#"' for '#'))); 
          ELSE
            IF (tags->tag ~ '^\d*$') THEN
              RETURN to_number(tags->tag, '999999999');
            END IF;
          END IF;
        END IF;
      END IF;
    END IF; 
  END IF;
  RETURN -1;
END;
$$ LANGUAGE plpgsql;


DO $$
DECLARE
--	CREATE TYPE edge_type AS TABLE of edges_routing%rowtype;
	way ways;
	node_id bigint;
	source_rec nodes_routing%rowtype;
	target_rec nodes_routing%rowtype;
	node_rec nodes_routing%rowtype;
  source_data nodes_data_routing%rowtype;
  target_data nodes_data_routing%rowtype;
	speed_fw integer := -1;
	speed_bw integer := -1;
	paid boolean := false;
	oneway boolean := false;
	counter integer := 0;
	idx integer := 0;
	idx_counter integer := 0;
	node_set geometry;
	dump geometry;
	node_split geometry[];
	edge_geom geometry := null;
	node_array geometry[];
  road_type integer := 1;
  data_key bigint;
--	edge_list edge_type; 
BEGIN       
-- **************************************************************************************** DELETING CURRENT ROWS ****************************************************************************************
DELETE FROM edges_routing;
-- **************************************************************************************** EXTRACT SPEED ****************************************************************************************
FOR way IN (SELECT * FROM ways WHERE public."_isValidWay"(ways)) LOOP
-- 	RAISE NOTICE 'valid way = %', ST_AsText(way.linestring);
	node_id := 0;
	source_rec := NULL;
	target_rec := NULL;
	node_rec := NULL;
	speed_fw := -1;
	speed_bw := -1;
	paid := false;
	oneway := false;
	counter := 0;
	idx := 0;
	idx_counter := 0;
	node_set := NULL;
	dump := NULL;
	node_split := NULL;
	edge_geom := NULL;
	node_array := NULL;
	road_type := 1;
  speed_fw := public."_parseSpeedFromMaxspeed"(way.tags, 'maxspeed:forward');  
  speed_bw := public."_parseSpeedFromMaxspeed"(way.tags, 'maxspeed:backward');
  IF speed_fw = -1 THEN
    speed_fw := public."_parseSpeedFromMaxspeed"(way.tags, 'maxspeed'); 
  END IF;
  IF speed_bw = -1 THEN  
    speed_bw := speed_fw;
  END IF;
  -- **************************************************************************************** EXTRACT PAID ****************************************************************************************
  	paid := exist(way.tags, 'toll') AND (way.tags->'toll' = 'yes');
  -- **************************************************************************************** EXTRACT ONEWAY ****************************************************************************************	
  	oneway := (exist(way.tags, 'oneway') AND (way.tags->'oneway' = 'yes')) OR (way.tags->'highway' = 'motorway');
  -- **************************************************************************************** EXTRACT ROAD TYPE ****************************************************************************************
    SELECT type_id INTO road_type FROM road_types WHERE way.tags->'highway' LIKE (CONCAT(road_types.name));
    IF road_type IS NULL THEN
  	SELECT type_id INTO road_type FROM road_types WHERE road_types.name = 'living_street';
    END IF;
  -- **************************************************************************************** FOREACH NODE IN WAY - PREPARE NODES **************************************************************************************** 
  	FOR dump IN (SELECT (dumb::geometry_dump).geom FROM (
  					SELECT (ST_DumpPoints(way.linestring)) AS dumb
  				) AS dumbb) LOOP
  		node_array := array_append(node_array, dump);
  	END LOOP;
  	counter := 0;
  	FOREACH node_id IN ARRAY way.nodes LOOP
  		SELECT * INTO node_rec FROM nodes_routing nr JOIN nodes_data_routing ndr ON nr.data_id = ndr.id WHERE ndr.osm_id = node_id;
  --		RAISE NOTICE 'noderec = %',node_rec;
  		counter := counter + 1;
  		IF edge_geom IS NULL THEN
  			edge_geom := ST_MakeLine(node_array[counter]);
  		ELSE
  			edge_geom := ST_AddPoint(edge_geom, node_array[counter]);
  		END IF;
  		IF node_rec IS NULL THEN
  		ELSE
  			target_rec := node_rec;
  			IF source_rec IS NULL THEN
  			ELSE
          SELECT * INTO source_data FROM nodes_data_routing WHERE nodes_data_routing.id = source_rec.data_id;
          SELECT * INTO target_data FROM nodes_data_routing WHERE nodes_data_routing.id = target_rec.data_id;
  				edge_geom = ST_SetSRID(edge_geom, 4326);          
 -- 				RAISE NOTICE 'inserting geom: %', ST_AsText(edge_geom); 
--          RAISE NOTICE 'inserting data: wayid = %, paid = %, oneway = %, isinside = %, speedfw = %, speedbw = %, length = %, roadtype = %, state = %, sourceid = %, targetid = %, sourcelon = %, sourcelat = %, targetlon = %, targetlat = %, geom = %', way.id, paid, oneway, false, speed_fw, speed_bw,(ST_Length(edge_geom, true) / 1000), road_type, 'CZ'::character(2), source_rec.id, target_rec.id,ST_X(source_rec.geom) * 10000000,ST_Y(source_rec.geom) * 10000000, ST_X(target_rec.geom) * 10000000, ST_Y(target_rec.geom) * 10000000, ST_AsText(edge_geom) ;
  				INSERT INTO edges_data_routing 
  					(osm_id, is_paid, is_inside, length, road_type, state, geom, source_lon, source_lat, target_lon, target_lat)
  					VALUES
  					(way.id::bigint							-- osm_id
  					, paid									-- is_paid
  					, false									-- is_inside
  					, (ST_Length(edge_geom, true) / 1000)	-- length
  					, road_type							-- road_type
  					, 'CZ'::character(2)					-- state
  					, edge_geom								-- geom  
  					, ST_X(source_data.geom) * 10000000		-- source_longitude
  					, ST_Y(source_data.geom) * 10000000		-- source_latitude
  					, ST_X(target_data.geom) * 10000000		-- target_longitude
  					, ST_Y(target_data.geom) * 10000000		-- target_latitude
  					) RETURNING id INTO data_key;
          INSERT INTO edges_routing 
  					(data_id, speed, is_forward, source_id, target_id)
  					VALUES
  					(data_key							-- osm_id
  					, speed_fw								-- speed_forward
            , true
  					, source_rec.id							-- source_id
  					, target_rec.id							-- target_id
  					);
          IF oneway IS FALSE THEN
            INSERT INTO edges_routing 
    					(data_id, speed, is_forward, source_id, target_id)
    					VALUES
    					(data_key							-- osm_id
    					, speed_bw								-- speed_forward
              , false
    					, target_rec.id							-- source_id
    					, source_rec.id							-- target_id
    					);
          END IF;
  				edge_geom := ST_MakeLine(node_array[counter]);
 -- 				RAISE NOTICE 'geom after insert: %', ST_AsText(edge_geom); 
  --				counter := counter - 1;
  			END IF;
  			source_rec := node_rec;
  		END IF;
  	END LOOP;
END LOOP;
END $$;

DROP FUNCTION IF EXISTS public."_parseSpeedFromMaxspeed"(hstore, text);

-- Index: public.edges_routing_osm_id_idx

-- DROP INDEX public.edges_routing_osm_id_idx;

CREATE INDEX edges_data_routing_osm_id_idx
  ON public.edges_data_routing
  USING btree
  (osm_id);    

-- Index: public.edges_routing_source_lat_idx

-- DROP INDEX public.edges_routing_source_lat_idx;

CREATE INDEX edges_data_routing_source_lat_idx
  ON public.edges_data_routing
  USING btree
  (source_lat);

-- Index: public.edges_routing_source_lon_idx

-- DROP INDEX public.edges_routing_source_lon_idx;

CREATE INDEX edges_data_routing_source_lon_idx
  ON public.edges_data_routing
  USING btree
  (source_lon);

-- Index: public.edges_routing_target_lat_idx

-- DROP INDEX public.edges_routing_target_lat_idx;

CREATE INDEX edges_data_routing_target_lat_idx
  ON public.edges_data_routing
  USING btree
  (target_lat);

-- Index: public.edges_routing_target_lon_idx

-- DROP INDEX public.edges_data_routing_target_lon_idx;

CREATE INDEX edges_data_routing_target_lon_idx
  ON public.edges_data_routing
  USING btree
  (target_lon);
  
CREATE INDEX edges_data_routing_geom_idx
  ON public.edges_data_routing
  USING gist
  (geom);


-- Index: public.edges_routing_id_idx

-- DROP INDEX public.edges_routing_id_idx;

CREATE INDEX edges_routing_id_idx
  ON public.edges_routing
  USING btree
  (id);

  
-- Index: public.edges_routing_osm_id_idx
-- DROP INDEX public.edges_routing_osm_id_idx;

CREATE INDEX edges_data_routing_id_idx
  ON public.edges_routing
  USING btree
  (data_id);

-- Index: public.fki_nodes_source_idx

-- DROP INDEX public.fki_nodes_source_idx;

CREATE INDEX fki_nodes_source_idx
  ON public.edges_routing
  USING btree
  (source_id);

-- Index: public.fki_nodes_target_idx

-- DROP INDEX public.fki_nodes_target_idx;

CREATE INDEX fki_nodes_target_idx
  ON public.edges_routing
  USING btree
  (target_id);
