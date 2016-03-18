-- Function: public."_isValidWay"(ways)

-- DROP FUNCTION public."_isValidWay"(ways);

CREATE OR REPLACE FUNCTION public."_isValidWay"(ways ways)
  RETURNS boolean AS
$BODY$BEGIN
RETURN (exist(ways.tags,'highway')
AND (NOT exist(ways.tags,'motor_vehicle') OR (ways.tags->'motor_vehicle' <> 'no' AND ways.tags->'motor_vehicle' <> 'delivery'))
AND (NOT exist(ways.tags,'motorcar') OR ways.tags->'motorcar' <> 'no')
AND (NOT exist(ways.tags,'access') OR (ways.tags->'access' <> 'no' AND ways.tags->'access' <> 'private'))
AND (
ways.tags->'highway' = 'motorway' OR
ways.tags->'highway' = 'trunk' OR
ways.tags->'highway' = 'primary' OR
ways.tags->'highway' = 'secondary' OR
ways.tags->'highway' = 'tertiary' OR
ways.tags->'highway' = 'unclassified' OR
ways.tags->'highway' = 'residential' OR
--tags->'highway' = 'service' OR
(ways.tags->'highway' = 'pedestrian' AND (ways.tags->'motor_vehicle'='yes' OR ways.tags->'motor_vehicle'='designated' OR ways.tags->'motorcar'='yes')) OR
ways.tags->'highway' = 'motorway_link' OR
ways.tags->'highway' = 'trunk_link' OR
ways.tags->'highway' = 'primary_link' OR
ways.tags->'highway' = 'secondary_link' OR
ways.tags->'highway' = 'tertiary_link' OR
(exist(ways.tags,'motor_vehicle') AND (ways.tags->'motor_vehicle'='yes' OR ways.tags->'motor_vehicle'='designated')) OR
(exist(ways.tags,'motorcar') AND ways.tags->'motorcar'='yes')
)
);
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public."_isValidWay"(ways)
  OWNER TO postgres;
