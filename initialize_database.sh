#!/bin/bash
# Pull parameters for psql connections from a shared file
# to be used across files.
source ./shared_parameters.sh
set -e

if ["$CREATEDB" = "true"]; then
    createdb nyc-taxi-data
fi

psql ${PG_URI} -f setup_files/create_nyc_taxi_schema.sql

shp2pgsql -s 2263:4326 -I shapefiles/taxi_zones/taxi_zones.shp | psql ${PG_URI} 
psql ${PG_URI} -c "CREATE INDEX ON taxi_zones (locationid);"
psql ${PG_URI} -c "VACUUM ANALYZE taxi_zones;"

shp2pgsql -s 2263:4326 -I shapefiles/nyct2010_15b/nyct2010.shp | psql ${PG_URI}
psql ${PG_URI} -f setup_files/add_newark_airport.sql
psql ${PG_URI} -c "CREATE INDEX ON nyct2010 (ntacode);"
psql ${PG_URI} -c "VACUUM ANALYZE nyct2010;"

psql ${PG_URI} -f setup_files/add_tract_to_zone_mapping.sql

cat data/fhv_bases.csv | psql ${PG_URI} -c "COPY fhv_bases FROM stdin WITH CSV HEADER;"
weather_schema="station_id, station_name, date, average_wind_speed, precipitation, snowfall, snow_depth, max_temperature, min_temperature"
cat data/central_park_weather.csv | psql ${PG_URI} -c "COPY central_park_weather_observations (${weather_schema}) FROM stdin WITH CSV HEADER;"
psql ${PG_URI} -c "UPDATE central_park_weather_observations SET average_wind_speed = NULL WHERE average_wind_speed = -9999;"
