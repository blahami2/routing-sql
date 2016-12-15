-- add table create scripts
-- Function: public."_setState"()
                
DROP TYPE IF EXISTS a5293eb9d34b3de; 
CREATE TYPE a5293eb9d34b3de AS (linestring geometry, sequence_id integer);

DROP FUNCTION IF EXISTS public."_create_areas"(adminLevel integer);
CREATE OR REPLACE FUNCTION _create_areas(adminLevel integer)
RETURNS void
AS $$
DECLARE
	way ways;
	relation relations;
	rel_member relation_members;
	edge edges_routing;
	linestring geometry;
	area geometry;
	area_approx geometry;
	member_id integer;
	x_min integer;
	x_max integer;
	y_min integer;
	y_max integer;
	counter integer := 0;
	total integer := 0;
	used_members integer[];
	area_id integer;
	relation_way a5293eb9d34b3de;
	node_data nodes_data_routing%rowtype;
	edge_data edges_data_routing%rowtype;
	node nodes_routing%rowtype;
	connector_source area_connectors%rowtype;
	connector_target area_connectors%rowtype;
	ad_area areas%rowtype;
BEGIN

FOR relation IN (SELECT * FROM relations WHERE (tags->'boundary' = 'administrative' AND to_number(tags->'admin_level','99') = adminLevel)) LOOP
	area := null;
	used_members := null;
	FOR member_id IN (SELECT rm.relation_id FROM relation_members AS rm JOIN ways AS w ON rm.member_id = w.id WHERE rm.relation_id = relation.id) LOOP
--		RAISE NOTICE 'member id = %', member_id;
		FOR relation_way IN (SELECT w.linestring, rm.sequence_id FROM relation_members AS rm JOIN ways AS w ON rm.member_id = w.id WHERE (rm.relation_id = relation.id AND ((used_members @> ARRAY[rm.sequence_id]) IS NULL OR (used_members @> ARRAY[rm.sequence_id]) IS FALSE)
		)) LOOP
			IF relation_way.linestring IS NULL THEN
			ELSE
--				RAISE NOTICE '% contains % = %',used_members,relation_way.sequence_id,(used_members @> ARRAY[relation_way.sequence_id]) ;
--				IF used_members @> ARRAY[relation_way.sequence_id] THEN
--				ELSE
					IF area IS NULL THEN
		--				RAISE NOTICE 'way: %', way;
						area := relation_way.linestring;
						used_members := array_append(used_members,relation_way.sequence_id);
					ELSE
						IF ST_Equals(ST_EndPoint(area), ST_StartPoint(relation_way.linestring)) THEN
							area := ST_MakeLine(area, relation_way.linestring);
							used_members := array_append(used_members,relation_way.sequence_id);
						ELSE 
							IF ST_Equals(ST_EndPoint(area), ST_EndPoint(relation_way.linestring)) THEN
								area := ST_MakeLine(area, ST_Reverse(relation_way.linestring));
								used_members := array_append(used_members,relation_way.sequence_id);
							END IF;
						END IF;
					END IF;
--				END IF;
			END IF;
		END LOOP;
	END LOOP;
	area := ST_AddPoint(area, ST_StartPoint(area));
	IF ST_NPoints(area) >= 4 THEN
		INSERT INTO areas (admin_level, name) VALUES (adminLevel, relation.tags->'name') RETURNING id INTO area_id;
		area := ST_MakePolygon(area);
		counter := 0;
		FOR node_data IN (SELECT * FROM nodes_data_routing n WHERE ( ST_Within(n.geom, area) ) ) LOOP
			INSERT INTO area_connectors (member_type, member_id, area_id) VALUES ('N', node_data.id, area_id);
			counter := counter + 1;
		END LOOP;
--		RAISE NOTICE 'operations = %',counter;
		RAISE NOTICE 'area = {%,%,%}, nodes = %', area_id, relation.tags->'admin_level', relation.tags->'name', counter;
	ELSE
--		RAISE NOTICE 'area = %', ST_AsText(area);
	END IF;
END LOOP;
RAISE NOTICE 'connecting ways';
--INSERT INTO area_connectors (member_type, member_id, area_id)
--	SELECT DISTINCT 'E', ed.id, sa.id
--	FROM edges_data_routing ed JOIN edges_routing e ON ed.id = e.data_id
--	JOIN nodes_routing sn ON sn.id = e.source_id
--	JOIN nodes_data_routing sdn ON sdn.id = sn.data_id
--	JOIN area_connectors sac ON sac.member_type = 'N' AND sac.member_id = sdn.id
--	JOIN areas sa ON sa.id = sac.area_id AND sa.admin_level = adminLevel
--	JOIN nodes_routing tn ON tn.id = e.target_id
--	JOIN nodes_data_routing tdn ON tdn.id = tn.data_id
--	JOIN area_connectors tac ON tac.member_type = 'N' AND tac.member_id = tdn.id AND tac.area_id = sa.id;
counter := 0;
FOR edge IN (SELECT e.* FROM edges_routing e JOIN (SELECT x.data_id, MAX(x.id) as max_id FROM edges_routing x GROUP BY x.data_id) e2 ON e.data_id = e2.data_id AND e.id = e2.max_id ) LOOP -- select one edge of every edge_data group
	SELECT ac.* INTO connector_source FROM nodes_data_routing d JOIN nodes_routing n ON d.id = n.data_id AND n.id = edge.source_id JOIN area_connectors ac ON ac.member_type = 'N' AND ac.member_id = d.id;
	SELECT ac.* INTO connector_target FROM nodes_data_routing d JOIN nodes_routing n ON d.id = n.data_id AND n.id = edge.target_id JOIN area_connectors ac ON ac.member_type = 'N' AND ac.member_id = d.id;
	IF connector_source.area_id = connector_target.area_id THEN
		SELECT a.* INTO ad_area FROM areas a WHERE a.id = connector_source.area_id;
		IF ad_area.admin_level = adminLevel THEN
			INSERT INTO area_connectors (member_type, member_id, area_id) VALUES ('E', edge.data_id, ad_area.id);
			counter := counter + 1;
			IF (counter % 10000) = 0 THEN
				RAISE NOTICE 'done: %', counter;
			END IF;
		END IF;
	ELSE
		RAISE NOTICE 'source and target areas differ: %->%, %->%', connector_source.member_id, connector_source.area_id, connector_target.member_id, connector_target.area_id;
	END IF;
END LOOP;
RAISE NOTICE 'done';
END;
$$ LANGUAGE plpgsql;

SELECT _create_areas(6);

DROP TYPE a5293eb9d34b3de;
        

