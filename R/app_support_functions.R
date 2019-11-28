##################################################
## Project: UFOKN Nervous Norman Application
## Script purpose: Support scripts for App
## Date: Nov 27, 2019
## Author: @mikejohnson
##################################################


IPgeocode = function() {
  jsonlite::fromJSON('https://json.geoiplookup.io/') %>%
    data.frame() %>% 
    mutate(request = isp) %>% 
    sf::st_as_sf(coords = c('longitude', 'latitude')) %>%
    st_set_crs('+proj=longlat +datum=WGS84')
}


get_data = function(pt) {
  list(pt = pt, comid = nhdplusTools::discover_nhdplus_id(pt))
}

map  = function(d) {
  
  pop <- paste(
    paste("<strong>Location:</strong>", d$pt$request),
    paste("<strong>COMID:</strong>", d$comid),
    sep = "<br/>"
  )
  
  leaflet() %>%
    addTiles() %>%
    addMarkers(data = d$pt, popup = pop) 
}

add_osm = function(d, feature){
  AOI::getAOI(list(st_coordinates(d$pt)[2],st_coordinates(d$pt)[1], .25, .25)) %>%
    opq() %>% 
    add_osm_feature(feature) %>% 
    osmdata_sf() 
}

add_building = function(m, d){
  
  xy = add_osm(d, "buildings")
  
  if(!is.null(xy$osm_polygons)){
    
    b = st_transform(xy$osm_polygons, 4269)
    
    build_pop  =  paste(
      paste("<strong>ID:</Name>", b$osm_id),
      paste("<strong>Location:</Name>", b$name),
      paste("<strong>Number:</strong>", b$addr.housenumber),
      paste("<strong>Street:</strong>", b$addr.street),
      sep = "<br/>"
    )
    
    m = m %>% addPolygons(data = b, fill = 'green', stroke = F, weight   = .3, opacity = 1, popup = build_pop)
  }
  
  return(m)
}


add_roads = function(m, d){
  
  xy = add_osm(d, "highway")
  
  if(!is.null(xy$osm_lines)){
    
  l = st_transform(xy$osm_lines, 4269)
  
  road_pop  <- paste(
    paste("<strong>ID:</strong>", l$osm_id),
    paste("<strong>Name:</strong>", l$name),
    paste("<strong>Type:</strong>", l$highway),
    sep = "<br/>"
  )
  
  m = m %>% addPolylines(data = l, color = 'black', popup = road_pop)
  }
  
  return(m)

}

add_flood_grid = function(m, d){
  
  xy = AOI::getAOI(list(st_coordinates(d$pt)[2],st_coordinates(d$pt)[1], .35, .35)) %>%
    st_transform(5070) %>% 
    st_make_grid(c(10,10)) %>% 
    st_transform(4269)
  
  m %>% addPolylines(data = xy, color = 'black', weight = .5)
  
}

add_hydro = function(m, d){
  
  nhd   = HydroData::findNHD(comid = d$comid)[[2]]
  catch = HydroData::query_cida(AOI::getBoundingBox(nhd), type = "catchments") %>% filter(featureid == d$comid)
  
  
  m = m %>% addPolylines(data = nhd, color = 'blue', weight = 2) %>% 
    addPolygons(data = catch, fill = NA, color = 'red')
  
  return(m)
}