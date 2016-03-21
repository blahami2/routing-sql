SELECT 
	id,
	ST_AsText(
		(ST_Dump(
			ST_Split(
				linestring, 
				ST_Snap(
					ST_Union(
						ST_SetSRID(ST_MakePoint(14.4404817, 50.1093514),4326),ST_SetSRID(ST_MakePoint(14.4392107, 50.1092536),4326)
						--(SELECT geom FROM nodes_routing) 
					)
					,linestring
					,0.00000001
				)
			)
		)).geom
	) AS geom 
--"LINESTRING(14.4418276 50.1096055,14.4412761 50.1095044,14.4408275 50.1094096,,14.4400379 50.109298,14.4393789 50.1092637,14.4392107 50.1092536,14.4388453 50.1092406)"
FROM ways 
WHERE (
	id = 106502246
) 
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