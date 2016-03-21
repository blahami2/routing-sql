/*
SELECT ST_AsText((dump::geometry_dump).geom), (dump::geometry_dump).path[1]  FROM (
SELECT 
--	id,
--	ST_AsText(
		(ST_Dump(
			ST_Split(
				linestring, 
				ST_Snap(
					ST_Union(
						ST_SetSRID(ST_MakePoint(14.5763739, 50.0910499),4326),ST_SetSRID(ST_MakePoint(14.576333, 50.0910358),4326)
						--(SELECT geom FROM nodes_routing) 
					)
					,linestring
					,0.00000001
				)
			)
		)) AS dump
--	) AS geom 
--""LINESTRING(14.5763739 50.0910499,14.576333 50.0910358,14.5761384 50.0909768,14.5763839 50.0905841,14.5765713 50.0900869,14.5767254 50.0898754,14.5770473 50.0894581)"
FROM ways 
WHERE (
	id = 1614262
) 
) AS dumb
ORDER BY (dump::geometry_dump).path[1]
*/

 /*
SELECT ST_AsText(
			ST_Split(
				linestring, 
				ST_Snap(
					ST_Union(
						ST_SetSRID(ST_MakePoint(14.5763739, 50.0910499),4326),ST_SetSRID(ST_MakePoint(14.576333, 50.0910358),4326)
						--(SELECT geom FROM nodes_routing) 
					)
					,linestring
					,0.00000001
				)
			)
		)
FROM ways
WHERE id = 1614262;
*/

--UNION
--SELECT ST_AsText(linestring) AS geom
--ST_Split(
--	linestring, 
--	ST_MakeLine(
--		ST_SetSRID(ST_MakePoint(14.4404817,50.1093514),4326),
--		ST_SetSRID(ST_MakePoint(14.4404817,50.1093514),4326)
--	)
--) AS geom 
--FROM ways 
--WHERE (
	--public."_isValidWay"(ways)
--	id = 106502246
--) 
;

/* select edges with nodes (osmid)
SELECT e.osm_id, ST_AsText(e.geom), sn.osm_id AS source, tn.osm_id AS target, e.length 
FROM edges_routing AS e 
JOIN nodes_routing AS sn
ON e.source_id = sn.id
JOIN nodes_routing AS tn
ON e.target_id = tn.id
WHERE e.osm_id = 1614262;
*/
