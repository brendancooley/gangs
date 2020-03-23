### SETUP ###

# rm(list = ls())
source("../01_code/00_params.R")

libs <- c("tidyverse", "rgdal", "sf", "tmap", "rgeos")
ipak(libs)

crimes_clean <- read_csv(crimes_clean_path)
tracts <- readOGR(tracts_path, verbose=FALSE)
chi_outline <- gUnaryUnion(tracts)

### CLEAN ###

crimes_clean_hnfs <- crimes_clean %>% filter(hnfs==1)

crimes_clean_geo <- crimes_clean_hnfs %>%
  st_as_sf(coords = c('lng', 'lat'), crs=proj4string(tracts))

### FIGURE ###

# animation
hnfs_animated <- tm_shape(chi_outline) +
  tm_polygons(col="white") +
  tm_shape(crimes_clean_geo) +
  tm_dots(col="red") +
  tm_view(bbox=st_bbox(crimes_clean_geo)) +
  tm_facets(along = "month", free.coords=FALSE)
# tmap_animation(hnfs_animated, filename=hnfs_animated_path, width=1600, delay=40)

# first month, overlaid tracts
months <- crimes_clean_hnfs$month %>% unique() %>% sort()
mfirst <- months[1]
clean_hnfs_first <- crimes_clean_hnfs %>% filter(month==mfirst)

clean_first_geo <- clean_hnfs_first %>%
  st_as_sf(coords = c('lng', 'lat'), crs=proj4string(tracts))

hnfs_ex_mfirst_tracts <- tm_shape(tracts) +
  tm_borders(col="black", alpha=.5) +
  tm_shape(clean_first_geo) +
  tm_dots(col="red", size=.05) +
  tm_layout(outer.bg.color="white", bg.color="white") +
  tm_view(bbox=st_bbox(crimes_clean_geo))
