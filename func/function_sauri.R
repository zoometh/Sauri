library(htmlwidgets)
library(kableExtra)
library(dplyr)
library(knitr)
library(magick)
library(leaflet)
library(RPostgreSQL)
library(rpostgis)
library(rdrop2)
library(sp)
library(sf)
library(plotly)

remove.packages("Rdev", lib="~/R/win-library/3.6")
# remove.packages("reshape", lib="~/R/win-library/3.6")
rm(list=ls()) # remove all Globs var
.rs.restartR() # uninstall & restart session
devtools::install_github("zoometh/Rdev")
library(Rdev)

# con <- rdev.conn.pg()

rdev.reproj <- function(a.geom){
  # rdev.reproject
  wgs84 <- CRS("+proj=longlat +datum=WGS84")
  a.geom <- spTransform(a.geom, wgs84)
  return(a.geom)
}


roches <- st_read(dsn = "D:/Sites_10/Sauri/GIS/roches_pts", layer = "roches_all")
# roches <- st_crs(roches, 2531)
roches <- st_transform(roches, 4236) # rdev.reproj
leaflet(roches, height = "300px", width = "75%") %>%
  addWMSTiles(
    # "http://geoserveis.icgc.cat/icc_ortohistorica/wms/service?",
    "http://www.ign.es/wms-inspire/pnoa-ma?",
    layers = "OI.OrthoimageCoverage",
    options = WMSTileOptions(format = "image/png", transparent = TRUE),
    attribution = "") %>% 
  # addTiles() %>%  # Add default OpenStreetMap map tiles
  # all rocks
  addCircleMarkers(popup="engraved<br>rock",radius = 1,opacity = 0.3)

# http://geoserveis.icgc.cat/icc_ortohistorica/wms/service?

# rdev.conn.pg <- function(){
#   drv <- dbDriver("PostgreSQL")
#   con <- dbConnect(drv,
#                    dbname="bego",
#                    host="localhost",
#                    port=5432,
#                    user="postgres",
#                    password="postgres")
# }
# 
# rdev.reproj <- function(a.geom){
#   # rdev.reproject
#   a.geom <- spTransform(a.geom, wgs84)
#   return(a.geom)
# }
# 

con <- rdev.conn.pg()
sqll <- "select zone,groupe,roche,nom,histoseule,geographie ,ST_X(ST_Transform(wkb_geometry, 4326)) as x ,ST_Y(ST_Transform(wkb_geometry, 4326)) as y from roches_gravees"
roches.all <- dbGetQuery(con,sqll)
aRoche <- roches.all[roches.all$zone == Z & roches.all$groupe == G & roches.all$roche == R,]
dbDisconnect(con)
Plan_lk <- f.ico.aRoche(Z,G,R)[[2]] # the Plan_lk
aRoche  <- leaflet(width = "50%") %>%
  setView(lng = aRoche$x, lat = aRoche$y, zoom=18) %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  # all rocks
  addCircleMarkers(lng=roches.all$x, lat=roches.all$y,
                   popup="engraved<br>rock",radius = 1,opacity = 0.3) %>%
  addCircleMarkers(lng=aRoche$x, lat=aRoche$y,
                   popup = Plan_lk,
                   color = "red",
                   radius = 2,
                   opacity = 0.7)
R <- gsub("@","x",R)
aRocheName <- paste0("Z",Z,"G",G,"R",R)
saveWidget(aRoche, file=paste0(chm,"/img/",aRocheName,".html"))

