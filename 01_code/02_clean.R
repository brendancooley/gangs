### SETUP ###

rm(list = ls())
source("00_params.R")
source("helpers.R")

libs <- c("tidyverse", "sp", "rgdal", "rgeos", "maptools", "tigris", 
          "leaflet", "leaflet.extras", "lubridate", "spdep", "sf", "rgdal", "rgeos")
ipak(libs)

crimes_clean <- read_csv(crimes_clean_path) # %>% filter(hnfs==1)
tracts <- readOGR(tracts_path)
crimes_clean %>% filter(hnfs==1) %>% filter(year=="2019-01-01")

minY <- min(crimes_clean$year) %>% year()
maxY <- max(crimes_clean$year) %>% year()

n_y_chunk <- (maxY - minY + 1) %/% y_chunk  # chunks over which to subset analysis

# week, month, year, all
crimes_clean$all <- "all"

### POPULATION DATA (CHICAGO) ###

# TODO: generalize to arbitrary city

pop20002010 <- read_csv(paste0(data_path_base, "pop20002010.csv"))
pop20102018 <- read_csv(paste0(data_path_base, "pop20102018.csv"))

pop20002010$id <- paste0(pop20002010$STATE, pop20002010$PLACE)
pop20102018$id <- pop20102018$`Target Geo Id2`

chi_pop20002009 <- pop20002010 %>% filter(id==chicago_id, COUNTY=="000") %>% dplyr::select(-SUMLEV, -STATE, -COUNTY, -PLACE, -COUSUB, -NAME, -STNAME, -ESTIMATESBASE2000, -id, -CENSUS2010POP, -POPESTIMATE2010)
chi_pop20102018 <- pop20102018 %>% filter(id==chicago_id) %>% dplyr::select(-Id, -Id2, -Geography, -`Target Geo Id`, -`Target Geo Id2`, -Rank, -Geography_1, -Geography_2, -`April 1, 2010 - Census`, -`April 1, 2010 - Estimates Base`, -id)
chi_pop_y <- seq(2000, 2018)

chi_pop <- data.frame(chi_pop_y, c(t(chi_pop20002009), t(chi_pop20102018)))
colnames(chi_pop) <- c("year", "population")
write_csv(chi_pop, pop_path)

### TAG CRIMES TO TRACTS (ALL) ###

crimes_clean <- tag_crimes(crimes_clean, tracts)
# chi_clean %>% filter(is.na(GEOID))  # 41 events untagged
crimes_clean <- crimes_clean %>% filter(!is.na(GEOID))  # drop these from data

# all events
clean_h <- crimes_clean %>% filter(homicide==1)
clean_s <- crimes_clean %>% filter(hnfs==1)  # homicides and non-fatal shootings
clean_n <- crimes_clean %>% filter(narcotics==1, arrest==1) # narcotics arrests

all_h <- agg_crimes(clean_h, "all")
all_s <- agg_crimes(clean_s, "all")
all_n <- agg_crimes(clean_n, "all") 
write_csv(all_h, tha_path)
write_csv(all_s, tsa_path)
write_csv(all_n, tna_path)

# by aggregation
# TODO group by hnfs versus narcotics as above under "all events"
agg_h <- agg_crimes(clean_h, aggregation)
agg_s <- agg_crimes(clean_s, aggregation)
agg_n <- agg_crimes(clean_n, aggregation)

# convert to matrix and vector storing geoids
mat_h <- agg_h %>% spread_(aggregation, "count") %>% dplyr::select(-GEOID)
mat_s <- agg_s %>% spread_(aggregation, "count") %>% dplyr::select(-GEOID)
mat_n <- agg_n %>% spread_(aggregation, "count") %>% dplyr::select(-GEOID)
geoids <- agg_h %>% spread_(aggregation, "count") %>% dplyr::select(GEOID)

write_csv(mat_h, th_mat_path, col_names=FALSE)
write_csv(mat_s, ts_mat_path, col_names=FALSE)
write_csv(mat_n, tn_mat_path, col_names=FALSE)
write_csv(geoids, geoids_path, col_names=FALSE)

