require 'rubygems'
require 'csv'
require 'rest-client'
require 'active_support'
require 'active_support/core_ext'

def parse_number(string)
  string.to_s.squish.gsub(/[,%-]/, "").presence&.to_f
end

# TLC monthly reports
tlc_monthly_data_url = "https://www1.nyc.gov/assets/tlc/downloads/csv/data_reports_monthly.csv"
tlc_monthly_data = CSV.parse(RestClient.get(tlc_monthly_data_url).body)

CSV.open("tlc_monthly_data.csv", "wb") do |csv|
  tlc_monthly_data.drop(1).each do |row|
    csv << [
      Date.strptime(row[0], "%Y-%m").end_of_month,
      row[1].downcase.gsub("-", " ").squish.gsub(" ", "_"),
      parse_number(row[2])&.to_i,
      parse_number(row[3])&.to_i,
      parse_number(row[4])&.to_i,
      parse_number(row[5])&.to_i,
      parse_number(row[6])&.to_i,
      parse_number(row[7]),
      parse_number(row[8]),
      parse_number(row[9]),
      parse_number(row[10]),
      parse_number(row[11]),
      parse_number(row[12]),
      parse_number(row[13])&.to_i
    ]
  end
end

# FHV monthly data (includes Uber and Lyft)
fhv_monthly_data_url = "https://data.cityofnewyork.us/api/views/2v9c-2k7f/rows.csv?accessType=DOWNLOAD"
fhv = CSV.parse(RestClient.get(fhv_monthly_data_url).body)

CSV.open("fhv_monthly_data.csv", "wb") do |csv|
  fhv.drop(1).each do |row|
    dba_string = row[2].to_s.downcase

    dba = if %w(uber lyft via juno gett).include?(dba_string)
      dba_string
    else
      "other"
    end

    csv << (row + [dba])
  end
end

# create tables and import data
system(%{psql ${PG_URI} -f create_statistics_tables.sql})
system(%{sort -u tlc_monthly_data.csv | psql ${PG_URI} -c "COPY tlc_monthly_reports FROM stdin CSV;"})
system(%{cat fhv_monthly_data.csv | psql ${PG_URI} -c "COPY fhv_monthly_reports FROM stdin CSV;"})
