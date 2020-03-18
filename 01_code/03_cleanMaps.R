### SETUP ###

rm(list = ls())
source("00_params.R")
source("helpers.R")

libs <- c("tidyverse", "sp", "rgdal", "rgeos", "maptools", "tigris", 
          "leaflet", "leaflet.extras", "lubridate", "spdep", "sf", "rgeos")
ipak(libs)

tracts <- readOGR(tracts_path)

### CPD GANG MAPS ###

# first run clean_gang_maps_replication.R in bruhn_path
load(file=paste0(bruhn_path, "gangMaps.rda"))

# gang correspondence
gang_correspondence <- read_csv(gang_correspondence_path, col_names=FALSE)
colnames(gang_correspondence) <- c("old_name", "new_name")

# assign tracts to gangs
gang.maps <- as(gang.maps, 'Spatial') #Transform to an SP object too
# city.blocks <- tracts(17, county = 031, year = 2016) #FOR TRACTS
gang.maps <- spTransform(gang.maps, proj4string(tracts))

# merge gang polygons
for (i in unique(gang.maps$gang)) {
  new_name_idx <- which(gang_correspondence$old_name==i)
  new_name <- gang_correspondence$new_name[new_name_idx]
  gang.maps$gang[gang.maps$gang==i] <- new_name
}

# polygon unions
gang.maps$ID <- paste0(gang.maps$gang, "-", gang.maps$year)

gang.maps <- spTransform(gang.maps, CRSobj="+proj=moll")
gang.maps <- gBuffer(gang.maps, byid = T, width = -1) # add small buffer to prevent self-intersections
gang.maps <- spTransform(gang.maps, CRSobj=proj4string(tracts))
gang.maps.data <- gang.maps@data %>% unique()
row.names(gang.maps.data) <- as.character(gang.maps.data$ID)

gang.maps.polygons <- unionSpatialPolygons(gang.maps, gang.maps$ID)

gang.maps <- SpatialPolygonsDataFrame(gang.maps.polygons, gang.maps.data)

# testing
# vl <- test[test$gang=="vice lords", ]
# vl2004 <- vl[vl$year==2016, ]
# 
# leaflet(vl2004) %>%
#   addPolygons()

# calculate gang areas by year
gang.maps$area <- raster::area(gang.maps)

# export
gang.maps@data %>% select(-ID) %>% as_tibble() %>% write_csv(paste0(gang_territory_path, "gang_area_year.csv"))

# average over years
gang_area_means <- gang.maps@data %>% as_tibble() %>% group_by(gang) %>% summarise(area_mean=mean(area)) %>% 
  arrange(desc(area_mean)) # average over years

# export
gang_area_means %>% write_csv(paste0(gang_territory_path, "gang_area_means.csv"))

# construct ownership matrices over tracts
ownership <- list()
gang.names <- unique(gang.maps$gang)
n <- length(gang.names)
geoids <- tracts$GEOID
k <- length(tracts$GEOID)

for (m in bruhn_sy:bruhn_ey) {
  
  gang_maps_y <- gang.maps[gang.maps$year==m,]
  ownership_y <- matrix(NA, nrow=n, ncol=(k)) 
  print(paste0("year: ", m))
  
  for (i in 1:n) {
    print(paste0("gang: ", gang.names[i]))
    gang_maps_yi <- gang_maps_y[gang_maps_y$gang==gang.names[i],]
    if (nrow(gang_maps_yi) != 0) {
      # gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = "+proj=moll")
      # gang_maps_yi <- gBuffer(gang_maps_yi, byid = T, width = -1)
      # gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = proj4string(tracts))
      for (j in 1:k) {
        blocks_j <- tracts[tracts$GEOID==geoids[j],]
        if(gIntersects(gang_maps_yi, blocks_j)){
          intersection_yij <- gIntersection(gang_maps_yi, blocks_j)
          print(raster::area(intersection_yij)/raster::area(tracts[tracts$GEOID==geoids[j],]))
          ownership_y[i,j] <- raster::area(intersection_yij)/raster::area(tracts[tracts$GEOID==geoids[j],])
        }
        else {
          ownership_y[i,j] <- 0
        }
      }
    } else {
      for (j in 1:k) {
        ownership_y[i,j] <- 0
      }
    }
    print(i)
    ownership[[m]] <- ownership_y
    # write to csv
    write_csv(ownership[[m]] %>% as.data.frame(), paste0(gang_territory_path, m, ".csv"), col_names=FALSE)
  }
}

write_csv(geoids %>% as.data.frame(), paste0(gang_territory_path, "geoids.csv"), col_names=FALSE)  # columns
write_csv(gang.names %>% as.data.frame(), paste0(gang_territory_path, "gang.names.csv"), col_names=FALSE)  # rows
