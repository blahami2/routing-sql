-- INSERT NODES
-- warning: valid_nodes view has to exist

INSERT INTO nodes_routing (osm_id, is_inside, state, geom)
SELECT id, FALSE, 'CZ', geom FROM valid_nodes   -- adjust state? based on political areas recalculate

-- INSERT EDGES
-- warning: valid_ways view has to exist

INSERT INTO edges_routing (osm_id)

