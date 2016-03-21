-- Function: public."_determineAdminAreas"()

DROP FUNCTION public."_determineAdminAreas"();

CREATE OR REPLACE FUNCTION public."_determineAdminAreas"()
  RETURNS void AS
$BODY$
DECLARE
	way ways;
	relation relations;
	rel_member relation_members;
	edge edges_routing;
	area geometry;
BEGIN

FOR relation IN (SELECT * FROM relations WHERE tags->'boundary' = 'administrative') LOOP
	area := null;
	FOR rel_member IN (SELECT * FROM relation_members WHERE relation_members.relation_id = relation.id) LOOP
		SELECT * INTO way FROM ways WHERE ways.id = rel_member.member_id;
		IF way IS NULL THEN
		ELSE
			IF area IS NULL THEN
--				RAISE NOTICE 'way: %', way;
				area := way.linestring;
			ELSE
				area := ST_Union(area, way.linestring);
			END IF;
		END IF;
	END LOOP;
--	RAISE NOTICE 'area = %', ST_AsText(area);
	FOR edge IN (SELECT * FROM edges_routing) LOOP
		IF ST_Contains(area, edge.geom) THEN
			UPDATE edges_routing SET is_inside = true;
		END IF;
	END LOOP;
END LOOP;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."_determineAdminAreas"()
  OWNER TO postgres;


SELECT public."_determineAdminAreas"();