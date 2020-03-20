### SETUP ###

# rm(list = ls())
# invisible(lapply(paste0('package:', names(sessionInfo()$otherPkgs)), detach, character.only=TRUE, unload=TRUE))
source("../01_code/00_params.R")

libs <- c("tidyverse", "tigris", "tmap", "rgdal", "GISTools", "scales", "leaflet", "stringi")
ipak(libs)

tracts <- readOGR(tracts_path, verbose=FALSE)
chi_outline <- gUnaryUnion(tracts)

y <- 2016

read_csv(paste0(covariates_path, y, ".csv")) 
covariates <- read_csv(paste0(covariates_path, y, ".csv")) %>% dplyr::select(GEOID, percentage.black, percentage.latino)
colnames(covariates) <- c("GEOID", "black", "latino")

col_black <- "#1A81D0"
col_latino <- "#C3734A"

col_correspondence <- data.frame(c(col_black, col_latino), c("black", "latino"))
colnames(col_correspondence) <- c("color", "max_race")

### CLEAN ###

covariates$black[is.na(covariates$black)] <- 0
covariates$latino[is.na(covariates$latino)] <- 0

mat <- covariates %>% dplyr::select(black, latino) %>% as.matrix()
covariates$max_race <- c("black", "latino")[apply(mat, 1, which.max)]
covariates$alpha <- apply(mat, 1, max)
covariates$alpha <- ifelse(covariates$alpha >=1, .99, covariates$alpha)

covariates <- covariates %>% left_join(col_correspondence)
# covariates$color <- covariates$color %>% as.character()
covariates$color_a <- add.alpha(covariates$color, covariates$alpha)
covariates_geo <- geo_join(tracts, covariates, "GEOID", "GEOID")

ethnicity_map <- tm_shape(covariates_geo) +
  tm_fill(col="color_a") +
  tm_borders(col="white") +
  tm_shape(chi_outline) +
  tm_borders(col="black") +
  tm_add_legend(type="fill", labels=stri_trans_totitle(col_correspondence$max_race), col=as.character(col_correspondence$color), title="Ethnicity") +
  tm_layout(paste0("Black and Latino Population Shares ", y), bg.color="white", outer.bg.color="white", legend.position=c("left", "bottom"))
