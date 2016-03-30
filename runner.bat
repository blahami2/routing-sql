@echo off

REM -- will contain all the scripts
set start_time=%time%
echo ---------------------------------------------------------------------------------------- >> log.txt
echo %date% %time% >> log.txt
echo Running database import: %1 >> log.txt
echo Start: %time% >> log.txt

set database=postgis_prague
REM import data
REM osmosis --read-pbf %1 --log-progress --write-pgsql authFile=dbauth.txt 
echo osmosis time: %time% >> log.txt  
echo osmosis time: %time%

psql -U postgres -d %database% -a -f create.sql > NUL   
echo create.sql time: %time% >> log.txt      
echo create.sql time: %time%

psql -U postgres -d %database% -a -f _isValidWay.sql > NUL 
echo _isValidWay.sql time: %time% >> log.txt 
echo _isValidWay.sql time: %time%

psql -U postgres -d %database% -a -f create_views.sql > NUL   
echo create_views.sql time: %time% >> log.txt 
echo create_views.sql time: %time%

psql -U postgres -d %database% -a -f insert.sql > NUL   
echo insert.sql time: %time% >> log.txt      
echo insert.sql time: %time% 
   
psql -U postgres -d %database% -a -f _divideWay.sql > NUL 
echo _divideWay.sql time: %time% >> log.txt  
echo _divideWay.sql time: %time%

psql -U postgres -d %database% -a -f _setInside.sql > NUL  
echo _setInside.sql time: %time% >> log.txt    
echo _setInside.sql time: %time%

psql -U postgres -d %database% -a -f _setState.sql > NUL 
echo _setState.sql time: %time% >> log.txt      
echo _setState.sql time: %time%
                        
psql -U postgres -d %database% -a -f _setSpeed.sql > NUL     
echo _setSpeed.sql time: %time% >> log.txt    
echo _setSpeed.sql time: %time%
                                                                    
 
echo End: %time%s >> log.txt
