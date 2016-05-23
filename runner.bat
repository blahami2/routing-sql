@echo off

REM -- will contain all the scripts
:start
set ENDTIME=%time%
set database=osm_kladno
set tablespace=osm
set temp_tablespace=temporary_hdd
set dbuser=postgres
set dbhost=localhost
set dbpassword=password
set inputpbf=C:\Routing\Data\kladno.pbf
set postgispath=C:\Program Files\PostgreSQL\9.5\share\contrib\postgis-2.2
set osmosispath=C:\Program Files (x86)\osmosis
echo ---------------------------------------------------------------------------------------- >> log.txt
echo %date% %time% >> log.txt
echo Running database import: %database% >> log.txt
echo Start: %time% >> log.txt 
echo Running database import: %database%
echo Start: %time%



::goto tables
::goto turn_rest

:createdb
dropdb -U %dbuser% %database%
createdb -U %dbuser% -O %dbuser% -E utf8 -D %tablespace% --lc-collate="Czech_Czech Republic.1250" --lc-ctype="Czech_Czech Republic.1250" %database%

:tmp
psql -U %dbuser% -d %database% -c "ALTER DATABASE %database% SET temp_tablespaces = '%temp_tablespace%';" > NUL  
:create
psql -U %dbuser% -d %database% -f "%postgispath%\postgis.sql" > NUL
psql -U %dbuser% -d %database% -f "%postgispath%\spatial_ref_sys.sql" > NUL  
psql -U %dbuser% -d %database% -c "CREATE EXTENSION hstore;" > NUL
::psql -U %dbuser% -d %database% -f "%postgispath%\hstore-new.sql"
psql -U %dbuser% -d %database% -f "%osmosispath%\script\pgsnapshot_schema_0.6.sql" > NUL
psql -U %dbuser% -d %database% -f "%osmosispath%\script\pgsnapshot_schema_0.6_linestring.sql" > NUL  

  
::echo database creation time: %time% >> log.txt  
::echo database creation time: %time%
call:set_duration
call:print_all "database creation time: " %time%

REM osmosis peformance tunning
set JAVACMD_OPTIONS=-server -Xmx4g
:import
call osmosis --read-pbf %inputpbf% --buffer --log-progress --write-pgsql host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
goto osmtime 
:update
call osmosis --read-pbf %1 --log-progress --write-pgsql-change host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
:osmtime  
::echo osmosis time: %time% >> log.txt  
::echo osmosis time: %time%     
call:set_duration
call:print_all "osmosis time: " %time%
echo %date% %time% >> log.txt

::goto end

:index_osm
psql -U %dbuser% -d %database% -a -f index_osm.sql > NUL 
call:set_duration
call:print_all "index_osm.sql time: " %time%

:tables
psql -U %dbuser% -d %database% -a -f create_tables.sql > NUL   
call:set_duration
call:print_all "create_tables.sql time: " %time%


:functions
psql -U %dbuser% -d %database% -a -f _isValidWay.sql > NUL  
call:set_duration
call:print_all "_isValidWay.sql time: " %time%

:views
psql -U %dbuser% -d %database% -a -f create_views.sql > NUL   
call:set_duration
call:print_all "create_views.sql time: " %time%

:functions                  
psql -U %dbuser% -d %database% -a -f find_node.sql > NUL 
call:set_duration
call:print_all "find_node.sql time: " %time% 

:insert
psql -U %dbuser% -d %database% -a -f insert_all.sql > NUL   
call:set_duration
call:print_all "insert_all.sql time: " %time%

:index_routing
psql -U %dbuser% -d %database% -a -f index_routing.sql > NUL    
call:set_duration
call:print_all "index_routing.sql time: " %time%

:divide_ways   
psql -U %dbuser% -d %database% -a -f insert_edges.sql > NUL
call:set_duration
call:print_all "insert_edges.sql time: " %time%

::goto end

:set_inside
psql -U %dbuser% -d %database% -a -f determine_city.sql > NUL   
call:set_duration
call:print_all "determine_city time: " %time%

:set_state
psql -U %dbuser% -d %database% -a -f determine_state.sql > NUL 
call:set_duration
call:print_all "determine_state.sql time: " %time%

:set_speed                        
psql -U %dbuser% -d %database% -a -f set_speed.sql > NUL     
call:set_duration
call:print_all "set_speed.sql time: " %time%

::goto end

::remove indexes
:turn_rest                       
psql -U %dbuser% -d %database% -a -f tr_expand_graph.sql > NUL 
call:set_duration
call:print_all "tr_expand_graph.sql time: " %time%
::add indexes                
                                                                    
:end 
::echo End: %time%s >> log.txt  
call:set_duration
call:print_all "End: %time%"
echo %date% %time% >> log.txt

:set_duration
set STARTTIME=%ENDTIME%
set ENDTIME=%time%
::hours possibly (1%STARTTIME:~0.2%-100)*...
set /A start_time=((%STARTTIME:~0,2%)*3600000 + (1%STARTTIME:~3,2%-100)*60000 + (1%STARTTIME:~6,2%-100)*1000 + (1%STARTTIME:~9,2%-100)*10)
set /A end_time=((%ENDTIME:~0,2%)*3600000 + (1%ENDTIME:~3,2%-100)*60000 + (1%ENDTIME:~6,2%-100)*1000 + (1%ENDTIME:~9,2%-100)*10)
set /A duration=%end_time%-%start_time%
goto:eof

:print_all
::echo %~1 %~2
::echo %~1 %~2 >> log.txt
::echo %duration% ms 
::echo %duration% ms >> log.txt  
echo %~1 %duration% ms
echo %~1 %duration% ms >> log.txt
goto:eof
