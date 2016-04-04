DROP TABLE IF EXISTS public.edges_routing;
DROP TABLE IF EXISTS public.edges_data_routing;
DROP TABLE IF EXISTS public.nodes_routing;    
DROP TABLE IF EXISTS public.nodes_data_routing;
DROP TABLE IF EXISTS public.traffic_speed_map;
DROP TABLE IF EXISTS public.traffic_zones;
DROP TABLE IF EXISTS public.speed_map;
DROP TABLE IF EXISTS public.road_types;
DROP SEQUENCE IF EXISTS public.edges_routing_inc; 
DROP SEQUENCE IF EXISTS public.edges_data_routing_inc;
DROP SEQUENCE IF EXISTS public.nodes_routing_inc; 
DROP SEQUENCE IF EXISTS public.nodes_data_routing_inc;

-- ***************************** EDGE SEQUENCE *****************************
-- Sequence: public.edges_routing_inc
-- DROP SEQUENCE public.edges_routing_inc;

CREATE SEQUENCE public.edges_routing_inc
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.edges_routing_inc
  OWNER TO postgres;
  
-- ***************************** EDGE DATA SEQUENCE *****************************
-- Sequence: public.edges_routing_inc
-- DROP SEQUENCE public.edges_routing_inc;

CREATE SEQUENCE public.edges_data_routing_inc
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.edges_data_routing_inc
  OWNER TO postgres;
                                
-- ***************************** NODE SEQUENCE *****************************
-- Sequence: public.nodes_routing_inc
-- DROP SEQUENCE public.nodes_routing_inc;

CREATE SEQUENCE public.nodes_routing_inc
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.nodes_routing_inc
  OWNER TO postgres;

-- ***************************** NODE DATA SEQUENCE *****************************
-- Sequence: public.edges_routing_inc
-- DROP SEQUENCE public.edges_routing_inc;

CREATE SEQUENCE public.nodes_data_routing_inc
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.nodes_data_routing_inc
  OWNER TO postgres;

-- ***************************** ROAD TYPES *****************************
-- Table: public.road_types
-- DROP TABLE public.road_types;

CREATE TABLE public.road_types
(
  type_id integer NOT NULL,
  name text,
  CONSTRAINT road_types_pkey PRIMARY KEY (type_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.road_types
  OWNER TO postgres;

-- Index: public.road_types_type_id_idx

-- DROP INDEX public.road_types_type_id_idx;

CREATE INDEX road_types_type_id_idx
  ON public.road_types
  USING btree
  (type_id);

-- ***************************** SPEED MAP *****************************
-- Table: public.speed_map
-- DROP TABLE public.speed_map;

CREATE TABLE public.speed_map
(
  type_id integer NOT NULL,
  state character(2) NOT NULL,
  speed_inside integer,
  speed_outside integer,
  CONSTRAINT speed_map_pkey PRIMARY KEY (type_id, state)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.speed_map
  OWNER TO postgres;

-- Index: public.speed_map_road_type_state_idx
-- DROP INDEX public.speed_map_road_type_state_idx;
CREATE INDEX speed_map_road_type_state_idx
  ON public.speed_map
  USING btree
  (type_id, state COLLATE pg_catalog."default");
  
  
-- ***************************** TRAFFIC ZONES *****************************
-- Table: public.traffic_zones
-- DROP TABLE public.traffic_zones;

CREATE TABLE public.traffic_zones
(
  zone_id integer NOT NULL,
  name text,
  CONSTRAINT traffic_zones_pkey PRIMARY KEY (zone_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.traffic_zones
  OWNER TO postgres;

-- Index: public.traffic_zones_zone_id_idx
-- DROP INDEX public.traffic_zones_zone_id_idx;

CREATE INDEX traffic_zones_zone_id_idx
  ON public.traffic_zones
  USING btree
  (zone_id);
  
-- ***************************** TRAFFIC SPEED MAP *****************************
-- Table: public.traffic_speed_map
-- DROP TABLE public.traffic_speed_map;

CREATE TABLE public.traffic_speed_map
(
  zone_id integer NOT NULL,
  state character(2) NOT NULL,
  speed_inside integer,
  speed_outside integer,
  CONSTRAINT traffic_speed_map_pkey PRIMARY KEY (zone_id, state)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.traffic_speed_map
  OWNER TO postgres;

-- Index: public.traffic_speed_map_traffic_zone_state_idx
-- DROP INDEX public.traffic_speed_map_traffic_zone_state_idx;

CREATE INDEX traffic_speed_map_traffic_zone_state_idx
  ON public.traffic_speed_map
  USING btree
  (zone_id, state COLLATE pg_catalog."default");


-- ***************************** NODES DATA *****************************
-- Table: public.nodes_routing
-- DROP TABLE public.nodes_routing;

CREATE TABLE public.nodes_data_routing
(
  id bigint NOT NULL DEFAULT nextval('nodes_data_routing_inc'::regclass),
  osm_id bigint,
  state character(2),
  geom geometry(Point,4326),
  CONSTRAINT nodes_data_routing_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.nodes_data_routing
  OWNER TO postgres;

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

-- ***************************** NODES *****************************
-- Table: public.nodes_routing
-- DROP TABLE public.nodes_routing;

CREATE TABLE public.nodes_routing
(
  id bigint NOT NULL DEFAULT nextval('nodes_routing_inc'::regclass),
  data_id bigint,
  CONSTRAINT nodes_routing_pkey PRIMARY KEY (id),
  CONSTRAINT nodes_data_idx FOREIGN KEY (data_id)
      REFERENCES public.nodes_data_routing (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.nodes_routing
  OWNER TO postgres;

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
  


  
-- ***************************** EDGES DATA *****************************
-- Table: public.edges_data_routing
-- DROP TABLE public.edges_data_routing;  
CREATE TABLE public.edges_data_routing
(
  id bigint NOT NULL DEFAULT nextval('edges_data_routing_inc'::regclass),
  osm_id bigint,
  is_paid boolean,
  is_inside boolean,
  length double precision,
  road_type integer,
  state character(2),
  geom geometry(Geometry,4326),
  source_lat integer,
  source_lon integer,
  target_lat integer,
  target_lon integer, 
  CONSTRAINT edges_data_routing_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.edges_data_routing
  OWNER TO postgres;


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


-- ***************************** EDGES *****************************
-- Table: public.edges_routing
-- DROP TABLE public.edges_routing;

CREATE TABLE public.edges_routing
(
  id bigint NOT NULL DEFAULT nextval('edges_routing_inc'::regclass),
  data_id bigint,
  speed integer,
  source_id bigint,
  target_id bigint,
  CONSTRAINT edges_routing_pkey PRIMARY KEY (id),
  CONSTRAINT nodes_source_idx FOREIGN KEY (source_id)
      REFERENCES public.nodes_routing (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT nodes_target_idx FOREIGN KEY (target_id)
      REFERENCES public.nodes_routing (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT edges_data_idx FOREIGN KEY (data_id)
      REFERENCES public.edges_data_routing (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.edges_routing
  OWNER TO postgres;

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
