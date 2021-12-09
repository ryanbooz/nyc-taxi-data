#!/bin/bash
# Pull parameters for psql connections from a shared file
# to be used across files.
source ./shared_parameters.sh

# load 2014 Uber data into `fhv_trips` table
for filename in data/uber-raw-data*14.csv; do
  echo "`date`: beginning load for $filename"
  cat $filename | psql ${PG_URI} -c "SET datestyle = 'ISO, MDY'; COPY uber_trips_2014 (pickup_datetime, pickup_latitude, pickup_longitude, base_code) FROM stdin CSV HEADER;"
  echo "`date`: finished raw load for $filename"
done;

psql ${PG_URI} -f setup_files/populate_2014_uber_trips.sql
