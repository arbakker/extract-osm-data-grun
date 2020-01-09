# README

Bash scripts for extracting points of interest from Open Street Map (OSM) datasets.

Requires:
- bash
- ogr2ogr

## extract_osm_data

Outputs results in geopackage `data/poi.gpkg`.

Script does the following:
- downloads osm dataset of province of Groningen
- downloads bestuurlijke grenzen dataset
- extracts municipal boundary Groningen
- clips osm points layer on municipal of Groningen geometry
- extracts benches from clipped osm points layer
- extracts public toilets from clipped osm points layer

## extract_osm_data

Outputs results in txt file `data/unique_other_tags.txt`. 

Script does the following:
- outputs all unique values in the other_tags attribute  for exploration
