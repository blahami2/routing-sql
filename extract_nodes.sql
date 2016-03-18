--SELECT osm_id AS id--, ST_AsX3D(geom_vertex) AS geom 
--FROM prg_2po_vertex
--EXCEPT

SELECT nodes.*--, ST_AsX3D(geom) AS geom, amount, ST_AsText(nodes.geom) 
FROM nodes JOIN
        (SELECT res.node_id FROM
            (SELECT w.node_id, COUNT(*) AS amount FROM
                (SELECT unnest(fw.nodes) AS node_id,* FROM 
                    (SELECT * FROM ways WHERE (public."_isValidWay"(ways)) ) AS fw 
                ) AS w 
            GROUP BY (w.node_id)) AS res
            WHERE (
                res.amount<>1 
                AND
                res.amount<>0
                ) 
        UNION
        SELECT nodes.id AS node_id FROM
	    nodes JOIN (
		SELECT * FROM ways WHERE (public."_isValidWay"(ways))
	    ) AS ways
	    ON (nodes.id = ways.nodes[array_lower(nodes,1)] OR nodes.id = ways.nodes[array_upper(nodes,1)])
        ) AS valid
ON nodes.id = valid.node_id
--ORDER BY nodes.id



;