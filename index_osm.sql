-- Add indexes to tables.
CREATE INDEX idx_nodes_geom ON nodes USING gist (geom);

CREATE INDEX idx_way_nodes_node_id ON way_nodes USING btree (node_id);

CREATE INDEX idx_relation_members_member_id_and_type ON relation_members USING btree (member_id, member_type);


CREATE INDEX nodes_id_idx
  ON public.nodes
  USING btree
  (id);
  
CREATE INDEX relation_members_member_id_idx
  ON public.relation_members
  USING btree
  (member_id);

-- Index: public.relation_members_relation_id_idx

-- DROP INDEX public.relation_members_relation_id_idx;

CREATE INDEX relation_members_relation_id_idx
  ON public.relation_members
  USING btree
  (relation_id);
  

  
CREATE INDEX relations_id_idx
  ON public.relations
  USING btree
  (id);
  
CREATE INDEX ways_id_idx
  ON public.ways
  USING btree
  (id);

CREATE INDEX idx_ways_linestring
  ON public.ways
  USING gist
  (linestring);