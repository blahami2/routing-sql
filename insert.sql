-- INSERT ROAD TYPES
INSERT INTO road_types (type_id, name)
VALUES 
  (1, 'motorway'), 
  (2, 'trunk'),
  (3, 'primary'),
  (4, 'secondary'),
  (5, 'tertiary'),
  (6, 'unclassified'),
  (7, 'residential'),
  (8, 'living_street');

-- INSERT VALUES INTO SPEED MAP
DELETE FROM speed_map;
INSERT INTO speed_map (type_id, state, speed_inside, speed_outside)
VALUES 
  (1, 'CZ', 80, 130),
  (2,'CZ',50,90),
  (3,'CZ',50,90),
  (4,'CZ',50,90),
  (5,'CZ',50,90),
  (6,'CZ',50,90),
  (7,'CZ',50,90),
  (8,'CZ',20,20),
  (1,'DE',80,150),
  (2,'DE',50,130),
  (3,'DE',50,100),
  (4,'DE',50,100),
  (5,'DE',50,100),
  (6,'DE',50,100),
  (7,'DE',50,100),
  (8,'DE',7,7);
  
-- INSERT TRAFFIC ZONES
INSERT INTO traffic_zones (zone_id, name)
VALUES
  (1, 'motorway'),
  (2, 'trunk'),
  (3, 'rural'),
  (4, 'urban'),
  (5, 'living_street');
   
-- INSERT VALUES INTO TRAFFIC SPEED MAP
INSERT INTO traffic_speed_map (zone_id, state, speed_inside, speed_outside)
VALUES
  (1,'AT',130,130),
  (2,'AT',100,100),
  (3,'AT',100,100),
  (4,'AT',50,50),
  (5,'AT',20,20),
  (1,'CH',120,120),
  (2,'CH',100,100),
  (3,'CH',80,80),
  (4,'CH',50,50),
  (5,'CH',20,20),
  (1,'CZ',80,130),
  (2,'CZ',80,130),
  (3,'CZ',90,90),
  (4,'CZ',50,50),
  (5,'CZ',20,20),
  (1,'DE',150,150),
  (2,'DE',100,100),
  (3,'DE',100,100),
  (4,'DE',50,50),
  (5,'DE',7,7),
  (1,'FI',120,120),
  (2,'FI',100,100),
  (3,'FI',80,80),
  (4,'FI',50,50),
  (5,'FI',20,20),
  (1,'FR',130,130),
  (2,'FR',110,110),
  (3,'FR',90,90),
  (4,'FR',50,50),
  (5,'FR',20,20),
  (1,'HU',130,130),
  (2,'HU',110,110),
  (3,'HU',90,90),
  (4,'HU',50,50),
  (5,'HU',20,20),
  (1,'IT',130,130),
  (2,'IT',110,110),
  (3,'IT',90,90),
  (4,'IT',50,50),
  (5,'IT',20,20),
  (1,'RO',130,130),
  (2,'RO',100,100),
  (3,'RO',90,90),
  (4,'RO',50,50),
  (5,'RO',20,20),
  (1,'RU',110,110),
  (2,'RU',110,110),
  (3,'RU',90,90),
  (4,'RU',60,60),
  (5,'RU',20,20),
  (1,'SK',90,130),
  (2,'SK',90,130),
  (3,'SK',90,90),
  (4,'SK',50,50),
  (5,'SK',20,20),
  (1,'SI',130,130),
  (2,'SI',110,110),
  (3,'SI',90,90),
  (4,'SI',50,50),
  (5,'SI',20,20),
  (1,'SE',110,110),
  (2,'SE',90,90),
  (3,'SE',70,70),
  (4,'SE',50,50),
  (5,'SE',20,20),
  (1,'GB',112,112),
  (2,'GB',95,95),
  (3,'GB',95,95),
  (4,'GB',50,50),
  (5,'GB',20,20),
  (1,'UA',130,130),
  (2,'UA',110,110),
  (3,'UA',90,90),
  (4,'UA',60,60),
  (5,'UA',20,20);

-- INSERT NODES
-- warning: valid_nodes view has to exist

INSERT INTO nodes_data_routing (osm_id, state, geom)
SELECT id, 'CZ', geom FROM valid_nodes;   -- adjust state? based on political areas recalculate

INSERT INTO nodes_routing (data_id)
SELECT id FROM nodes_data_routing;

-- INSERT EDGES
-- warning: valid_ways view has to exist

-- call _divideWay.sql



