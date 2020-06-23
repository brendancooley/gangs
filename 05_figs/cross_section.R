### SETUP ###

# rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "rgdal", "sf", "tmap", "tigris", "lubridate", "leaflet")
ipak(libs)

tha <- read_csv(tha_path)
tsa <- read_csv(tsa_path)
tna <- read_csv(tna_path)

covar <- read_csv(paste0(covariates_path, covar_y, ".csv"))
tracts <- readOGR(tracts_path, verbose=FALSE)
# nrow(tracts)
chi_outline <- gUnaryUnion(tracts)

crimes_clean <- read_csv(crimes_clean_path)
minY <- min(crimes_clean$year) %>% year()
maxY <- max(crimes_clean$year) %>% year()

### CLEAN ###

tha <- tha %>% left_join(covar)
tsa <-tsa %>% left_join(covar)
tna <- tna %>% left_join(covar)

# construct hnfs/arrest rates per tract
tha$rate <- tha$count / tha$population
tsa$rate <- tsa$count / tsa$population
tna$rate <- tna$count / tna$population

tsa_geo <- geo_join(tracts, tsa, "GEOID", "GEOID")
tna_geo <- geo_join(tracts, tna, "GEOID", "GEOID")

### FIGURES ###

hmColors <- colorRampPalette(c("white", bcOrange))(10)

tsa_map <- tm_shape(tsa_geo) +
  tm_fill(col="rate", title=paste0("Homicides and Non-Fatal Shootings \n per Capita, ", bruhn_sy, "-", bruhn_ey), palette=hmColors) +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  tm_layout(legend.outside=TRUE)
# save_tmap(chi_tsa_map, "figs/chi_tsa_map.png")

tna_map <- tm_shape(tna_geo) +
  tm_polygons("rate", title=paste0("Narcotics-Related Arrests per Capita ", bruhn_sy, "-", bruhn_ey)) +
  tm_layout(legend.position=c("left", "bottom"))

# leaflet (interactive) version
popup <- paste0("GEOID: ", tsa_geo$GEOID, "<br>", "Shootings: ", tsa_geo$count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = tsa_geo$count)

tsa_map_leaflet <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = tsa_geo, 
              fillColor = ~pal(count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
