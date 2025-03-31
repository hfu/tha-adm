DATASET_URL = https://data.humdata.org/dataset/d24bdc45-eb4c-4e3d-8b16-44db02667c27/resource/d0c722ff-6939-4423-ac0d-6501830b1759/download/tha_adm_rtsd_itos_20210121_shp.zip
ZIP_FILE = tha_adm_rtsd_itos_20210121_shp.zip
SRC_DIR = src
DST_DIR = docs
DST_URL = s3://smartmaps/foil4gr1/tha-adm/a.pmtiles
ENDPOINT_OPTION = --endpoint-url=https://data.source.coop
OUTPUT_PMTILES = $(DST_DIR)/a.pmtiles
STYLE_PKL = style.pkl
STYLE_JSON = $(DST_DIR)/style.json
HOST_PORT = 8080
JQ_SCRIPT = filter.jq

ADM0_BASE = tha_admbnda_adm0_rtsd_20220121
ADM1_BASE = tha_admbnda_adm1_rtsd_20220121
ADM2_BASE = tha_admbnda_adm2_rtsd_20220121
ADM3_BASE = tha_admbnda_adm3_rtsd_20220121
BNDL_BASE = tha_admbndl_admALL_rtsd_itos_20220121
BNDP_BASE = tha_admbndp_admALL_rtsd_itos_20220121

ADM0 = $(SRC_DIR)/$(ADM0_BASE).shp
ADM1 = $(SRC_DIR)/$(ADM1_BASE).shp
ADM2 = $(SRC_DIR)/$(ADM2_BASE).shp
ADM3 = $(SRC_DIR)/$(ADM3_BASE).shp
BNDL = $(SRC_DIR)/$(BNDL_BASE).shp
BNDP = $(SRC_DIR)/$(BNDP_BASE).shp

download: $(ZIP_FILE)
	curl -OL $(DATASET_URL)
	unzip -d $(SRC_DIR) $(ZIP_FILE)

$(SRC_DIR):
	mkdir -p $@

$(OUTPUT_PMTILES): produce
	# This dependency ensures produce runs before creating the pmtiles

$(DST_DIR):
	mkdir -p $@


produce: $(BNDL) $(BNDP) $(ADM0) $(ADM1) $(ADM2) $(ADM3) $(JQ_SCRIPT) $(DST_DIR)
	(\
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(BNDL) -select admLevel | jq -c --arg layer "bndl" -f $(JQ_SCRIPT) ; \
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(BNDP) -select ADM1_EN,ADM2_EN,ADM3_EN | jq -c --arg layer "bndp" -f $(JQ_SCRIPT) ; \
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(ADM0) -select ADM0_EN,ADM0_PCODE | jq -c --arg layer "adm0" -f $(JQ_SCRIPT) ; \
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(ADM1) -select ADM1_EN,ADM1_PCODE | jq -c --arg layer "adm1" -f $(JQ_SCRIPT) ; \
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(ADM2) -select ADM2_EN,ADM2_PCODE | jq -c --arg layer "adm2" -f $(JQ_SCRIPT) ; \
	ogr2ogr -of GeoJSONSeq /vsistdout/ $(ADM3) -select ADM3_EN,ADM3_PCODE | jq -c --arg layer "adm3" -f $(JQ_SCRIPT) ; \
	) | tippecanoe --no-simplification-of-shared-nodes -f -o $(OUTPUT_PMTILES) --maximum-zoom=14

$(STYLE_JSON): $(STYLE_PKL)
	pkl eval -f json $(STYLE_PKL) > $@

style: $(STYLE_JSON)
	@echo "Style file created: $@"

host: $(STYLE_JSON)
	budo -d $(DST_DIR) -p $(HOST_PORT)

upload:
	aws s3 cp docs/a.pmtiles $(DST_URL) $(ENDPOINT_OPTION)

.PHONY: download produce style host
