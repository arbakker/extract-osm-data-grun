#!/usr/bin/env bash
set -eu

download_data () {
    local download_url
    local filename
    local useragent
    mkdir -p data
    download_url=$1
    filename=$(basename $download_url)
    useragent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:67.0) Gecko/20100101 Firefox/67.0"
    echo "downloading $download_url"
    curl --user-agent "$useragent" "$download_url" -o "data/$filename"
}

GRENZEN_URL="https://geodata.nationaalgeoregister.nl/bestuurlijkegrenzen/extract/bestuurlijkegrenzen.zip?datum=2020-01-02"
OSM_URL="https://download.geofabrik.de/europe/netherlands/groningen-latest.osm.pbf"
RESULT_GPKG="data/poi.gpkg"

download_data $OSM_URL
download_data $GRENZEN_URL
unzip data/$(basename $GRENZEN_URL) -d data/grenzen/

# extract grens gemeente Groningen
ogr2ogr -f GeoJSON data/gem_groningen_grens.json data/grenzen/Gemeentegrenzen.gml -sql "select * from Gemeenten where Gemeentenaam='Groningen'" -t_srs EPSG:4236
rm -r data/grenzen
rm data/$(basename $GRENZEN_URL)

# clip osm points layer op gemeentegrens Groningen
ogr2ogr -f GPKG data/groningen-stad-points.gpkg data/groningen-latest.osm.pbf points -clipsrc data/gem_groningen_grens.json

# select all benches from osm point layer and store in points layer in data/poi.gpkg
ogr2ogr -f GPKG ${RESULT_GPKG} data/groningen-stad-points.gpkg -sql "select other_tags, geom, 'bench' as type from points where other_tags LIKE '%\"amenity\"=>\"bench\"%'" -nln points

# toilets
# - wheelchair: yes,no (no when not wheelchair:yes, yes when wheelchair:yes)
# - public: yes, no (no when access:customers, yes when not access:customers)
# extract all toilets in temp layer
ogr2ogr -update -f GPKG ${RESULT_GPKG} data/groningen-stad-points.gpkg -sql "select other_tags, geom from points where other_tags LIKE '%\"amenity\"=>\"toilets\"%'" -nln temp_toilets
# select wheelchair:yes toilets in temp layer
ogr2ogr -update -f GPKG ${RESULT_GPKG} ${RESULT_GPKG} -sql "select other_tags, geom, 'yes' as wheelchair from temp_toilets where other_tags LIKE '%\"wheelchair\"=>\"yes\"%'" -nln temp_2_toilets
# select wheelchair:no toilets in temp layer
ogr2ogr -update -append -f GPKG ${RESULT_GPKG} ${RESULT_GPKG} -sql "select other_tags, geom, 'no' as wheelchair from temp_toilets where other_tags NOT LIKE '%\"wheelchair\"=>\"yes\"%'" -nln temp_2_toilets
# select public:yes toilets in temp layer
ogr2ogr -update -append  -f GPKG ${RESULT_GPKG} ${RESULT_GPKG} -sql "select other_tags, geom, wheelchair, 'yes' as public from temp_2_toilets where other_tags NOT LIKE '%\"access\"=>\"customers\"%'" -nln toilets
# select public:no toilets in temp layer
ogr2ogr -update -append  -f GPKG ${RESULT_GPKG} ${RESULT_GPKG} -sql "select other_tags, geom, wheelchair, 'no' as public from temp_2_toilets where other_tags LIKE '%\"access\"=>\"customers\"%'" -nln toilets
# clean up temp layers
ogrinfo ${RESULT_GPKG} -sql "drop table temp_toilets"
ogrinfo ${RESULT_GPKG} -sql "drop table temp_2_toilets"
