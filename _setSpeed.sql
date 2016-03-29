﻿--SELECT *, tags->'ISO3166-1:alpha2' FROM relations WHERE (tags->'boundary' = 'administrative' AND to_number(tags->'admin_level','99') = 2 AND tags->'ISO3166-1:alpha2' IS NOT NULL)
-- Function: public."_setState"()

DROP FUNCTION IF EXISTS public."fba3dd4c94104260aeee0e3738676077"();

CREATE OR REPLACE FUNCTION public."fba3dd4c94104260aeee0e3738676077"()
  RETURNS void AS
$BODY$
DECLARE
	edge edges_routing;
	speed speed_map;
BEGIN

FOR edge IN (SELECT * FROM edges_routing WHERE speed_forward = -1 OR speed_backward = -1) LOOP
	SELECT * INTO speed FROM speed_map WHERE (speed_map.state = edge.state AND speed_map.type_id = edge.road_type);
	IF edge.is_inside THEN BEGIN
		IF edge.speed_forward = -1 THEN BEGIN
			UPDATE edges_routing SET speed_forward = speed.speed_inside WHERE id = edge.id;
		END;
		IF edge.speed_backward = -1 THEN BEGIN
			UPDATE edges_routing SET speed_backward = speed.speed_inside WHERE id = edge.id;
		END;
	ELSE
		IF edge.speed_forward = -1 THEN BEGIN
			UPDATE edges_routing SET speed_forward = speed.speed_outside WHERE id = edge.id;
		END;
		IF edge.speed_backward = -1 THEN BEGIN
			UPDATE edges_routing SET speed_backward = speed.speed_outside WHERE id = edge.id;
		END;
	END;
	/* -- TODO traffic zones
	UPDATE edges_routing
	SET 
		speed_forward = s.speed_inside
	FROM (edges_routing AS e INNER JOIN ways AS w
		ON e.osm_id = w.id)
		INNER JOIN 
		(SELECT * FROM traffic_speed_map
		INNER JOIN traffic_zones
		ON traffic_speed_map.zone_id = traffic_zones.zone_id
		) AS s
		ON (
			e.state = s.state
			AND (
				w.tags->'maxspeed' = CONCAT(CONCAT(s.state,':'),s.name)
				OR w.tags->'zone:traffic' = CONCAT(CONCAT(s.state,':'),s.name)
			)
		)
	WHERE (
		e.speed_forward = -1
		AND 
		e.is_inside IS TRUE
			AND (
				w.tags->'maxspeed' = CONCAT(CONCAT(s.state,':'),s.name)
				OR w.tags->'zone:traffic' = CONCAT(CONCAT(s.state,':'),s.name)
			)
	);
	*/
END LOOP;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."fba3dd4c94104260aeee0e3738676077"()
  OWNER TO postgres;


SELECT public."fba3dd4c94104260aeee0e3738676077"();

DROP FUNCTION public."fba3dd4c94104260aeee0e3738676077"();




