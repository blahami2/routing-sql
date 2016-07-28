DROP TABLE IF EXISTS public.turn_restrictions;
DROP TABLE IF EXISTS public.turn_restrictions_array; 
DROP SEQUENCE IF EXISTS public.turn_restrictions_inc;

CREATE SEQUENCE public.turn_restrictions_inc
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;
ALTER TABLE public.turn_restrictions_inc
  OWNER TO postgres; 

CREATE TABLE public.turn_restrictions
(
  from_id bigint NOT NULL DEFAULT nextval('turn_restrictions_inc'::regclass), -- sequence of edges to the last node; NOT NULL DEFAULT nextval('turn_restrictions_inc'::regclass)
  via_id bigint, -- last node before the last edge
  to_id bigint -- last edge
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.turn_restrictions
  OWNER TO postgres;
 
  
CREATE TABLE public.turn_restrictions_array
(
  array_id bigint, -- turn_restrictions.from
  position integer, -- position of this row in the array
  edge_id bigint -- id of the edge in this array on the given position
)
WITH (
  OIDS=FALSE
);

ALTER TABLE public.turn_restrictions_array
  OWNER TO postgres;


DO $$
DECLARE         
	relation relations%rowtype;   
  edge edges_view%rowtype;  
  edge_from edges_view%rowtype;  
  edge_to edges_view%rowtype;
  node nodes_view%rowtype;
  array_id_inserted bigint;
BEGIN
-- for all nodes that are in valid restrictions (where valid means it is not a restriction into an opposite oneway and it applies to cars)
FOR relation IN (
  SELECT r.* 
  FROM relations r
  JOIN relation_members rm ON r.id = rm.relation_id 
	WHERE (
		exist(r.tags,'restriction')
		AND rm.member_role = 'via'
    AND rm.member_type = 'N'
		AND (
			NOT EXIST(r.tags,'except')
			OR r.tags->'except' NOT LIKE '%motorcar%'
		)
	)  
) LOOP
  RAISE NOTICE 'relation = %', relation;
  SELECT * INTO node FROM nodes_view n JOIN relation_members rm ON n.osm_id = rm.member_id WHERE rm.relation_id = relation.id AND rm.member_role = 'via' AND rm.member_type = 'N';
  RAISE NOTICE 'node = %', node;   
	SELECT e.* INTO edge_from 
  	FROM edges_view e
  	JOIN nodes_routing target_n ON e.target_id = target_n.id 
  	JOIN relation_members rm ON e.osm_id = rm.member_id 
  	WHERE (
      rm.relation_id = relation.id
      AND rm.member_role = 'from'
      AND target_n.data_id = node.data_id
  );
  RAISE NOTICE 'edge_from = %', edge_from;
  SELECT e.* INTO edge_to
    FROM edges_view e
		JOIN nodes_routing source_n ON e.source_id = source_n.id 
    JOIN relation_members rm ON e.osm_id = rm.member_id
    WHERE (
      rm.relation_id = relation.id
      AND rm.member_role = 'to'
      AND source_n.data_id = node.data_id
  );           
  RAISE NOTICE 'edge_to = %', edge_to;
  IF edge_from IS NOT NULL AND node IS NOT NULL AND edge_to IS NOT NULL THEN
    IF relation.tags->'restriction' LIKE 'no_%' THEN
      INSERT INTO turn_restrictions (via_id, to_id) VALUES (node.data_id, edge_to.data_id) RETURNING from_id INTO array_id_inserted;
      INSERT INTO turn_restrictions_array (array_id, position, edge_id) VALUES (array_id_inserted, 0, edge_from.data_id);
    END IF;
  	IF relation.tags->'restriction' LIKE 'only_%' THEN
    -- INSERT ALL OTHER
      FOR edge IN (
        SELECT e.* FROM edges_view e
        JOIN nodes_view n ON n.id = e.source_id
        WHERE (
          e.source_id = edge_to.source_id
          AND e.id <> edge_to.id
          AND n.data_id = node.data_id
        )
      ) LOOP
        INSERT INTO turn_restrictions (via_id, to_id) VALUES (node.data_id, edge.data_id) RETURNING from_id INTO array_id_inserted;
        INSERT INTO turn_restrictions_array (array_id, position, edge_id) VALUES (array_id_inserted, 0, edge_from.data_id);
      END LOOP;
    END IF;
  END IF;
END LOOP;
END $$;

