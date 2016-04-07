@echo off

REM -- will contain all the scripts
:start
set ENDTIME=%time%
set database=osm_prague
set tablespace=pg_default
set temp_tablespace=temporary_ssd
set dbuser=postgres
set dbhost=localhost
set dbpassword=password
set inputpbf=C:\Routing\Data\prague.pbf
set postgispath=C:\Program Files\PostgreSQL\9.5\share\contrib\postgis-2.2
set osmosispath=C:\Program Files (x86)\osmosis
echo ---------------------------------------------------------------------------------------- >> log.txt
echo %date% %time% >> log.txt
echo Running database import: %database% >> log.txt
echo Start: %time% >> log.txt 
echo Running database import: %database%
echo Start: %time%



::goto tables

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
call:print_all "database creation time: %time%"
call:print_all "%duration% ms"

:import
call osmosis --read-pbf %inputpbf% --log-progress --write-pgsql host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
goto osmtime 
:update
call osmosis --read-pbf %1 --log-progress --write-pgsql-change host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
:osmtime  
::echo osmosis time: %time% >> log.txt  
::echo osmosis time: %time%     
call:set_duration
call:print_all "osmosis time: %time%"
call:print_all "%duration% ms"

::goto end

:index
psql -U %dbuser% -d %database% -a -f index_osm.sql > NUL 

:tables
psql -U %dbuser% -d %database% -a -f create.sql > NUL   
::echo create.sql time: %time% >> log.txt      
::echo create.sql time: %time%
call:set_duration
call:print_all "create.sql time: %time%"
call:print_all "%duration% ms"


:functions
psql -U %dbuser% -d %database% -a -f _isValidWay.sql > NUL 
::echo _isValidWay.sql time: %time% >> log.txt 
::echo _isValidWay.sql time: %time%   
call:set_duration
call:print_all "_isValidWay.sql time: %time%"
call:print_all "%duration% ms"

:views
psql -U %dbuser% -d %database% -a -f create_views.sql > NUL   
::echo create_views.sql time: %time% >> log.txt 
::echo create_views.sql time: %time% 
call:set_duration
call:print_all "create_views.sql time: %time%"
call:print_all "%duration% ms"

:insert
psql -U %dbuser% -d %database% -a -f insert.sql > NUL   
::echo insert.sql time: %time% >> log.txt      
::echo insert.sql time: %time%  
call:set_duration
call:print_all "insert.sql time: %time%"
call:print_all "%duration% ms"

:divide_ways   
psql -U %dbuser% -d %database% -a -f _divideWay.sql > NUL
::echo _divideWay.sql time: %time% >> log.txt  
::echo _divideWay.sql time: %time% 
call:set_duration
call:print_all "_divideWay.sql time: %time%"
call:print_all "%duration% ms"

:set_inside
psql -U %dbuser% -d %database% -a -f _setInside.sql > NUL  
::echo _setInside.sql time: %time% >> log.txt    
::echo _setInside.sql time: %time%  
call:set_duration
call:print_all "_setInside.sql time: %time%"
call:print_all "%duration% ms"

:set_state
psql -U %dbuser% -d %database% -a -f _setState.sql > NUL 
::echo _setState.sql time: %time% >> log.txt      
::echo _setState.sql time: %time%  
call:set_duration
call:print_all "_setState.sql time: %time%"
call:print_all "%duration% ms"

:set_speed                        
psql -U %dbuser% -d %database% -a -f _setSpeed.sql > NUL     
::echo _setSpeed.sql time: %time% >> log.txt    
::echo _setSpeed.sql time: %time%   
call:set_duration
call:print_all "_setSpeed.sql time: %time%"
call:print_all "%duration% ms"


:turn_rest                       
psql -U %dbuser% -d %database% -a -f turnRestrictions.sql > NUL 
::echo turnRestrictions.sql time: %time% >> log.txt    
::echo turnRestrictions.sql time: %time% 
call:set_duration
call:print_all "turnRestrictions.sql time: %time%"
call:print_all "%duration% ms"
                                                                    
:end 
::echo End: %time%s >> log.txt  
call:set_duration
call:print_all "End: %time%"
call:print_all "%duration% ms"

:set_duration
set STARTTIME=%ENDTIME%
set ENDTIME=%time%
set /A start_time=(1%STARTTIME:~0,2%-100)*3600000 + (1%STARTTIME:~3,2%-100)*60000 + (1%STARTTIME:~6,2%-100)*1000 + (1%STARTTIME:~9,2%-100)*10
set /A end_time=(1%ENDTIME:~0,2%-100)*3600000 + (1%ENDTIME:~3,2%-100)*60000 + (1%ENDTIME:~6,2%-100)*1000 + (1%ENDTIME:~9,2%-100)*10
set /A duration=%end_time%-%start_time%
goto:eof

:print_all
echo %~1
echo %~1 >> log.txt
goto:eof
