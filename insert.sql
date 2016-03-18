-- INSERT NODES

INSERT INTO nodes_routing (osm_id, is_inside, state, geom)
SELECT id, FALSE, 'CZ', geom FROM valid_nodes   -- adjust state?

