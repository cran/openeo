test_that("numeric epsg code works", {
  tryCatch({
    code = openeo:::BoundingBox$new()
    code$setValue(list(west = 16.06, south = 48.06, east = 16.65, north = 48.35, crs = 3857))
    
    msg = code$validate()
    expect(length(msg)==0,failure_message = "It doesn't work")
  }, error = function(e) {
    expect(FALSE,failure_message=e$message)
  })
})

test_that("epsg code as string works", {
  tryCatch({
    code = openeo:::BoundingBox$new()
    code$setValue(list(west = 16.06, south = 48.06, east = 16.65, north = 48.35, crs = "EPSG:3857"))
    
    msg = code$validate()
    expect(length(msg)==0,failure_message = "It doesn't work") 
  }, error = function(e) {
    expect(FALSE,failure_message=e$message)
  })
})

test_that("class bbox works with argument BoundingBox", {
  tryCatch({
    bbox = sf::st_bbox(c(xmin=10.711799440170706, xmax= 11.542794097651838, ymin=45.92724558214729, ymax= 46.176044942018734),crs = 4326)
    code = openeo:::BoundingBox$new()
    code$setValue(bbox)
    
    msg = code$validate()
    expect(length(msg)==0,failure_message = "It doesn't work") 
  }, error = function(e) {
    expect(FALSE,failure_message=e$message)
  })
})


test_that("class bbox with non 4326 crs works with argument BoundingBox", {
  tryCatch({
    bbox = st_bbox(c(xmin=632126.8, xmax= 697150.3, ymin=5087388.7, ymax= 5116750.7),crs = 25832)
    code = openeo:::BoundingBox$new()
    code$setValue(bbox)
    
    msg = code$validate()
    expect(length(msg)==0,failure_message = "It doesn't work") 
    
    serialized = code$serialize()
    expect(all(serialized$crs == 25832,
               serialized$west == unname(bbox$xmin),
               serialized$east == unname(bbox$xmax),
               serialized$south == unname(bbox$ymin),
               serialized$north == unname(bbox$ymax)),failure_message="Serialization is not equal")
    
  }, error = function(e) {
    expect(FALSE,failure_message=e$message)
  })
})

test_that("bboxable sf", {
  skip_if_not_installed("sf")
  # geojson = sf::read_sf("D:/Downloads/file_001.json")
  geojson = sf::read_sf(system.file("geojson/polygons.geojson",package="openeo"))
  code = openeo:::BoundingBox$new()
  code$setValue(geojson)
  
  msg = code$validate()
  expect(length(msg)==0,failure_message = paste("It doesn't validate:",msg)) 
  
  serialized = code$serialize()
})

test_that("bboxable stars", {
  skip_if_not_installed("stars")
  img = stars::read_stars(system.file("tif/L7_ETMs.tif",package = "stars"))
  code = openeo:::BoundingBox$new()
  code$setValue(img)

  msg = code$validate()
  expect(length(msg)==0,failure_message = paste("It doesn't validate:",msg))
})

test_that("bboxable terra", {
  skip_if_not_installed("terra")
  img = terra::rast(system.file("tif/L7_ETMs.tif",package = "stars"))
  code = openeo:::BoundingBox$new()
  code$setValue(img)
  
  msg = code$validate()
  expect(length(msg)==0,failure_message = paste("It doesn't validate:",msg))
})
