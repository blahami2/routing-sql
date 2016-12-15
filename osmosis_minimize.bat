set inputpbf=C:\Routing\Data\europe.pbf
set outputpbf=C:\Routing\Data\europe_parsed.pbf
set JAVACMD_OPTIONS=-server -Xmx4g

::barrier_whitelist = { ["cattle_grid"] = true, ["border_control"] = true, ["checkpoint"] = true, ["toll_booth"] = true, ["sally_port"] = true, ["gate"] = true, ["lift_gate"] = true, ["no"] = true, ["entrance"] = true }
::access_tag_whitelist = { ["yes"] = true, ["motorcar"] = true, ["motor_vehicle"] = true, ["vehicle"] = true, ["permissive"] = true, ["designated"] = true, ["destination"] = true }
::access_tag_blacklist = { ["no"] = true, ["private"] = true, ["agricultural"] = true, ["forestry"] = true, ["emergency"] = true, ["psv"] = true, ["delivery"] = true }
::access_tag_restricted = { ["destination"] = true, ["delivery"] = true }
::access_tags_hierarchy = { "motorcar", "motor_vehicle", "vehicle", "access" }
::service_tag_restricted = { ["parking_aisle"] = true }
::restriction_exception_tags = { "motorcar", "motor_vehicle", "vehicle" }



call osmosis --read-pbf %inputpbf% --buffer --log-progress --tf accept-relations type=boundary,restriction --tf accept-ways highway=* access=* --tf reject-ways access=no,private,agricultural,forestry,emergency,psv,delivery --used-node --write-pbf %outputpbf%