### SETUP ###

rm(list = ls())
source("00_params.R")

libs <- c("tidyverse", "lubridate", "acs", "tigris", "sp", "rgdal", "tigris", "leaflet", "leaflet.extras")
ipak(libs)

years <- c(2009, 2016)  # years for which to get census data
aggregation <- "week"

# Reading in Census Tract Boundaries
cook.tracts <-  tracts("Illinois", county = "031", year = 2016, refresh=TRUE)  # Cook County Block Groups
# TODO: get block groups

### SUBSET CHICAGO TRACTS ###

# TODO: generalize to arbitrary city

chi_shp <- readOGR(chi_shape_path, "Chicago")
chi_shp <- spTransform(chi_shp, proj4string(cook.tracts))  # match CRS 
proj4string(chi_shp) <- proj4string(cook.tracts)
library(raster)
chi_tracts <- intersect(cook.tracts, chi_shp)
chi_tracts <- subset(chi_tracts, !(GEOID %in% airport_ids)) # drop airports
chi_tracts <- subset(chi_tracts, !(GEOID %in% drop_ids)) # drop other Cook weirdos
chi_tracts_ids <- chi_tracts@data$GEOID
detach("package:raster", unload=TRUE)  # masks select from dplyr

if (!dir.exists(tracts_path)) {
  mkdir(tracts_path)
  writeOGR(chi_tracts, tracts_path, driver="ESRI Shapefile", layer='tracts')
  # NOTE: warnings ok, see https://github.com/r-spatial/sf/issues/306
}

### Victim-Based Crime Reports ###

crimes <- read_csv(chi_crimes_raw_url, 
                   col_types=list(`X Coordinate`=col_double(), `Y Coordinate`=col_double(), Latitude=col_double(), Longitude=col_double(), Location=col_character()))

crimes$dateChr <- substr(crimes$Date, 1, 10)
crimes$date <- as.Date(crimes$dateChr, format="%m/%d/%Y")
crimes$month <- floor_date(crimes$date, "month")
crimes$week <- floor_date(crimes$date, "week")
crimes$year <- as.Date(paste0(crimes$Year, "-01-01"))
# crimes$year %>% unique() 

# subset years
crimes <- crimes %>% filter(year >= ymd(start_year, truncated=2L), year < ymd(end_year+1, truncated=2L))

crimes$lat <- crimes$Latitude
crimes$lng <- crimes$Longitude

homicide_iucr <- c("0110", "0130")
hnfs_iucr <- c("0110", "0130", "041A", "041B")  # First and Second degree homicide and Aggravated Battery with a handgun or other firearm
# NOTE: see codes: https://data.cityofchicago.org/Public-Safety/Chicago-Police-Department-Illinois-Uniform-Crime-R/c7ck-438e/data
# NOTE: does not include aggravated assault: threat/display of firearm (0450, 0451)
# NOTE: does not include aggravated battery against protected employee by firearm (0480, 0481)
# NOTE: does not include ritual mutilation by firearm (0490, 0491)
# NOTE: does not include weapons violation, unlawful use of firearm (0141A, 0141B)
narcotics_fbi <- c("18") # http://gis.chicagopolice.org/clearmap_crime_sums/crime_types.html

crimes$homicide <- ifelse(crimes$IUCR %in% homicide_iucr, 1, 0)
crimes$hnfs <- ifelse(crimes$IUCR %in% hnfs_iucr, 1, 0)
crimes$narcotics <- ifelse(crimes$`FBI Code` %in% narcotics_fbi, 1, 0)
crimes$arrest <- ifelse(crimes$Arrest==TRUE, 1, 0)

crimesClean <- crimes %>% filter(hnfs==1 | narcotics==1) %>% filter(!is.na(lat) & !is.na(lng) & lat > 40) %>% select(date, year, month, week, lat, lng, homicide, hnfs, narcotics, arrest)
# crimesClean %>% filter(hnfs==1)

write_csv(crimesClean, crimes_clean_path)  # to data folder
write_csv(crimesClean, paste0(shiny_path, "crimes_clean.csv")) # to shiny folder

### GET CENSUS DATA ###

