DO $$
DECLARE
	relation relations%rowtype;
	node nodes_routing%rowtype;
	node_data nodes_data_routing%rowtype;
	new_node nodes_routing%rowtype;
	source_node nodes_routing%rowtype;
	edge edges_routing%rowtype;
	node_array bigint[];
	tmp_array bigint[];
	neighbour_array bigint[];
	idx integer;
	idx2 integer;
	node_count integer;
	edge_from edges_routing%rowtype;
	edge_to edges_routing%rowtype;
	node_from_id bigint;
	node_to_id bigint;
	dist_data_id bigint;
	new_node_id bigint;
BEGIN
ALTER TABLE nodes_routing ADD COLUMN target_data_id bigint;
-- for all nodes that are in valid restrictions (where valid means it is not a restriction into an opposite oneway and it applies to cars)
FOR node IN (
	SELECT DISTINCT n.* FROM
	relation_members rm JOIN
	(	SELECT DISTINCT r.* FROM
		relations r
		JOIN relation_members rm ON r.id = rm.relation_id
		JOIN edges_data_routing d ON rm.member_id = d.osm_id
		JOIN edges_routing e ON e.data_id = d.id
		JOIN (SELECT n.* 
			FROM relations r 
			JOIN relation_members rm ON r.id = rm.relation_id
			JOIN nodes_data_routing nd ON rm.member_id = nd.osm_id 
			JOIN nodes_routing n ON n.data_id = nd.id
			WHERE (
				exist(r.tags,'restriction')
			)
		) AS nodes ON (e.source_id = nodes.id)
		WHERE (
			exist(r.tags,'restriction')
			AND (
				(
					rm.member_role = 'to'
					AND (
						nodes.id = e.source_id
					)
				)	 
			)
			AND (
				NOT EXIST(r.tags,'except')
				OR r.tags->'except' NOT LIKE '%motorcar%'
			)
		)
	) AS rels
	ON rm.relation_id = rels.id
	JOIN nodes_data_routing nd ON nd.osm_id = rm.member_id
	JOIN nodes_routing n ON n.data_id = nd.id
	ORDER BY n.id
) LOOP
	SELECT * INTO node_data FROM nodes_data_routing WHERE nodes_data_routing.id = node.data_id;
	-- Foreach distinct data_id, edges join nodes where source = node
	FOR dist_data_id IN (
		SELECT DISTINCT n.data_id FROM edges_routing e JOIN nodes_routing n ON e.target_id = n.id WHERE e.source_id = node.id
	) LOOP
		-- clone node -> new_node
		INSERT INTO nodes_routing (data_id, target_data_id) VALUES (node.data_id, dist_data_id) RETURNING id INTO new_node_id; 
		-- connect node to target
		-- - update edges set source = new_node where target = data_id
		UPDATE edges_routing SET source_id = new_node_id WHERE id IN (SELECT e.id FROM edges_routing e JOIN nodes_routing n ON e.target_id = n.id WHERE (e.source_id = node.id AND n.data_id = dist_data_id));
	END LOOP;
	-- Foreach edge where target = crossroad
	FOR edge IN (
		SELECT * FROM edges_routing e WHERE e.target_id = node.id
	) LOOP
		SELECT * INTO source_node FROM nodes_routing n WHERE n.id = edge.source_id;
		-- foreach new_node where data_id = crossroad.data_id and target_data_id <> edge.source.data_id
		FOR new_node IN (
			SELECT n.* FROM nodes_routing n JOIN nodes_data_routing nd ON n.data_id = nd.id WHERE (n.data_id = node.data_id AND n.id <> node.id AND n.target_data_id <> source_node.data_id ) 
		) LOOP
			-- clone edge -> new_edge
			-- update new_edge set target = node
			INSERT INTO edges_routing (data_id, speed, source_id, target_id) VALUES (edge.data_id, edge.speed, edge.source_id, new_node.id);
		END LOOP;
		-- delete old edge
		DELETE FROM edges_routing e WHERE e.id = edge.id;
	END LOOP;
	
	-- Forall valid restrictions
	FOR relation IN (
		SELECT DISTINCT r.* FROM
		relations r
		JOIN relation_members rm ON r.id = rm.relation_id
		JOIN edges_data_routing d ON rm.member_id = d.osm_id
		JOIN edges_routing e ON e.data_id = d.id
		JOIN nodes_routing n ON n.id = e.source_id
		WHERE (
			exist(r.tags,'restriction')
			AND (
				(
					rm.member_role = 'to'
					AND (
						node_data.id = n.data_id
					)
				)	 
			)
			AND (
				NOT EXIST(r.tags,'except')
				OR r.tags->'except' NOT LIKE '%motorcar%'
			)
		)
	) LOOP
--		RAISE NOTICE 'restrictions';
		-- select edge_from from edges_routing where member_role = 'from' and target.data_id = node.data_id
    SELECT e.* INTO edge_to
      FROM edges_routing e
      JOIN edges_data_routing d ON e.data_id = d.id 
			JOIN nodes_routing source_n ON e.source_id = source_n.id 
      JOIN relation_members rm ON d.osm_id = rm.member_id
      WHERE (
        rm.relation_id = relation.id
        AND rm.member_role = 'from'
        AND source_n.data_id = node.data_id
    );
		SELECT e.* INTO edge_from 
			FROM edges_routing e 
			JOIN edges_data_routing d ON e.data_id = d.id
			JOIN nodes_routing target_n ON e.target_id = target_n.id 
			JOIN relation_members rm ON d.osm_id = rm.member_id 
			WHERE (
				rm.relation_id = relation.id 
				AND rm.member_role = 'from' 
				AND target_n.data_id = node.data_id
        AND target_n.target_data_id IN (
          SELECT 
          FROM 
        )
			);
		-- no_* => remove connection
		IF relation.tags->'restriction' LIKE 'no_%' THEN
		-- - remove 'from' edge
      RAISE NOTICE 'no way from % to %', edge_from.source_id, edge_from.target_id;
			DELETE FROM edges_routing e WHERE e.id = edge_from.id; 
		END IF;
		-- only_* => remove all other connections
		IF relation.tags->'restriction' LIKE 'only_%' THEN
		-- - remove all but 'from' edge                   
      RAISE NOTICE 'only way from % to %', edge_from.source_id, edge_from.target_id;
			DELETE FROM edges_routing WHERE edges_routing.id IN (
				SELECT e.id
				FROM edges_routing e
				JOIN nodes_routing target_n ON e.target_id = target_n.id
				WHERE (
					e.source_id = edge_from.source_id
					AND e.id <> edge_from.id
					AND target_n.data_id = node.data_id
				)
			);
		END IF;		
	END LOOP;
	-- Delete old node
	DELETE FROM nodes_routing n WHERE n.id = node.id;
END LOOP;

ALTER TABLE nodes_routing DROP COLUMN target_data_id;
END $$;

