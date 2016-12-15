-- Function: public."_isValidWay"(ways)

-- DROP FUNCTION public."_getBoundaryRestrictions"(integer);

CREATE OR REPLACE FUNCTION public."_getBoundaryRelations"(target_admin_level int)
RETURNS SETOF planet_osm_rels 
AS
$$
DECLARE
	relation planet_osm_rels%rowtype;
	relation_rest planet_osm_rels%rowtype;
	tag text;
	counter int;
	has_admin_level boolean;
	admin_level int;
	member text;
	node planet_osm_nodes%rowtype;
	node_id bigint;
	way planet_osm_ways%rowtype;
	way_id bigint;
	node_id_text text;
BEGIN
	counter := 0;
	FOR relation IN (SELECT * FROM planet_osm_rels WHERE tags @> '{"boundary","administrative","admin_level"}') LOOP -- basic filter
		-- RAISE NOTICE 'relation: %', relation;		
		has_admin_level := false;
		admin_level := 0;
		FOR tag IN (SELECT * FROM unnest(relation.tags)) LOOP
			IF has_admin_level THEN
				BEGIN
					admin_level := tag::int;
				EXCEPTION WHEN OTHERS THEN
					admin_level := 0;
				END;
				EXIT;
			END IF;
			IF tag = 'admin_level' THEN
				has_admin_level := true;
			END IF;
		END LOOP;
		IF admin_level = target_admin_level THEN
			-- RAISE NOTICE 'found: %',relation;
			-- RETURN NEXT relation;
			FOR member IN (SELECT * FROM unnest(relation.members)) LOOP
				IF substring(member from 1 for 1) = 'w' THEN
					way_id := substring(member from 2 for (char_length(member) - 1))::int;
					-- RAISE NOTICE 'member: % - %', substring(member from 1 for 1),way_id;
					SELECT w.* INTO way FROM planet_osm_ways w WHERE w.id = way_id;
					FOR node_id IN (SELECT * FROM unnest(way.nodes)) LOOP
						node_id_text := 'n' || node_id;
						FOR relation_rest IN (SELECT r.* FROM planet_osm_rels r WHERE r.tags @> '{restriction}' AND r.members @> array[node_id_text]) LOOP
							RAISE NOTICE 'Found such node: id = %, boundary_id = %, restriction_id = %', node_id, relation.id, relation_rest.id;
							counter := counter + 1;
						END LOOP;
					END LOOP;
				END IF;
			END LOOP;
		END IF;
	END LOOP;
	-- RAISE NOTICE 'counter = %', counter;
END;
$$
LANGUAGE plpgsql VOLATILE
COST 100;


SELECT * FROM public."_getBoundaryRelations"(2);
