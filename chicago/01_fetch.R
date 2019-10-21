### SETUP ###

if (!'chicago' %in% strsplit(getwd(), "/")[[1]]) {
  setwd('chicago')
}
# getwd()

helperPath <- "../source/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

libs <- c("tidyverse", "lubridate", "acs", "tigris")
ipak(libs)

crimes_raw_url <- "https://www.dropbox.com/s/h7da81i9qt876tf/chi_crimes.csv?dl=1"
ss_raw_url <- "https://www.dropbox.com/s/3qfruwbsg1t7g23/shotspotter.csv?dl=1"

years <- c(2009, 2016)  # years for which to get census data
aggregation <- "week"

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

write_csv(crimesClean, 'data/chi_clean.csv')  # to data folder
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

  # Reading in Census Tract Boundaries
  cook.blocks <-  block_groups("Illinois", county = "031", year = "2016")   #Cook County Block Groups

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

### MAP SHOOTINGS TO CENSUS BLOCKS ###

chi_shots <- crimesClean %>% filter(hnfs==1)
# nrow(chi_shots)  # ~46,000 hnfs

# income_merged <- geo_join(cook.blocks, income_df, "GEOID", "GEOID")

# transform crime into spatial data that matches the CRS of the income merged data
coordinates(chi_shots) <- ~lng+lat
proj4string(chi_shots) <- proj4string(cook.blocks)

# Mapping crime events to districts
chi_shots_geoids <- over(chi_shots, cook.blocks) %>% as_tibble()
chi_shots$GEOID <- chi_shots_geoids$GEOID  # append geoids to chi_shots

# summarize counts
chi_shots_agg <- chi_shots %>% as_tibble() %>% group_by_("GEOID", aggregation) %>%
  summarise(hnfs=n())
chi_shots_agg %>% summary()

# cook_shots <- geo_join(cook.blocks, chi_shots_agg, "GEOID", "GEOID")

Chicago <- readOGR(".","Chicago")
Chicago <- spTransform(Chicago, proj4string(cook.blocks))  # match CRS 
# proj4string(Chicago)
# proj4string(cook_shots)
chi_blocks <- intersect(cook.blocks, Chicago)

GEOID <- chi_blocks$GEOID
unit <- chi_shots[[aggregation]] %>% unique() %>% sort()
chi_blank <- crossing(GEOID, unit)
colnames(chi_blank)[colnames(chi_blank)=="unit"] <- aggregation
chi_blank$hnfs <- 0

anti_join(chi_shots_agg, chi_blank)

# chi_shots$dummy <- 1
# proj4string(Chicago) <- proj4string(cook_shots)  #Changing the CRS to match
popup <- paste0("GEOID: ", chi_shots$GEOID, "<br>", "Violence Present", chi_shots$hnfs)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = chi_shots$hnfs)

mapChicago2 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = chi_shots, 
              fillColor = ~pal(hnfs), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup)
mapChicago2
# clearly some districts are being double counted






# calculate number of violent events total per district?
total <- unique(chi_shots_geoids$GEOID)
district <- vector()
count <- vector()

for (i in 1:length(total)) {
  district[i] <- total[i]
  count[i] <- sum(chi_shots_geoids$GEOID==district[i])
}
# length(unique(chi_shots_geoids$GEOID)) # 1905 districts with a shooting


# convert to data frame, each row is a district, each column a daily count
violence <- data.frame(district)
colnames(violence)[colnames(violence)=="district"] <- "GEOID"
violence$shootings <- count
violence %>% summary()

write_csv(violence, "output/tracts_shootings.csv")

##This bit is likely CHICAGO SPECIFIC
#Find the earliest date in the data and the latest
crime_income_merged$just.date <- crime_income_merged$Date
#Remove AM, PM strings, then hours, minutes, seconds
crime_income_merged$just.date <- gsub(x=crime_income_merged$just.date,pattern=" PM",replacement="",fixed=T)
crime_income_merged$just.date <- gsub(x=crime_income_merged$just.date,pattern=" AM",replacement="",fixed=T)
crime_income_merged$just.date <- format(as.POSIXct(crime_income_merged$just.date,format='%m/%d/%Y %H:%M:%S'),
                                        format='%m/%d/%Y')
crime_income_merged$just.date <- as.Date(crime_income_merged$just.date, format="%m/%d/%Y")

#Now to actually find the earliest date
dates <- seq(min(crime_income_merged$just.date), max(crime_income_merged$just.date), by="days")

#Now, to make the data
for(i in 1:length(dates)){
  day <- dates[i]
  container <- vector()
  for(j in 1:length(total)){
    container[j] <- sum(crime_income_merged$just.date == day & crime_income_merged$GEOID == total[j])
  }
  violence$container <- container
  names(violence)[names(violence) == "container"] <- paste(day)
}

#Add the income variables back to data (CHICAGO SPECIFIC)
violence <- full_join(income_df, violence, by = "GEOID")
violence$event.count[is.na(violence$event.count)] <- 0
violence[, 21:ncol(violence)][is.na(violence[, 21:ncol(violence)])] <- 0
return(violence)
