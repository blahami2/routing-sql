DO $$
DECLARE
	relation relations%rowtype;
	node nodes_routing%rowtype;
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
BEGIN
-- for all nodes that are in valid restrictions (where valid means it is not a restriction into an opposite oneway and it applies to cars)
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
	-- Create nodes for outgoing edges
	-- - get outgoing edges
	-- - get neighbour nodes
	-- - create new array (2D) and add these nodes to the array
	node_array := NULL;
	neighbour_array := NULL;
	FOR edge IN (SELECT e.* FROM edges_routing e 
		WHERE (
			e.source_id = node.id
			OR (
				e.target_id = node.id
	--			AND e.is_oneway IS FALSE
			)
		)
	) LOOP
		IF edge.source_id = node.id THEN
			node_array := array_append(node_array, edge.target_id);
		ELSE
			node_array := array_append(node_array, edge.source_id);
		END IF;
	END LOOP;
	node_count := array_length(node_array, 1);
	-- Connect all to all
	-- - add all other nodes into the array for each neighbour node
	FOR i IN 1..node_count LOOP
		FOR j IN 1..node_count LOOP
			IF i <> j THEN
--				neighbour_array[i][j] := node_array[i];
				neighbour_array := array_append(neighbour_array, node_array[j]);
			ELSE
				neighbour_array := array_append(neighbour_array, -1::bigint);
--				neighbour_array[i][j] := -1::bigint;
			END IF;
		END LOOP;
	END LOOP;

-- DEBUG PRINT
	RAISE NOTICE 'node_array print: %', node_array;
	RAISE NOTICE 'neighbour_array print: %', neighbour_array;
	
	-- - remove paths from nodes to opposite oneway neighbour
	FOR edge IN (SELECT e.* FROM edges_routing e 
		WHERE (
			e.target_id = node.id
			AND e.is_oneway IS TRUE
		)
	) LOOP
		FOR i IN 1..array_length(neighbour_array,1) LOOP
			IF edge.source_id = neighbour_array[i] THEN
				neighbour_array[i] := -1::bigint;
			END IF;
		END LOOP;
	END LOOP;

-- DEBUG PRINT
--	FOR i IN 1..array_length(node_array,1) LOOP
--		RAISE NOTICE '[%]: %',i, node_array[i];
--	END LOOP;
	RAISE NOTICE 'neighbour_array print: %', neighbour_array;
--	FOR i IN 1..node_count LOOP
--		FOR j IN 1..node_count LOOP
--			RAISE NOTICE '[%][%]: %', i,j, neighbour_array[(i-1)*node_count + j];
--		END LOOP;
--	END LOOP;
	
	-- Forall valid restrictions
	FOR relation IN (
		SELECT DISTINCT r.* FROM
		relations r
		JOIN relation_members rm ON r.id = rm.relation_id
		JOIN edges_routing e ON rm.member_id = e.osm_id
		WHERE (
			exist(r.tags,'restriction')
			AND (
				(
					rm.member_role = 'to'
					AND (
						node.id = e.source_id
						OR (
							node.id = e.target_id 
							AND e.is_oneway IS FALSE
						)
					)
				)	 
			)
			AND (
				NOT EXIST(r.tags,'except')
				OR r.tags->'except' NOT LIKE '%motorcar%'
			)
		)
	) LOOP
		RAISE NOTICE 'relation id = %', relation.id;
		RAISE NOTICE 'node id = %', node.id;
		-- get relation members (from, to)
		SELECT e.* INTO edge_from FROM edges_routing e JOIN relation_members rm ON e.osm_id = rm.member_id WHERE (rm.relation_id = relation.id AND rm.member_role = 'from' AND (e.target_id = node.id OR e.source_id = node.id));
		SELECT e.* INTO edge_to FROM edges_routing e JOIN relation_members rm ON e.osm_id = rm.member_id WHERE (rm.relation_id = relation.id AND rm.member_role = 'to' AND (e.target_id = node.id OR e.source_id = node.id));

		IF edge_from.target_id = node.id THEN
			node_from_id := edge_from.source_id;
		ELSE
			node_from_id := edge_from.target_id;
		END IF;
		IF edge_to.target_id = node.id THEN
			node_to_id := edge_to.source_id;
		ELSE
			node_to_id := edge_to.target_id;
		END IF;
		
		-- no_* => remove connection
		-- - remove 'to' edge/node from 'from' edge/node
		IF relation.tags->'restriction' LIKE 'no_%' THEN
			RAISE NOTICE 'removing % -> % from connections', edge_from.id, edge_to.id;
			RAISE NOTICE 'nodes: % - > %', node_from_id, node_to_id;
			idx := array_position(node_array,node_from_id);
			FOR i IN ((idx-1)*node_count + 1)..((idx-1)*node_count + node_count) LOOP
				IF neighbour_array[i] = node_to_id THEN
					neighbour_array[i] = -1::bigint;
				END IF;
			END LOOP;
		END IF;
		-- only_* => remove all other connections
		-- - remove all but 'to' edge/node from 'from' edge/node
		IF relation.tags->'restriction' LIKE 'only_%' THEN
			RAISE NOTICE 'removing all but % -> % from connections', edge_from.id, edge_to.id;
			RAISE NOTICE 'nodes: % - > %', node_from_id, node_to_id;
			idx := array_position(node_array,node_from_id);
			FOR i IN ((idx-1)*node_count + 1)..((idx-1)*node_count + node_count) LOOP
				IF neighbour_array[i] <> node_to_id THEN
					neighbour_array[i] = -1::bigint;
				END IF;
			END LOOP;
		END IF;
		
	END LOOP;
	
-- DEBUG PRINT
	RAISE NOTICE 'neighbour_array print: %', neighbour_array;
	-- Create crossroad
	-- - create new node for each outgoing edge
	-- - for each neighbour node
	-- - - clone edge to crossroad and connect it to new nodes according to the neighbour array
END LOOP;

END $$;

