@echo off

REM -- will contain all the scripts
:start
set ENDTIME=%time%
set database=osm_prague
set tablespace=osm
set temp_tablespace=temporary_hdd
set dbuser=postgres
set dbhost=localhost
set dbpassword=password
set script_name=tr_turn_tables.sql

psql -U %dbuser% -d %database% -a -f %script_name%
 