### SETUP ###

rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "rgdal", "sf", "tmap", "tigris")
ipak(libs)

pop <- read_csv(paste0(covariates_path, covar_y, ".csv")) %>% select(GEOID, population)
tracts <- readOGR(tracts_path)

### FIGURE ###

chi_pop_geo <- geo_join(tracts, pop, "GEOID", "GEOID")

chi_pop_map <- tm_shape(chi_pop_geo) +
  tm_polygons("population", title=paste0("Population Estimates, 2016")) +
  tm_layout(legend.position=c("left", "bottom"))
