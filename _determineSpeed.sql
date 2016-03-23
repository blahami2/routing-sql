-- ************************************** FORWARD INSIDE **************************************
UPDATE e
SET 
	speed_forward = s.speed_inside,
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward <> -1
	AND e.is_inside IS TRUE
);

-- ************************************** FORWARD OUTSIDE **************************************
UPDATE e
SET 
	speed_forward = s.speed_outside,
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_forward <> -1
	AND e.is_inside IS FALSE
);

-- ************************************** BACKWARD INSIDE **************************************
UPDATE e
SET 
	speed_backward = s.speed_inside,
FROM edges_routing AS e INNER JOIN  
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward <> -1
	AND e.is_inside IS TRUE
);

-- ************************************** BACKWARD OUTSIDE **************************************
UPDATE e
SET 
	speed_backward = s.speed_inside,
FROM edges_routing AS e INNER JOIN 
	speed_map AS s
	ON (
		e.state = s.state
		AND e.road_type = s.road_type
	)
WHERE (
	e.speed_backward <> -1
	AND e.is_inside IS FALSE
);




--SELECT * FROM edges_routing LIMIT 20;
--SELECT * FROM speed_map LIMIT 20;