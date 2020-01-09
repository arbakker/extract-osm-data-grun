#!/usr/bin/env bash
# extact other_tags attribute from all points except addresses with housenumber
ogrinfo -geom=NO -nocount -noextent data/groningen-stad-points.gpkg -sql "select other_tags from points where other_tags NOT LIKE '%addr:housenumber%'" > data/other_tags_ogr.txt
# remove all the redundant ogrinfo output
grep "other_tags" <data/other_tags_ogr.txt > data/other_tags.txt
# select only the uniqu other_tags values
sort data/other_tags.txt | uniq > data/unique_other_tags.txt
while read -r LINE; do echo "$LINE" |  sed 's/other_tags (String) = "//' >> data/unique_other_tags_cleaned.txt; done<data/unique_other_tags.txt
mv data/unique_other_tags_cleaned.txt data/unique_other_tags.txt
rm data/other_tags.txt data/other_tags_ogr.txt