for (i in years) {

  api.key.install(key="9e14fb5cda17c74f8b723def3de2ada902631d4c")
  geo <- geo.make(state=c(17), county=c(31), tract = "*") # Creating a Geographic Set for which to Grab Tabular Data from the ACS
  
  # Then Pulling Out the Median Household Income and Per Capita Income
  income <- acs.fetch(endyear = i, span = 5, geography = geo,
                      table.number = c("B19001"), col.names = "pretty") # median household income

  # Converting the Data to a Dataframe for Merging
  # convert to a data.frame for merging
  income_df <- data.frame(paste0(str_pad(income@geography$state, 2, "left", pad="0"),
                                 str_pad(income@geography$county, 3, "left", pad="0"),
                                 str_pad(income@geography$tract, 6, "left", pad="0"),
                                 str_pad(income@geography$blockgroup, 1, "left", pad="0")),
                          income@estimate,
                          stringsAsFactors = FALSE)

  rownames(income_df) <- 1:nrow(income_df)
  names(income_df) <- c("GEOID", "total", "less_10" , "between_10-15", "between_15-20", "between20-25",
                        "between_25-30", "between_30-35", "between_35-40", "between_40-45",
                        "between_45-50", "between_50-60", "between_60-75", "between_75-100",
                        "between_100-125", "between_125-150", "between_150-200" ,"over_200")

  # Next recall the per-capita income data
  capita <- acs.fetch(endyear = i, span = 5, geography = geo,
                      table.number = c("B19301"), col.names = "pretty") # Per capita income given by, B19301

  income_df$capita <- as.numeric(capita@estimate)
  income_df$capita[income_df$capita < 0] <- 1  # use 1 so log still works

  income_df$ln_capita <- log(income_df$capita)

  # population
  pop <- acs.fetch(endyear=i, span=5, geography=geo, table.number=c("B01003"), col.names="pretty")
  income_df$population <- as.numeric(pop@estimate)
  
  # income_df$rounded <- as.numeric(round(income_df$capita, digits = -3))/1000

  income_df <- income_df %>% as_tibble()
  income_df <- income_df %>% filter(GEOID %in% chi_tracts_ids)  # filter out cook county non-city
  
  # export to data folder
  # write_csv(income_df, paste0(covariates_path, i, ".csv"))
  # export to shiny
  # write_csv(income_df, paste0(shiny_path, i, ".csv"))
  
  ### ETHNICITY ###
  
  # Creating a Geographic Set for which to Grab Tabular Data from the ACS
  # Then Pulling A General Race Table that also includes population totals in each tract
  race <- acs.fetch(endyear = i, span = 5, geography = geo,
                    table.number = c("B02001"), col.names = "pretty")
  
  # convert to a data.frame for merging
  race_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                               str_pad(race@geography$county, 3, "left", pad="0"),
                               str_pad(race@geography$tract, 6, "left", pad="0")),
                        race@estimate,
                        stringsAsFactors = FALSE)
  rownames(race_df)<-1:nrow(race_df)
  names(race_df)<-c("GEOID", "total", "white" , "black", "american.indian", "asian",
                    "native.hawian","other", "two.or.more", "two.or.more.including.some.other",
                    "two.or.more.including.some.other.and.three.or.more")
  
  #Pulling up black/african american table to get total identifying as black in a tract
  black <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                     table.number = c("B02009"), col.names = "pretty")
  black_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                                str_pad(race@geography$county, 3, "left", pad="0"),
                                str_pad(race@geography$tract, 6, "left", pad="0")),
                         black@estimate,
                         stringsAsFactors = FALSE)
  rownames(black_df)<-1:nrow(black_df)
  names(black_df)<-c("GEOID", "black")
  
  #Pulling up hispanic table (not included in race table)
  latino <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                      table.number = c("B03003"), col.names = "pretty")
  latino_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                                 str_pad(race@geography$county, 3, "left", pad="0"),
                                 str_pad(race@geography$tract, 6, "left", pad="0")),
                          latino@estimate,
                          stringsAsFactors = FALSE)
  rownames(latino_df)<-1:nrow(latino_df)
  names(latino_df)<-c("GEOID", "total","not.latino","latino")
  
  ethnicity <- data.frame(race_df$GEOID, race_df$total, black_df$black, latino_df$latino)
  names(ethnicity) <- c("GEOID", "total","black","latino")
  ethnicity$percentage.black <- ethnicity$black/ethnicity$total
  ethnicity$percentage.latino <- ethnicity$latino/ethnicity$total
  
  ethnicity <- ethnicity %>% filter(GEOID %in% chi_tracts_ids)
  
  income_df <- income_df %>% left_join(ethnicity)
  
  write_csv(income_df, paste0(covariates_path, i, ".csv"))
  
}

### POPULATION DATA ###

# population of U.S. municipalities
pop20102018 <- read_csv("https://www.dropbox.com/s/76t3iddlrtupul0/census20102018.csv?dl=1", skip=1)
pop20002010 <- read_csv("https://www.dropbox.com/s/oy1gtu7marwwoht/census20002010.csv?dl=1")

write_csv(pop20102018, paste0(data_path_base, "pop20102018.csv"))
write_csv(pop20002010, paste0(data_path_base, "pop20002010.csv"))