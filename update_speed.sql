-- Updates speed of all edges based on precalculated data - default speed map, road type, whether the road is inside or outside the city and so on
-- ******************************************************************* TYPES *******************************************************************
-- ************************************** FORWARD INSIDE **************************************
UPDATE edges_routing
SET 
	speed_forward = s.speed_inside
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward = -1
	AND e.is_inside IS TRUE
);

-- ************************************** FORWARD OUTSIDE **************************************
UPDATE edges_routing
SET 
	speed_forward = s.speed_outside
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward = -1
	AND e.is_inside IS FALSE
);

-- ************************************** BACKWARD INSIDE **************************************
UPDATE edges_routing
SET 
	speed_backward = s.speed_inside
FROM edges_routing AS e INNER JOIN  
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward = -1
	AND e.is_inside IS TRUE
);

-- ************************************** BACKWARD OUTSIDE **************************************
UPDATE edges_routing
SET 
	speed_backward = s.speed_inside
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward = -1
	AND e.is_inside IS FALSE
);


-- ******************************************************************* ZONES *******************************************************************
-- ************************************** FORWARD INSIDE **************************************
UPDATE edges_routing
SET 
	speed_forward = s.speed_inside
FROM edges_routing AS e JOIN ways AS w
	ON e.osm_id = w.id
	INNER JOIN 
	traffic_speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward = -1
	AND e.is_inside IS TRUE
);

-- ************************************** FORWARD OUTSIDE **************************************
UPDATE edges_routing
SET 
	speed_forward = s.speed_outside
FROM edges_routing AS e INNER JOIN 
	traffic_speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward = -1
	AND e.is_inside IS FALSE
);

-- ************************************** BACKWARD INSIDE **************************************
UPDATE edges_routing
SET 
	speed_backward = s.speed_inside
FROM edges_routing AS e INNER JOIN  
	traffic_speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward = -1
	AND e.is_inside IS TRUE
);

-- ************************************** BACKWARD OUTSIDE **************************************
UPDATE edges_routing
SET 
	speed_backward = s.speed_inside
FROM edges_routing AS e INNER JOIN 
	traffic_speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward = -1
	AND e.is_inside IS FALSE
);


--SELECT * FROM edges_routing LIMIT 20;
--SELECT * FROM speed_map LIMIT 20;