@echo off

REM -- will contain all the scripts
:start
set start_time=%time%
echo ---------------------------------------------------------------------------------------- >> log.txt
echo %date% %time% >> log.txt
echo Running database import: %1 >> log.txt
echo Start: %time% >> log.txt 
echo Running database import: %1
echo Start: %time%

set database=osm_prague
set tablespace=pg_default
set temp_tablespace=temporary_ssd
set dbuser=postgres
set dbhost=localhost
set dbpassword=password
set inputpbf="C:\Routing\Data\prague.pbf"
::WARNING!!! Do not forget to edit dbauth.txt as well!!!

::goto index

:createdb
dropdb -U %dbuser% %database%
createdb -U %dbuser% -O %dbuser% -E utf8 -D %tablespace% --lc-collate="Czech_Czech Republic.1250" --lc-ctype="Czech_Czech Republic.1250" %database%

:tmp
psql -U %dbuser% -d %database% -c "ALTER DATABASE %database% SET temp_tablespaces = '%temp_tablespace%';" > NUL  
:create
psql -U %dbuser% -d %database% -f "C:\Program Files\PostgreSQL\9.5\share\contrib\postgis-2.2\postgis.sql" > NUL
psql -U %dbuser% -d %database% -f "C:\Program Files\PostgreSQL\9.5\share\contrib\postgis-2.2\spatial_ref_sys.sql" > NUL  
psql -U %dbuser% -d %database% -c "CREATE EXTENSION hstore;" > NUL
::psql -U %dbuser% -d %database% -f "C:\Program Files\PostgreSQL\9.5\share\contrib\postgis-2.2\hstore-new.sql"
psql -U %dbuser% -d %database% -f "C:\Program Files (x86)\osmosis\script\pgsnapshot_schema_0.6.sql" > NUL
psql -U %dbuser% -d %database% -f "C:\Program Files (x86)\osmosis\script\pgsnapshot_schema_0.6_linestring.sql" > NUL  

  
echo database creation time: %time% >> log.txt  
echo database creation time: %time%

:import
call osmosis --read-pbf %inputpbf% --log-progress --write-pgsql host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
goto osmtime 
:update
call osmosis --read-pbf %1 --log-progress --write-pgsql-change host=%dbhost% database=%database% user=%dbuser% password=%dbpassword% dbType=postgresql
:osmtime  
echo osmosis time: %time% >> log.txt  
echo osmosis time: %time%

::goto end

:index
psql -U %dbuser% -d %database% -a -f index_osm.sql > NUL 

:tables
psql -U %dbuser% -d %database% -a -f create.sql > NUL   
echo create.sql time: %time% >> log.txt      
echo create.sql time: %time%

:functions
psql -U %dbuser% -d %database% -a -f _isValidWay.sql > NUL 
echo _isValidWay.sql time: %time% >> log.txt 
echo _isValidWay.sql time: %time%

:views
psql -U %dbuser% -d %database% -a -f create_views.sql > NUL   
echo create_views.sql time: %time% >> log.txt 
echo create_views.sql time: %time%

:insert
psql -U %dbuser% -d %database% -a -f insert.sql > NUL   
echo insert.sql time: %time% >> log.txt      
echo insert.sql time: %time% 

:divide_ways   
psql -U %dbuser% -d %database% -a -f _divideWay.sql > NUL
echo _divideWay.sql time: %time% >> log.txt  
echo _divideWay.sql time: %time%

:set_inside
psql -U %dbuser% -d %database% -a -f _setInside.sql > NUL  
echo _setInside.sql time: %time% >> log.txt    
echo _setInside.sql time: %time%

:set_state
psql -U %dbuser% -d %database% -a -f _setState.sql > NUL 
echo _setState.sql time: %time% >> log.txt      
echo _setState.sql time: %time%

:set_speed                        
psql -U %dbuser% -d %database% -a -f _setSpeed.sql > NUL     
echo _setSpeed.sql time: %time% >> log.txt    
echo _setSpeed.sql time: %time%
                                                                    
:end 
echo End: %time%s >> log.txt
