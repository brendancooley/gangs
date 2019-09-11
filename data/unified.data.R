### TODOs ###

# shot spotter data?

### SETUP ### 

library(readr)
library(tidyverse)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(mapview)
library(tigris)
library(acs)
library(stringr)
library(sf)
library(sp)
library(rgeos)
library(rgdal)
library (maptools)
library(spdep)


###Start Here###
city <- c(17,031) # First pick a city from the following, entering the number of the fips code
               #(Baltimore (24,510), Chicago (17,031), St. Louis (29,510)) 
tract.type <- "Tracts" # Second, pick the desired census unit from the following (Tracts, Block Groups)
micro.length <- 7 # Third, pick the desired length of micro-period from the following (e.g. 7,14,30)


### Checking the tract data
# tract.type <- "Tracts"
# test.data <- combined.data(city,tract.type)

###Acquiring the Crime Data###
#Start by acquring the raw crime data
raw.data <- function(city){
  if(city[2]==31)
  {
    # cpdURL <- 'https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD'
    # crimes <- read_csv(cpdURL)
    # write_csv(crimes, 'chi_crimes.csv')
    
    datas <- read_csv('chi_crimes.csv')
  }
  return(datas)
}

#Then reduce it to homicides and non-fatal shootings
crime.data <- function(city){
  # IUCR homicide and nonfatal shooting codes (last two are battery with gun)
  hnfs <- c("0110", "0130", "041A", "041B")
  crimes <- raw.data(city)
  hnfs.data <- crimes %>% filter(IUCR %in% hnfs)
  colnames(hnfs.data)[colnames(hnfs.data) %in% c('Latitude', 'Longitude')] <- c('lat', 'lng')
  if(city[2] == 31){
    hnfs.data <- hnfs.data %>% filter(!is.na(lat) & !is.na(lng) & lat > 40)  # filter ungeotagged and nonsensical events  
  }
  else{
    hnfs.data <- hnfs.data %>% filter(!is.na(lat) & !is.na(lng))  # filter ungeotagged and nonsensical events 
  }
}

### Combining with Census Data ###
census.data <- function(city,tract.type){
  # Obtaining the ACS Data begins with inputting the multi-use key
  api.key.install(key="9e14fb5cda17c74f8b723def3de2ada902631d4c")
  y <- "2016"
  # Then Reading in Census Tract Boundaries and Data, According to the Desired City and Tract type
  if(tract.type=="Block Groups"){
    city.blocks <- block_groups(city[1], county = city[2], year = y)
    geo <- geo.make(state=c(city[1]), county=c(city[2]),tract = "*" ,block.group = "*")
  }else{
    city.blocks <- tracts(city[1],county = city[2], year = y)
    geo <- geo.make(state=c(city[1]), county=c(city[2]),tract = "*")
  }
  # Creating a Geographic Set for which to Grab Tabular Data from the ACS
  # Then Pulling Out the Median Household Income and Per Capita Income
  income <- acs.fetch(endyear = y, span = 5, geography = geo,
                      table.number = c("B19001"), col.names = "pretty")
  # What did we get? (It's a list, not a dataframe)
  #names(attributes(income))
  # convert to a data.frame for merging
  income_df <- data.frame(paste0(str_pad(income@geography$state, 2, "left", pad="0"), 
                                 str_pad(income@geography$county, 3, "left", pad="0"), 
                                 str_pad(income@geography$tract, 6, "left", pad="0"),
                                 str_pad(income@geography$blockgroup, 1, "left", pad="0")),
                          income@estimate,
                          stringsAsFactors = FALSE)
  
  rownames(income_df)<-1:nrow(income_df)
  names(income_df)<-c("GEOID", "total", "less_10" , "between_10-15", "between_15-20", "between20-25", 
                      "between_25-30", "between_30-35", "between_35-40", "between_40-45",
                      "between_45-50", "between_50-60", "between_60-75", "between_75-100",
                      "between_100-125", "between_125-150", "between_150-200" ,"over_200")
  
  # Next recall the per-capita income data
  capita <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                      table.number = c("B19301"), col.names = "pretty")
  
  income_df$capita <- as.numeric(capita@estimate)
  income_df$capita[income_df$capita <0] <- 0
  income_df <- income_df %>% as_tibble()
  
  # Next merge the geographic boundaries dataset with the ACS data
  income_merged <- geo_join(city.blocks, income_df, "GEOID", "GEOID")
  # There are some tracts with no land that we should exclude
  income_merged <- income_merged[income_merged$ALAND>0, ]
  return(income_merged)
}

###Function combining the census and crime data
combined.data <- function(city, tract.type) {
  income_merged <- census.data(city,tract.type)
  hnfs.data <- crime.data(city)
  #First transforming crime into spatial data that matches the CRS of the income merged data
  coordinates(hnfs.data) <- ~lng+lat
  proj4string(hnfs.data) <- proj4string(income_merged)
  
  #Mapping crime events to districts
  crime_income_merged <- over(hnfs.data, income_merged)
  crime_income_merged <- spCbind(hnfs.data, crime_income_merged)
  
  #So how many violent events total per district?
  total <- unique(crime_income_merged$GEOID)
  district <- vector()
  count <- vector()
  
  for (i in 1:length(total)) {
    district[i] <- total[i]
    count[i] <- sum(crime_income_merged$GEOID==district[i])
  }
  #Cool, now lets make the dataset, each row is a district, each column a daily count
  violence <- data.frame(district)
  colnames(violence)[colnames(violence)=="district"] <- "GEOID"
  violence$event.count <- count
  
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
}

final.data <-function(city,tract.type,micro.length){
  #call up the required data
  violence <- combined.data(city, tract.type)
  #first figure out start and endyear for data
  first.year<- as.numeric(substring(names(violence[22]),1,4))
  last.year <- as.numeric(substring(names(violence[ncol(violence)]),1,4))-1
  construction <- violence[,c(1:21)] #the new dataset being constructed
  for(i in first.year:last.year)
  {
    first.day <- ifelse(i==first.year,22,ifelse((i-1)%%4==0,first.day+367,first.day+366)) #determine first day of the year (column)
    last.day <- ifelse(i%%4==0,first.day+366,first.day+365) #determine last day of the year (column)
    iterations <- 365%/%micro.length #number of internal loops to run
    for(j in 1:iterations)
    {
      currentmarker <- ifelse(j==1,first.day,currentmarker+micro.length)#first column to be dealt with
      to.be.added <- ifelse(j!=iterations,colnames(violence[c(currentmarker:(currentmarker+micro.length-1))]),
                            colnames(violence[c(currentmarker:last.day)])) #takes one micro-length worth of days to aggregate
      construction$place.holder <- rowSums(violence[to.be.added]) #aggregation step
      names(construction)[names(construction) == "place.holder"] <- paste(i,".",j,sep = "") #rename variable
    }
  }
  return(construction)
}



  
