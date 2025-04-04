def layer_config:
  {
    "bndl": { "minzoom_func": "bndl_minzoom", "maxzoom": 14, "properties": null },
    "bndp": { "minzoom": 13, "maxzoom": 14, "properties": { "name": "ADM3_EN", "code": null } },
    "adm0": { "minzoom": 3, "maxzoom": 6, "properties": { "name": "ADM0_EN", "code": "ADM0_PCODE" } },
    "adm1": { "minzoom": 7, "maxzoom": 8, "properties": { "name": "ADM1_EN", "code": "ADM1_PCODE" } },
    "adm2": { "minzoom": 9, "maxzoom": 10, "properties": { "name": "ADM2_EN", "code": "ADM2_PCODE" } },
    "adm3": { "minzoom": 11, "maxzoom": 14, "properties": { "name": "ADM3_EN", "code": "ADM3_PCODE" } }
  };

def bndl_minzoom:
  if .properties.admLevel == 99 then 5
  elif .properties.admLevel == 0 then 3
  elif .properties.admLevel == 1 then 7
  elif .properties.admLevel == 2 then 9
  elif .properties.admLevel == 3 then 11
  else null
  end;

def tippecanoe_config(layer_name):
  . + {
    tippecanoe: {
      minzoom: (
        if layer_config[layer_name].minzoom_func == "bndl_minzoom" then
          bndl_minzoom
        else
          layer_config[layer_name].minzoom
        end
      ),
      maxzoom: layer_config[layer_name].maxzoom,
      layer: layer_name
    }
  };

def rename_properties(layer_name):
  if layer_config[layer_name].properties == null then .properties
  else
    .properties | {
      name: (try .[layer_config[layer_name].properties.name] catch null),
      code: (try .[layer_config[layer_name].properties.code] catch null)
    } | del(.null)
  end;

def process(layer_name):
  tippecanoe_config(layer_name) | . + { properties: rename_properties(layer_name) };

. | process($layer)