# migrate primary matrix (all) to results path for analysis
write_csv(mat_s, paste0(results_path, "all/", "ts_mat.csv"), col_names=FALSE)

# year chunks (just shootings)
for (i in 1:n_y_chunk) {
  miny <- minY + (i-1) * y_chunk
  mkdir(paste0(results_path, miny, "/"))
  maxy <- miny + y_chunk 
  minyd <- ymd(miny, truncated=2L)
  maxyd <- ymd(maxy, truncated=2L)
  mat_s_chunk <- agg_s %>% filter(.[[aggregation]] >= minyd & .[[aggregation]] < maxyd) %>% spread_(aggregation, "count") %>% dplyr::select(-GEOID)
  fname <- paste0(results_path, miny, "/", "ts_mat.csv")
  write_csv(mat_s_chunk, fname, col_names=FALSE)
}


### CONSTRUCT ADJACENCY MATRIX ###

adjacency <- poly2nb(tracts, queen=FALSE)  # queen allows corner merges
adjacency <- nb2mat(adjacency)
adjacency[adjacency > 0] <- 1
# adjacency <- gTouches(chi_tracts, byid=T) * 1 # TODO: currently allowing corner merges, need to convert neighbors code if we use poly2nb

geoid_order <- tracts@data$GEOID
id_df <- data.frame(geoid_order, seq(1, nrow(geoids)))
colnames(id_df) <- c("GEOID", "id")

colnames(adjacency) <- seq(1, nrow(geoids))
rownames(adjacency) <- seq(1, nrow(geoids))
write_csv(adjacency %>% as.data.frame(), tadjacency_path, col_names=FALSE)

### BOOTSTRAP ###

if (runBootstrap==TRUE) {
  N <- nrow(clean_s)
  
  for (i in 1:L) {
    sample_ids <- sample(seq(1, N), N, replace=T)
    clean_s_L <- clean_s[sample_ids, ]
    agg_s_L <- agg_crimes(clean_s_L, aggregation)
    mat_s_L <- agg_s_L %>% spread_(aggregation, "count") %>% dplyr::select(-GEOID)
    write_csv(mat_s_L, paste0(ts_period_bs_path, i, ".csv"), col_names=FALSE)
  }
}

### CPD GANG MAPS ###

# first run clean_gang_maps_replication.R in bruhn_path

load(file=paste0(bruhn_path, "gangMaps.rda"))
# gang.maps

# assign tracts to gangs
gang.maps <- as(gang.maps, 'Spatial') #Transform to an SP object too
# city.blocks <- tracts(17, county = 031, year = 2016) #FOR TRACTS
gang.maps <- spTransform(gang.maps, proj4string(tracts))

ownership <- list()
gang.names <- unique(gang.maps$gang)
n <- length(gang.names)
geoids <- tracts$GEOID
k <- length(tracts$GEOID)

library(raster)

for (m in bruhn_sy:bruhn_ey) {
  
  gang_maps_y <- gang.maps[gang.maps$year==m,]
  ownership_y <- matrix(NA, nrow=n, ncol=(k)) 
  print(paste0("year: ", m))
  
  for (i in 1:n) {
    print(paste0("gang: ", gang.names[i]))
    gang_maps_yi <- gang_maps_y[gang_maps_y$gang==gang.names[i],]
    if (nrow(gang_maps_yi) != 0) {
      gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = "+proj=moll")
      gang_maps_yi <- gBuffer(gang_maps_yi, byid = T, width = -1)
      gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = proj4string(tracts))
      for (j in 1:k) {
        blocks_j <- tracts[tracts$GEOID==geoids[j],]
        if(gIntersects(gang_maps_yi, blocks_j)){
          intersection_yij <- gIntersection(gang_maps_yi, blocks_j)
          print(area(intersection_yij)/area(tracts[tracts$GEOID==geoids[j],]))
          ownership_y[i,j] <- area(intersection_yij)/area(tracts[tracts$GEOID==geoids[j],])
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
gang.names %>% sort()
