#!/bin/bash
psql ${PG_URI} -f setup_scripts/write_data_to_csv.sql -v PWD=$(pwd)
