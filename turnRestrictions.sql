DO $$
DECLARE
	relation relations;
	node nodes_routing;
BEGIN

FOR node IN (
	SELECT DISTINCT n.* FROM
	relation_members rm JOIN
	(	SELECT DISTINCT r.* FROM
		relations r
		JOIN relation_members rm ON r.id = rm.relation_id
		JOIN edges_routing e ON rm.member_id = e.osm_id
		JOIN (SELECT n.* 
			FROM relations r 
			JOIN relation_members rm ON r.id = rm.relation_id 
			JOIN nodes_routing n ON rm.member_id = n.osm_id
			WHERE (
				exist(r.tags,'restriction')
			--	AND rm.member_type = 'N' 
			--	AND rm.member_role = 'via'
			)
		) AS nodes ON (e.target_id = nodes.id OR e.source_id = nodes.id)
		WHERE (
			exist(r.tags,'restriction')
			AND (
				(
					rm.member_role = 'to'
					AND (
						nodes.id = e.source_id
						OR (
							nodes.id = e.target_id 
							AND e.is_oneway IS FALSE
						)
					)
				)	 
		--		OR rm.member_role = 'from'
			)
			AND (
				NOT EXIST(r.tags,'except')
				OR r.tags->'except' NOT LIKE '%motorcar%'
			)
		)
	) AS rels
	ON rm.relation_id = rels.id
	JOIN nodes_routing n ON n.osm_id = rm.member_id
	ORDER BY n.id
) LOOP
	
END LOOP;

END $$;

