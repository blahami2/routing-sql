-- INDEX

-- Index: public.road_types_type_id_idx

-- DROP INDEX public.road_types_type_id_idx;

CREATE INDEX road_types_type_id_idx
  ON public.road_types
  USING btree
  (type_id);


-- Index: public.speed_map_road_type_state_idx
-- DROP INDEX public.speed_map_road_type_state_idx;
CREATE INDEX speed_map_road_type_state_idx
  ON public.speed_map
  USING btree
  (type_id, state COLLATE pg_catalog."default");

-- Index: public.traffic_zones_zone_id_idx
-- DROP INDEX public.traffic_zones_zone_id_idx;

CREATE INDEX traffic_zones_zone_id_idx
  ON public.traffic_zones
  USING btree
  (zone_id);

-- Index: public.nodes_routing_id_idx

-- DROP INDEX public.nodes_routing_id_idx;

CREATE INDEX nodes_data_routing_id_idx
  ON public.nodes_data_routing
  USING btree
  (id);

-- Index: public.nodes_routing_osm_id_idx

-- DROP INDEX public.nodes_routing_osm_id_idx;

CREATE INDEX nodes_data_routing_osm_id_idx
  ON public.nodes_data_routing
  USING btree
  (osm_id);
  
CREATE INDEX nodes_data_routing_geom_idx
  ON public.nodes_data_routing
  USING gist
  (geom);


-- Index: public.nodes_routing_id_idx

-- DROP INDEX public.nodes_routing_id_idx;

CREATE INDEX nodes_routing_id_idx
  ON public.nodes_routing
  USING btree
  (id);

-- Index: public.nodes_routing_osm_id_idx

-- DROP INDEX public.nodes_routing_osm_id_idx;

CREATE INDEX nodes_routing_data_id_idx
  ON public.nodes_routing
  USING btree
  (data_id);
  

CREATE INDEX idx_nodes_routing_geom ON nodes USING gist (geom);