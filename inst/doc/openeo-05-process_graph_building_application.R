## -----------------------------------------------------------------------------
library(openeo)

## ---- include=FALSE-----------------------------------------------------------
openeo:::demo_processes()

## -----------------------------------------------------------------------------
p = processes()

evi = function(data,context) {
  B08 = data[1]
  B04 = data[2]
  B02 = data[3]
  return((2.5 * (B08 - B04)) / sum(B08, 6 * B04, -7.5 * B02, 1))
}

## -----------------------------------------------------------------------------
as(evi,"Graph")

## ---- eval=FALSE--------------------------------------------------------------
#  library(sf)
#  
#  p = processes()
#  
#  bbox = st_bbox(c(xmin=16.1,
#                   xmax=16.6,
#                   ymax=48.6,
#                   ymin= 47.2), crs = 4326)
#  
#  data = p$load_collection(id = "SENTINEL2_L2A_SENTINELHUB",
#                           spatial_extent = bbox,
#                           temporal_extent = list(
#                             "2018-04-01", "2018-05-01"
#                           ),
#                           bands=list("B08","B04","B02"))

## ---- eval=FALSE--------------------------------------------------------------
#  spectral_reduce = p$reduce_dimension(data = data, dimension = "bands",reducer = evi)

## ---- eval=FALSE--------------------------------------------------------------
#  temporal_reduce = p$reduce_dimension(data=spectral_reduce,dimension = "t", reducer = function(x,y){
#    min(x)
#  })

## ---- eval=FALSE--------------------------------------------------------------
#  apply_linear_transform = p$apply(data=temporal_reduce,process = function(value,...) {
#    p$linear_scale_range(x = value,
#                             inputMin = -1,
#                             inputMax = 1,
#                             outputMin = 0,
#                             outputMax = 255)
#  })

## ---- eval=FALSE--------------------------------------------------------------
#  result = p$save_result(data=apply_linear_transform,format="PNG")

## ---- eval=FALSE--------------------------------------------------------------
#  library(magrittr)
#  
#  p = processes()
#  
#  result2 = p$load_collection(id = "SENTINEL2_L2A_SENTINELHUB",
#                           spatial_extent = bbox,
#                           temporal_extent = list(
#                             "2018-04-01", "2018-05-01"
#                           ),
#                           bands=list("B08","B04","B02")) %>%
#    p$reduce_dimension(dimension = "bands",reducer = evi) %>%
#    p$reduce_dimension(dimension = "t", reducer = function(x,y){
#      min(x)
#    }) %>%
#    p$apply(process = function(value,...) {
#      p$linear_scale_range(x = value,
#                               inputMin = -1,
#                               inputMax = 1,
#                               outputMin = 0,
#                               outputMax = 255)
#    }) %>%
#    p$save_result(format="PNG")
#  

## ---- paged.print=FALSE, eval=FALSE-------------------------------------------
#  list_user_processes()

## ---- eval=FALSE--------------------------------------------------------------
#  validate_process(graph = evi)

## ---- eval=FALSE--------------------------------------------------------------
#  graph_id = create_user_process(graph = evi, id = "evi", summary = "EVI calculation on an array with 3 bands", description = "The EVI calculation is based on an array of 3 band values: blue, red, nir. In that order.")

## ---- paged.print=FALSE, eval=FALSE-------------------------------------------
#  list_user_processes()

## ---- paged.print=FALSE, eval=FALSE-------------------------------------------
#  evi_process = describe_user_process(id = "evi")
#  class(evi_process)

## ---- paged.print = FALSE, eval=FALSE-----------------------------------------
#  evi_process

## ---- eval=FALSE--------------------------------------------------------------
#  evi_graph = parse_graph(json = evi_process) # or use as(evi_process,"Graph")

## ---- eval=FALSE--------------------------------------------------------------
#  min_evi_graph_id = create_user_process( graph = result, id = "min_evi",summary="Minimum EVI calculation on Sentinel-2", description = "A preset process graph that will calculate the minimum NDVI on Sentinel-2 data, performs a linear scale into the value interval 0 to 255 in order to store the results as PNG.")

## ---- paged.print = FALSE, eval=FALSE-----------------------------------------
#  list_user_processes()

## ---- eval=FALSE--------------------------------------------------------------
#  delete_user_process(id = min_evi_graph_id)

## ---- eval=FALSE--------------------------------------------------------------
#  p = processes()
#  udps = user_processes()

## ---- eval=FALSE--------------------------------------------------------------
#  spectral_reduce$parameters$reducer = function(x,context) {
#    udps$evi(x)
#  }
#  
#  min_evi_graph = as(result,"Process")

