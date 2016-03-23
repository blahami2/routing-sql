-- INSERT ROAD TYPES
INSERT INTO road_types (type_id, name)
VALUES 
  (1, 'motorway'),
  (2, 'primary'),
  (3, 'secondary'),
  (4, 'tertiary'),
  (5, 'trunk'),
  (6, 'unclassified'),
  (7, 'residential'),
  (8, 'living_street');

-- INSERT NODES
-- warning: valid_nodes view has to exist

INSERT INTO nodes_routing (osm_id, is_inside, state, geom)
SELECT id, FALSE, 'CZ', geom FROM valid_nodes   -- adjust state? based on political areas recalculate

-- INSERT EDGES
-- warning: valid_ways view has to exist

-- call _divideWay.sql

