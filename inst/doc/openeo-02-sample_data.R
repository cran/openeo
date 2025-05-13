## ----setup,echo=FALSE, eval=FALSE---------------------------------------------
# library(openeo)

## ----eval=FALSE---------------------------------------------------------------
# con = connect("https://openeo.cloud")
# login()

## ----eval=FALSE---------------------------------------------------------------
# p = processes()
# coll = list_collections()
# f = list_file_formats()
# 
# bounding_box = list(west=6.75,south=51.85,east=7.25,north=52.15)
# 
# data = p$load_collection(id = coll$SENTINEL2_L2A,
#                          bands=c("B04","B08"),
#                          spatial_extent = bounding_box,
#                          temporal_extent = list("2021-03-01","2021-07-15"))
# 
# ndvi = p$reduce_dimension(data=data, dimension = "bands",reducer = function(x, context) {
#   b04 = x[1]
#   b08 = x[2]
#   (b08-b04)/(b08+b04)
# })

## ----eval=FALSE---------------------------------------------------------------
# res = p$save_result(ndvi, format = f$output$netCDF)

## ----eval=FALSE---------------------------------------------------------------
# as(res,"Process")

## ----eval=FALSE---------------------------------------------------------------
# center = list(lon=mean(c(bounding_box$west, bounding_box$east)), lat=mean(c(bounding_box$south, bounding_box$north)))
# diff = 0.0003
# sample_bbox = list(west=center$lon-diff,south=center$lat-diff,east=center$lon+diff,north=center$lat+diff)

## ----eval=FALSE---------------------------------------------------------------
# data$parameters$spatial_extent = sample_bbox

## ----eval=FALSE---------------------------------------------------------------
# data

## ----eval=FALSE---------------------------------------------------------------
# manual_file = "test_manual.nc"
# file = compute_result(res,output_file = manual_file)

## ----eval=FALSE,results='asis', warning=FALSE---------------------------------
# library(stars)
# obj = read_stars(manual_file,driver = detect.driver(manual_file))
# obj

## ----eval=FALSE, warning=FALSE------------------------------------------------
# library(lubridate)
# library(stars)
# library(ggplot2)
# 
# dates = as_date(st_get_dimension_values(obj,"t"))
# obj = st_set_dimensions(obj,which="t",values = dates)
# obj

## ----eval=FALSE,out.height='400px',out.width='600px'--------------------------
# ggplot() + geom_stars(data=obj) + facet_wrap(~t) + coord_equal() + theme_void()

## ----eval=FALSE---------------------------------------------------------------
# data$parameters$spatial_extent = bounding_box
# data

## ----eval=FALSE, warning=FALSE------------------------------------------------
# library(mapview)
# library(sf)
# 
# initial_bbox = as.numeric(bounding_box)
# names(initial_bbox) = c("xmin","ymin","xmax","ymax")
# sample_bbox = as.numeric(sample_bbox)
# names(sample_bbox) = c("xmin","ymin","xmax","ymax")
# 
# initial_bbox = st_as_sfc(st_bbox(initial_bbox,crs=4326))
# sample_bbox = st_as_sfc(st_bbox(sample_bbox,crs=4326))
# 
# received_data_bbox = st_as_sfc(st_bbox(obj))
# 
# mapview(list(initial_bbox,sample_bbox,received_data_bbox))

## ----eval=FALSE---------------------------------------------------------------
# ?get_sample

## ----eval=FALSE---------------------------------------------------------------
# ?compute_result

## ----eval=FALSE---------------------------------------------------------------
# f = list_file_formats()

## ----eval=FALSE, warning=FALSE------------------------------------------------
# sample_file = "test_get_sample.nc"
# obj = get_sample(ndvi,
#                  as_stars=TRUE,
#                  output_file=sample_file,
#                  format = f$output$netCDF)

## ----eval=FALSE---------------------------------------------------------------
# obj

## ----eval=FALSE---------------------------------------------------------------
# library(lubridate)
# library(stars)
# library(ggplot2)
# 
# dates = as_date(st_get_dimension_values(obj,"t"))
# obj = st_set_dimensions(obj,which="t",values = dates)

## ----eval=FALSE, out.height="400px",out.width="600px"-------------------------
# ggplot() + geom_stars(data=obj) + facet_wrap(~t) + coord_equal() + theme_void()

## ----eval=FALSE---------------------------------------------------------------
# library(mapview)
# library(sf)
# 
# received_data_bbox = st_as_sfc(st_bbox(obj))
# 
# mapview(list(initial_bbox,received_data_bbox))

