--SELECT *, tags->'ISO3166-1:alpha2' FROM relations WHERE (tags->'boundary' = 'administrative' AND to_number(tags->'admin_level','99') = 2 AND tags->'ISO3166-1:alpha2' IS NOT NULL)
-- Function: public."_setState"()

DO $$
DECLARE
	edge edges_routing%rowtype;
	speed_m speed_map%rowtype;
  edge_data edges_data_routing%rowtype;
BEGIN

FOR edge IN (SELECT * FROM edges_routing WHERE speed = -1) LOOP
  SELECT * INTO edge_data FROM edges_data_routing d WHERE (d.id = edge.data_id);
	SELECT * INTO speed_m FROM speed_map WHERE (speed_map.state = edge_data.state AND speed_map.type_id = edge_data.road_type);
	IF edge_data.is_inside THEN
		IF edge.speed = -1 THEN 
			UPDATE edges_routing SET speed = speed_m.speed_inside WHERE id = edge.id;
		END IF;
	ELSE
		IF edge.speed = -1 THEN
			UPDATE edges_routing SET speed = speed_m.speed_outside WHERE id = edge.id;
		END IF;
	END IF;
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

END $$;        




