## ----eval=FALSE---------------------------------------------------------------
#  library(openeo)
#  
#  url = "https://earthengine.openeo.org"
#  
#  con = connect(host=url)

## ----eval=FALSE---------------------------------------------------------------
#  capabilities()

## ----eval=FALSE---------------------------------------------------------------
#  list_collections()

## ----eval=FALSE---------------------------------------------------------------
#  colls = list_collections()
#  class(colls)

## ----eval=FALSE---------------------------------------------------------------
#  str(colls$`COPERNICUS/S2`)

## ----paged.print = FALSE, eval=FALSE------------------------------------------
#  describe_collection(collection = colls$`COPERNICUS/S2`)

## ----paged.print=FALSE, eval=FALSE--------------------------------------------
#  process_list = list_processes()
#  
#  process_list[1:3]

## ----eval=FALSE---------------------------------------------------------------
#  process_viewer(x = "load_collection")
#  
#  process_viewer(x=process_list[1])
#  
#  p = processes()
#  process_viewer(x=p$load_collection)

## ----paged.print = FALSE, eval=FALSE------------------------------------------
#  process_list$`if`

## ----paged.print = FALSE, eval=FALSE------------------------------------------
#  process_list$`sum`

## ----eval=FALSE---------------------------------------------------------------
#  formats = list_file_formats()
#  class(formats)

## ----paged.print = FALSE, eval=FALSE------------------------------------------
#  formats

## ----paged.print=FALSE, eval=FALSE--------------------------------------------
#  formats$output$PNG

## ----eval=FALSE---------------------------------------------------------------
#  class(formats$output$PNG)

## ----paged.print=FALSE, eval=FALSE--------------------------------------------
#  service_types = list_service_types()
#  service_types

## ----eval=FALSE---------------------------------------------------------------
#  user = ""
#  pwd = ""
#  
#  login(user = user,password = pwd)

## ----paged.print = FALSE, eval=FALSE------------------------------------------
#  describe_account()

## ----eval=FALSE---------------------------------------------------------------
#  list_files()

## ----eval=FALSE---------------------------------------------------------------
#  file = tempfile(fileext = ".json")
#  
#  download.file(url = "https://raw.githubusercontent.com/Open-EO/openeo-r-client/master/examples/polygons.geojson", destfile = file)
#  
#  openeo::upload_file(content=file,target="aoi/polygons.json")
#  
#  file.remove(file)

## ----eval=FALSE---------------------------------------------------------------
#  list_files()

## ----eval=FALSE---------------------------------------------------------------
#  dl_file = download_file(src="aoi/polygons.json", dst = file)

## ----eval=FALSE---------------------------------------------------------------
#  cat(readChar(dl_file,nchars = file.size(dl_file)))

## ----eval=FALSE---------------------------------------------------------------
#  delete_file(src = "aoi/polygons.json")

## ----eval=FALSE---------------------------------------------------------------
#  list_files()

## ----echo=FALSE, include=FALSE, eval=FALSE------------------------------------
#  file.remove(dl_file)
#  rm(dl_file)

## ----eval=FALSE---------------------------------------------------------------
#  p = processes()

## ----eval=FALSE---------------------------------------------------------------
#  class(p)

## ----eval=FALSE---------------------------------------------------------------
#  names(p)

## ----eval=FALSE---------------------------------------------------------------
#  names(list_processes())

## ----eval=FALSE---------------------------------------------------------------
#  class(p$load_collection)

## ----eval=FALSE---------------------------------------------------------------
#  formals(p$load_collection)

## ----paged.print=FALSE, eval=FALSE--------------------------------------------
#  describe_process(process = "load_collection")

## ----eval=FALSE---------------------------------------------------------------
#  data = p$load_collection(id = colls$`COPERNICUS/S2`,
#                               spatial_extent = list(
#                                 west=16.1,
#                                 east=16.6,
#                                 north=48.6,
#                                 south= 47.2
#                               ),
#                               temporal_extent = list(
#                                 "2018-04-01", "2018-05-01"
#                               ),
#                               bands=list("B8","B4"))
#  
#  spectral_reduce = p$reduce_dimension(data = data, dimension = "bands",reducer = function(data,context) {
#    b8 = data[1]
#    b4 = data[2]
#  
#    return((b8-b4)/(b8+b4))
#  })
#  
#  temporal_reduce = p$reduce_dimension(data=spectral_reduce,dimension = "t", reducer = function(x,y){
#    min(x)
#  })
#  
#  apply_linear_transform = p$apply(data=temporal_reduce,process = function(value,...) {
#    p$linear_scale_range(x = value,
#                             inputMin = -1,
#                             inputMax = 1,
#                             outputMin = 0,
#                             outputMax = 255)
#  })
#  
#  result = p$save_result(data=apply_linear_transform,format=formats$output$PNG)

## ----eval=FALSE---------------------------------------------------------------
#  temp = tempfile()
#  file = compute_result(graph = result, output_file = temp)

## ----eval=FALSE---------------------------------------------------------------
#  r = raster::raster(file)
#  raster::spplot(r)

## ----eval=FALSE---------------------------------------------------------------
#  job = create_job(graph=result,title = "Minimum NDVI", description = "Minimum NDVI calculation on Sentinel-2 data, including a linear scaling into 0 to 255 and exporting as PNG file.")

## ----eval=FALSE---------------------------------------------------------------
#  jobs = list_jobs()
#  jobs

## ----eval=FALSE---------------------------------------------------------------
#  jobs[[job$id]]

## ----eval=FALSE---------------------------------------------------------------
#  describe_job(job = job)

## ----eval=FALSE---------------------------------------------------------------
#  start_job(job=job)

## ----eval=FALSE---------------------------------------------------------------
#  list_jobs()

## ----paged.print=FALSE, eval=FALSE--------------------------------------------
#  list_results(job=job)

## ----eval=FALSE---------------------------------------------------------------
#  dir = tempdir()
#  download_results(job=job, folder = dir)

## ----eval=FALSE---------------------------------------------------------------
#  list.files(dir)

## ----eval=FALSE---------------------------------------------------------------
#  delete_job(job=job)

## ----eval=FALSE---------------------------------------------------------------
#  service_types = list_service_types()

## ----eval=FALSE---------------------------------------------------------------
#  test_service = create_service(type = service_types$xyz, graph = result, title = "XYZ service for minimum EVI", description = "XYZ service for minimum EVI from the getting_started guide.",enabled = TRUE)

## ----eval=FALSE---------------------------------------------------------------
#  list_services()

## ----eval=FALSE---------------------------------------------------------------
#  describe_service(service = test_service)

## ----eval=FALSE---------------------------------------------------------------
#  library(magrittr)
#  library(leaflet)
#  leaflet() %>% addTiles() %>% addTiles(test_service$url, tileOptions(tms=TRUE)) %>% setView(lng = 16.363449,lat=48.210033,zoom = 7)

