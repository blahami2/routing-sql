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
  road_type integer NOT NULL,
  state character(2) NOT NULL,
  speed_inside integer,
  speed_outside integer,
  CONSTRAINT speed_map_pkey PRIMARY KEY (road_type, state)
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
  (road_type, state COLLATE pg_catalog."default");

-- ***************************** NODES *****************************
-- Table: public.nodes_routing
-- DROP TABLE public.nodes_routing;

CREATE TABLE public.nodes_routing
(
  id bigint NOT NULL,
  osm_id bigint,
  geom geometry,
  is_inside boolean,
  state character(2),
  CONSTRAINT nodes_routing_pkey PRIMARY KEY (id)
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

CREATE INDEX nodes_routing_osm_id_idx
  ON public.nodes_routing
  USING btree
  (osm_id);

-- ***************************** EDGES *****************************
-- Table: public.edges_routing
-- DROP TABLE public.edges_routing;

CREATE TABLE public.edges_routing
(
  id bigint NOT NULL DEFAULT nextval('edges_routing_inc'::regclass),
  osm_id bigint,
  is_paid boolean,
  is_oneway boolean,
  is_inside boolean,
  speed_forward integer,
  speed_backward integer,
  length double precision,
  road_type integer,
  state character(2),
  geom geometry(Geometry,4326),
  source_id bigint,
  target_id bigint,
  CONSTRAINT edges_routing_pkey PRIMARY KEY (id),
  CONSTRAINT nodes_source_idx FOREIGN KEY (source_id)
      REFERENCES public.nodes_routing (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT nodes_target_idx FOREIGN KEY (target_id)
      REFERENCES public.nodes_routing (id) MATCH SIMPLE
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

CREATE INDEX edges_routing_osm_id_idx
  ON public.edges_routing
  USING btree
  (osm_id);

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

