#!/bin/sh

# inputpbf - input pbf file
# database - output postgresql database

# --- DATASET: CZ_PRAGUE ----------------------------
inputpbf=/DATA/RoutingData/1_OSM/CZ/prague.pbf
database=osm_cz_prague
# --- DATASET: CZ -----------------------------------
#inputpbf=/DATA/RoutingData/1_OSM/CZ/CZ_parsed.pbf
#database=osm_cz
# ---------------------------------------------------

# KnowHow:
# Create postgreSQL user
# as postgres user:
#
# > createuser osm
# > psql
#     > alter user osm with password 'xxxxxxx';




# other configuration - usualy remains stale
dbhost=localhost
postgispath=/usr/share/postgresql/9.4/contrib/postgis-2.1/
osmosispath=/usr/share/doc/osmosis/examples/

dbuser=osm
dbpassword=xxxxxxx

# make possible to override configuration
if [ -f ./config.sh ]
then
    echo "INFO: Using external script ./config.sh to alter configuration"
    . ./config.sh
fi

echo ""
echo "--------------------------------------------------------"
echo "  Importer for OSM data files into PostgreSQL database  "
echo "--------------------------------------------------------"
echo ""

echo ">>> Input OSM binary file (.pbf): "$inputpbf" <<<"
echo ">>> Output postgreSQL database  : "$database" <<<"

echo ""

echo "--- Other configuration: ---"
echo "- DBHOST (host where the postgreSQL resists):            "$dbhost
echo "- DBUSER (user that interacts with postgreSQL database): "$dbuser
echo "- DBPASSWORD (postgreSQL user's password):               (HIDDEN)"
echo "- POSTGISPATH (path to postgis directory):               "$postgispath
echo "- OSMOSISPATH (path to osmosis directory):               "$osmosispath

echo ""

# --------------------------------------------------------------------------------------------------------------------
wantedscriptusername="postgres"
echo "\n+++ Checking username that called this script ["$wantedscriptusername"] +++"
scriptusername=`whoami`
if [ "$scriptusername" != "$wantedscriptusername" ]
then
    echo "FAILED"
    exit
fi
echo "[OK]"


# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Checking, that (postgreSQL client, postgis, osmosis) is present +++"
if ! (dpkg -l | grep -q "postgresql-client-common"); then
    echo "FAILED - postgreSQL client is not present"
    exit
fi
if ! (dpkg -l | grep -q "postgis"); then
    echo "FAILED - postgis is not present"
    exit
fi
if ! (dpkg -l | grep -q "osmosis"); then
    echo "FAILED - osmosis is not present"
    exit
fi
echo "[OK]"


############################
if true; then
############################

# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Creating PostgreSQL Database ["$database"] +++"
echo "- dropping database ["$database"]"
dropdb --if-exists $database
echo "- creating database ["$database"]"
createdb $database
echo "[OK]"

# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Importing postGIS scripts +++"
echo "- importing postgis.sql"
psql -d $database -f $postgispath"/postgis.sql" > /dev/null
echo "- importing spatial_ref_sys.sql"
psql -d $database -f $postgispath"/spatial_ref_sys.sql" > /dev/null
echo "- enabling EXTENSION hstore"
psql -d $database -c "CREATE EXTENSION hstore;" > /dev/null
echo "- extracting and importing osmosis schema"
gunzip -c $osmosispath"/pgsnapshot_schema_0.6.sql.gz" | psql -d $database > /dev/null
echo "- importing osmosis linestring schema"
psql -d $database -f $osmosispath"/pgsnapshot_schema_0.6_linestring.sql" > /dev/null
echo "[OK]"


# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Altering DATABASE and TABLE owner to user ["$dbuser"] +++"
psql -d $database -c "ALTER DATABASE $database owner to $dbuser;" > /dev/null
# ToDo - mozna nalevat primo pod userem dbuser, misto pod porstgresem a menit opravneni?
psql -d $database -c "ALTER TABLE geography_columns owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE geometry_columns owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE nodes owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE relation_members owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE relations owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE schema_info owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE spatial_ref_sys owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE users owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE way_nodes owner to $dbuser;" > /dev/null
psql -d $database -c "ALTER TABLE ways owner to $dbuser;" > /dev/null
echo "[OK]"

# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Importing data with Osmosis ["$inputpbf"] +++"
#osmosis --read-pbf $inputpbf --buffer --log-progress --write-pgsql host=$dbhost database=$database user=%dbuser% password=%dbpassword% dbType=postgresql
osmosis --read-pbf $inputpbf --buffer --log-progress --write-pgsql host=$dbhost database=$database user=$dbuser password=$dbpassword dbType=postgresql
echo "[OK]"



#####################
fi
#####################

# --------------------------------------------------------------------------------------------------------------------
echo "\n+++ Calling local SQL scripts +++"

echo "- SQL: index_osm.sql"
psql -d $database -f "index_osm.sql" > /dev/null

echo "- SQL: create_tables.sql"
psql -d $database -f "create_tables.sql" > /dev/null

echo "- SQL: _isValidWay.sql"
psql -d $database -f "_isValidWay.sql" > /dev/null

echo "- SQL: create_views.sql"
psql -d $database -f "create_views.sql" > /dev/null

echo "- SQL: find_node.sql"
psql -d $database -f "find_node.sql" > /dev/null

echo "- SQL: insert_all.sql"
psql -d $database -f "insert_all.sql" > /dev/null

echo "- SQL: index_routing.sql"
psql -d $database -f "index_routing.sql" > /dev/null

echo "- SQL: insert_edges.sql"
psql -d $database -f "insert_edges.sql" > /dev/null

echo "- SQL: determine_city.sql"
psql -d $database -f "determine_city.sql" > /dev/null

echo "- SQL: determine_state.sql"
psql -d $database -f "determine_state.sql" > /dev/null

echo "- SQL: set_speed.sql"
psql -d $database -f "set_speed.sql" > /dev/null

echo "- SQL: tr_turn_tables.sql"
psql -d $database -f "tr_turn_tables.sql" > /dev/null

echo "[OK]"
