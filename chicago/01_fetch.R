### TODO ###

# start with block groups and use regionalization to aggregate, gives finer footprint in important regions

### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}
# getwd()

source("params.R")

libs <- c("tidyverse", "lubridate", "acs", "tigris", "sp", "rgdal", "tigris", "leaflet", "leaflet.extras")
ipak(libs)

years <- c(2009, 2016)  # years for which to get census data
aggregation <- "week"

# Reading in Census Tract Boundaries
cook.tracts <-  tracts("Illinois", county = "031", year = 2016, refresh=TRUE)   #Cook County Block Groups

### SUBSET CHICAGO TRACTS ###

chi_shp <- readOGR(chi_shape_path, "Chicago")
chi_shp <- spTransform(chi_shp, proj4string(cook.tracts))  # match CRS 
proj4string(chicago_shp) <- proj4string(cook.tracts)
library(raster)
chi_tracts <- intersect(cook.tracts, chi_shp)
detach("package:raster", unload=TRUE)  # masks select from dplyr

if (!dir.exists(chi_tracts_path)) {
  mkdir(chi_tracts_path)
  writeOGR(chi_tracts, chi_tracts_path, driver="ESRI Shapefile", layer='chi_tracts')
  # NOTE: warnings ok, see https://github.com/r-spatial/sf/issues/306
}

### Victim-Based Crime Reports ###

crimes <- read_csv(crimes_raw_url)

crimes$dateChr <- substr(crimes$Date, 1, 10)
crimes$date <- as.Date(crimes$dateChr, format="%m/%d/%Y")
crimes$month <- floor_date(crimes$date, "month")
crimes$week <- floor_date(crimes$date, "week")
crimes$year <- as.Date(paste0(crimes$Year, "-01-01"))

crimes$lat <- crimes$Latitude
crimes$lng <- crimes$Longitude

hnfs <- c("0110", "0130", "041A", "041B")  # First and Second degree homicide and Aggravated Battery with a handgun or other firearm
# NOTE: see codes: https://data.cityofchicago.org/Public-Safety/Chicago-Police-Department-Illinois-Uniform-Crime-R/c7ck-438e/data
# NOTE: does not include aggravated assault: threat/display of firearm (0450, 0451)
# NOTE: does not include aggravated battery against protected employee by firearm (0480, 0481)
# NOTE: does not include ritual mutilation by firearm (0490, 0491)
# NOTE: does not include weapons violation, unlawful use of firearm (0141A, 0141B)

crimes$hnfs <- ifelse(crimes$IUCR %in% hnfs, 1, 0)
crimes$narcotics <- ifelse(crimes$`FBI Code` == '18', 1, 0)

crimesClean <- crimes %>% filter(hnfs==1 | narcotics==1) %>% filter(!is.na(lat) & !is.na(lng) & lat > 40) %>% select(date, year, month, week, lat, lng, hnfs, narcotics)

write_csv(crimesClean, chi_clean_path)  # to data folder
write_csv(crimesClean, 'shiny/chi_clean.csv') # to shiny folder

### Shotspotter ###

# NOTE: not completely rolled out yet, biased coverage

ss <- read_csv(ss_raw_url, col_types = cols(day="c", month="c", year="c", yearmonth="c"))
ss <- ss %>% filter(day!="#VALUE!")
ss$day <- as.integer(ss$day)
ss$month <- as.integer(ss$month)
ss$year <- as.integer(ss$year)
ss$yearmonth <- as.integer(ss$yearmonth)

### GET CENSUS DATA ###

for (i in years) {

  # Obtaining the ACS Data begins with inputting the multi-use key
  api.key.install(key="9e14fb5cda17c74f8b723def3de2ada902631d4c")
  # Creating a Geographic Set for which to Grab Tabular Data from the ACS
  geo <- geo.make(state=c(17), county=c(31),tract = "*" ,block.group = "*")

  # Then Pulling Out the Median Household Income and Per Capita Income
  income <- acs.fetch(endyear = i, span = 5, geography = geo,
                      table.number = c("B19001"), col.names = "pretty")

  # income2011 <- acs.fetch(endyear = 2011, span = 5, geography = geo,
  #                         table.number = c("B19001"), col.names = "pretty")
  # income2016 <- acs.fetch(endyear = 2016, span = 5, geography = geo,
  #                         table.number = c("B19001"), col.names = "pretty")

  # Per capita income given by , "B19301"
  # What did we get? (It's a list, not a dataframe)
  # names(attributes(income))
  # attr(income, "acs.colnames")

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
                      table.number = c("B19301"), col.names = "pretty")

  income_df$capita <- as.numeric(capita@estimate)
  income_df$capita[income_df$capita < 0] <- 1  # use 1 so log still works

  income_df$ln_capita <- log(income_df$capita)

  # income_df$rounded <- as.numeric(round(income_df$capita, digits = -3))/1000

  income_df <- income_df %>% as_tibble()

  # export to data folder
  write_csv(income_df, paste0("data/income", i, "_clean.csv"))
  # export to shiny
  write_csv(income_df, paste0("shiny/income", i, "_clean.csv"))
}

