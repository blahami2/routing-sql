CREATE OR REPLACE VIEW valid_ways AS
SELECT * FROM ways WHERE public."_isValidWay"(ways);

CREATE OR REPLACE VIEW valid_nodes AS
SELECT nodes.*--, ST_AsX3D(geom) AS geom, amount, ST_AsText(nodes.geom) 
FROM nodes JOIN
        (SELECT res.node_id FROM
            (SELECT w.node_id, COUNT(*) AS amount FROM
                (SELECT unnest(fw.nodes) AS node_id,* FROM 
                    valid_ways AS fw 
                ) AS w 
            GROUP BY (w.node_id)) AS res
            WHERE (
                res.amount<>1 
                AND
                res.amount<>0
                ) 
        UNION
        SELECT nodes.id AS node_id FROM
	    nodes JOIN valid_ways AS ways
	    ON (nodes.id = ways.nodes[array_lower(nodes,1)] OR nodes.id = ways.nodes[array_upper(nodes,1)])
        ) AS valid
ON nodes.id = valid.node_id;

CREATE OR REPLACE VIEW restrictions AS
SELECT r.*, rm.*
FROM relations r
JOIN relation_members rm ON r.id = rm.relation_id
WHERE exist(r.tags, 'restriction');

CREATE OR REPLACE VIEW nodes_view AS
SELECT n.*, d.osm_id, d.state, d.geom 
FROM nodes_routing n
JOIN nodes_data_routing d ON n.data_id = d.id;

CREATE OR REPLACE VIEW edges_view AS
SELECT e.*, d.osm_id, d.is_paid, d.is_inside, d.length, d.road_type, d.state, d.geom, d.source_lat, d.source_lon, d.target_lat, d.target_lon
FROM edges_routing e
JOIN edges_data_routing d ON e.data_id = d.id;



