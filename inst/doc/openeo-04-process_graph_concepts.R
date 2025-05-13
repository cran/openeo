## ----evi_example, eval=FALSE--------------------------------------------------
# library(openeo)
# # EVI example to create a user-defined processes
# con = connect("openeo.cloud")
# 
# p = processes()
# 
# evi_function = function(x,context) {
#   b02 = x[1]
#   b04 = x[2]
#   b08 = x[3]
# 
#   2.5*((b08-b04)/sum(b08,6*b04,-7.5*b02,1))
# }
# 
# login()
# 
# evi_process = create_user_process(evi_function,id = "evi",summary = "Function to be used in a band reducing function with an array of three input values as B02,B04 and B08 of a Sentinel-2 data set.")
# evi_process

## ----eval=FALSE---------------------------------------------------------------
# library(openeo)
# con = connect("openeo.cloud")
# p = processes()
# coll = list_collections()
# 
# data = p$load_collection(id = coll$SENTINEL2_L2A_SENTINELHUB, bands = c("B02","B04","B08"))
# class(data)

## ----eval = FALSE-------------------------------------------------------------
# library(openeo)
# con = connect("openeo.cloud")
# p = processes()
# coll = list_collections()
# 
# # as starting point: process(argument[s]) --> data
# data = p$load_collection(id = coll$SENTINEL2_L2A_SENTINELHUB,temporal_extent = c("2021-05-01","2021-08-31"), band = c("B04","B08"))
# 
# # as modifier: process(data, argument[s]) --> data
# temporal_subset = p$filter_temporal(data = data, extent=c("2021-05-01","2021-08-31"))
# 
# # as modifier with process graph: process(data, arguments, process) --> data
# ndvi_data = p$reduce_dimension(data=temporal_subset,dimension=c("t"),reducer = function(x, ...) {
#   b04 = x[1]
#   b08 = x[2]
# 
#   (b08-b04)/(b08+b04)
# })
# 
# # scalar processes
# p$add(x=2,y=4) # usually used in the former R syntax to manipulate data arrays
# 
# # as save / serializer: process(data, argument[s]) --> void
# result = p$save_result(data=ndvi_data, format = "GTiff")

## ----include=FALSE------------------------------------------------------------
library(openeo)
openeo:::demo_processes()

## -----------------------------------------------------------------------------
describe_process("load_collection")

## -----------------------------------------------------------------------------
library(sf)
p = processes()

bbox = st_bbox(c(xmin=7,xmax=7.5,ymin=52,ymax=52.5))
st_crs(bbox) = 4326

dc = p$load_collection(id = "S2", spatial_extent = bbox,temporal_extent = list("2022-05-20","2022-06-10"))
dc

## -----------------------------------------------------------------------------
dc$parameters$bands = c("B04","B08")
dc

## -----------------------------------------------------------------------------
dc$parameters$temporal_extent = c("2022-05-01",NA)
dc

## -----------------------------------------------------------------------------
dc$parameters$spatial_extent

## -----------------------------------------------------------------------------
bbox_var = create_variable(name="bbox",description = "The bounding box of the process graph")

dc$parameters$spatial_extent = bbox_var
dc

## -----------------------------------------------------------------------------
ndvi_prep_loader = as(dc,"Process")
ndvi_prep_loader

