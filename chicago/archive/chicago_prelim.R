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
city <- 031 # First pick a city from the following, entering the number (Baltimore, Chicago (031), St. Louis) 
tract.type <- "Block Groups" # Second, pick the desired census unit from the following (Block Groups)
micro.length <- "week" # Third, pick the desired length of micro-period from the following ("day, week, month")


###Acquiring the raw crime data
raw.data <- function(city){
  if(city==031)
  {
    # cpdURL <- 'https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD'
    # crimes <- read_csv(cpdURL)
    # write_csv(crimes, 'chi_crimes.csv')
    
    crimes <- read_csv('chi_crimes.csv')
  }
  return(datas)
}

crimes <- raw.data(city)


CHY <- list()  # homicides and nfs by year
CNY <- list()  # narcotics by year

for (i in 1:length(unique(crimes$Year))) {
  year <- unique(crimes$Year)[i]
  crimesY <- crimes %>% filter(Year == year)
  summary(crimesY)
  
  unique(crimesY$`Primary Type`) %>% sort
  unique(crimesY$`IUCR`)
  
  # IUCR homicide and nonfatal shooting codes (last two are battery with gun)
  hnfs <- c("0110", "0130", "041A", "041B")
  
  hnfsY <- crimesY %>% filter(IUCR %in% hnfs)
  narcoticsY <- crimesY %>% filter(`FBI Code` == '18')
  
  colnames(hnfsY)[colnames(hnfsY) %in% c('Latitude', 'Longitude')] <- c('lat', 'lng')
  hnfsY <- hnfsY %>% filter(!is.na(lat) & !is.na(lng) & lat > 40)  # filter ungeotagged and nonsensical events
  
  colnames(narcoticsY)[colnames(narcoticsY) %in% c('Latitude', 'Longitude')] <- c('lat', 'lng')
  narcoticsY <- narcoticsY %>% filter(!is.na(lat) & !is.na(lng) & lat > 40)
  
  CHY[[i]] <- hnfsY
  CNY[[i]] <- narcoticsY
}

CHYmaps <- list()
CNYmaps <- list()

for (i in 1:length(unique(crimes$Year))) {
  chy <- CHY[[i]]
  cny <- CNY[[i]]
  
  chymap <- leaflet(chy) %>% addTiles() %>% addProviderTiles(providers$CartoDB.Positron) %>%
    addHeatmap(radius=5, blur=10)
  cnymap <- leaflet(cny) %>% addTiles() %>% addProviderTiles(providers$CartoDB.Positron) %>%
    addHeatmap(radius=5, blur = 10)
  
  CHYmaps[[i]] <- chymap
  CNYmaps[[i]] <- cnymap
}

length(CHYmaps)

sync(CHYmaps[seq(15,18)])

sync(CNYmaps[seq(1,4)])


### TIME SERIES VARIATION ###

crimes$dateChr <- substr(crimes$Date, 1, 10)
crimes$date <- as.Date(crimes$dateChr, format="%m/%d/%Y")
crimes %>% select(date)

hnfs <- c("0110", "0130", "041A", "041B")
crimes$hnfs <- ifelse(crimes$IUCR %in% hnfs, 1, 0)
crimes$narcotics <- ifelse(crimes$`FBI Code` == '18', 1, 0)


crimesM <- crimes %>% group_by(month=floor_date(date, "month")) %>%
  summarise(hnfs=sum(hnfs),
            narcotics=sum(narcotics))
months <- crimesM %>% pull(month)
jan <- months[crimesM %>% pull(month) %>% months() == "January"]


ggplot(crimesM, aes(x=month, y=hnfs)) +
  geom_line() +
  geom_line(aes(y=narcotics)) +
  geom_vline(xintercept = jan, lty=2) +
  theme_classic()

Y <- 2005
crimesWY <- crimes %>% filter(Year==Y) %>% group_by(week=floor_date(date, "week")) %>%
  summarise(hnfs=sum(hnfs), 
            narcotics=sum(narcotics))
date.start.month=seq(as.Date(paste0(Y, "-01-01")), length=12, by="months")

ggplot(crimesWY, aes(x=week, y=hnfs)) +
  geom_line() +
  # geom_line(aes(y=narcotics)) +
  geom_vline(xintercept=date.start.month, lty=2) +
  theme_classic()
# seem to spike at the end of each months, precincts looking to get numbers? Might be useful for identification...


### NOAM CENSUS DATA ###

years <- c(2009, 2016)

for (i in years) {
  
  # Reading in Census Tract Boundaries
  cook.blocks <-  block_groups("Illinois", county = "031", year = "2016")   #Cook County Block Groups
  
  # Obtaining the ACS Data begins with inputting the multi-use key
  api.key.install(key="9e14fb5cda17c74f8b723def3de2ada902631d4c")
  # Creating a Geographic Set for which to Grab Tabular Data from the ACS
  geo <- geo.make(state=c(17), county=c(31),tract = "*" ,block.group = "*")
  
  # Then Pulling Out the Median Household Income and Per Capita Income
  income <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                      table.number = c("B19001"), col.names = "pretty")
  
  # income2011 <- acs.fetch(endyear = 2011, span = 5, geography = geo,
  #                         table.number = c("B19001"), col.names = "pretty")
  # income2016 <- acs.fetch(endyear = 2016, span = 5, geography = geo,
  #                         table.number = c("B19001"), col.names = "pretty")
  
  
  # What did we get? (It's a list, not a dataframe)
  
  names(attributes(income))
  
  attr(income, "acs.colnames")
  
  # Converting the Data to a Dataframe for Merging
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
  
  # income_df$rounded <- as.numeric(round(income_df$capita, digits = -3))/1000

  income_df <- income_df %>% as_tibble()
  
  # export to clean 
  write_csv(income_df, paste0("income", i, "_clean.csv"))
}

# Next merge the geographic boundaries dataset with the ACS data
income_merged <- geo_join(cook.blocks, income_df, "GEOID", "GEOID")
# There are some tracts with no land that we should exclude
income_merged <- income_merged[income_merged$ALAND>0, ]

# Next, making the map using leaflet
popup <- paste0("GEOID: ", income_merged$GEOID, "<br>", "Per Capita Income: ", income_merged$capita)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = income_merged$capita)

map3 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = income_merged, 
              fillColor = ~pal(capita), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = income_merged$capita, 
            position = "bottomright", 
            title = "Per Capita Income in 2016") 
 
map3


###Merging the crime and socio-economic data###
#Reduce crime size (copy paste of code above)
hnfs <- c("0110", "0130", "041A", "041B")
hnfs.data <- crimes %>% filter(IUCR %in% hnfs)
colnames(hnfs.data)[colnames(hnfs.data) %in% c('Latitude', 'Longitude')] <- c('lat', 'lng')
hnfs.data <- hnfs.data %>% filter(!is.na(lat) & !is.na(lng) & lat > 40)  # filter ungeotagged and nonsensical events

#The CRS of the income data
proj4string(income_merged)

#First transforming crime into spatial data
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

#Find the earliest date in the data and the latest
crime_income_merged$just.date <- crime_income_merged$Date
#Remove AM, PM strings, then hours, minutes, seconds
crime_income_merged$just.date <- gsub(x=crime_income_merged$just.date,pattern=" PM",replacement="",fixed=T)
crime_income_merged$just.date <- gsub(x=crime_income_merged$just.date,pattern=" AM",replacement="",fixed=T)
crime_income_merged$just.date <- format(as.POSIXct(crime_income_merged$just.date,format='%m/%d/%Y %H:%M:%S'),
                                        format='%m/%d/%Y')
crime_income_merged$just.date <- as.Date(crime_income_merged$just.date, format="%m/%d/%Y")

#Now to actually find the earliest date
min(crime_income_merged$just.date)
max(crime_income_merged$just.date)

dates <- seq(as.Date("2001-01-01"), as.Date("2018-09-09"), by="days")

#Now, to make the data
for(i in 1:length(dates)){
  day <- dates[i]
  container <- vector()
  for(j in 1:length(total)){
    container[j] <- sum(crime_income_merged$just.date == day & crime_income_merged$GEOID == total[j])
  }
  violence$container <- container
  names(violence)[names(violence) == "container"] <- paste(day)
  print(i)
}

#Add the income variables back to data
violence <- full_join(income_df, violence, by = "GEOID")
violence$event.count[is.na(violence$event.count)] <- 0 
violence[, 21:3993][is.na(violence2[, 21:3993])] <- 0
write.csv(violence, file = "violence.csv")

#Creating a dataset of week long micro-periods for each year

for(i in i:17)
{
  first.day <- ifelse(i==1,21,ifelse((i-1)%%4==0,first.day+366,first.day+365)) #determine first day of the year
  last.day <- ifelse(i%%4==0,first.day+366,first.day+365) #determine last day of the year
  year.marker <- ifelse(i<10, paste("200",i),paste("20",i)) #what number year
  place.holder <- violence2[,c(1:20,first.day:last.day)] #relevant variables from the original data
  construction <- violence2[,c(1:20)]
  for(j in 1:52)
  {
    first.week <- (i-1)*7+21
    for(k in first.week:last.week)
    {
      oneday <- place.holder[,first.day]
      twoday <- place.holder[,first.day+1]
      threeday <- place.holder[,first.day+2]
      fourday <- place.holder[,first.day+3]
      fiveday <- place.holder[,first.day+4]
      sixday <- place.holder[,first.day+5]
      sevenday <- place.holder[,first.day+6]
    }
    construction$week <- oneday +twoday +threeday +fourday +fiveday + sixday + sevenday
    if(week==52)
    {
      eightday <- place.holder[,first.day+7]
      nineday <- ifelse(i%%4==0,place.holder[,first.day+8],rep(0,nrow(eightday)))
      construction$week <- construction$week + eightday +nineday
    }
    names(construction)[names(construction) == "week"] <- paste("week",j)
  }
  
}





##Plotting the violence
violence <- geo_join(cook.blocks, violence, "GEOID", "GEOID")

##Saving the data


# Next, making the map using leaflet
popup <- paste0("GEOID: ", violence$GEOID, "<br>", "Event Count: ", violence$event.count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = violence$event.count)

map4 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = violence, 
              fillColor = ~pal(event.count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = violence$event.count, 
            position = "bottomright", 
            title = "Violent Events in the dataset for all Block Groups") 

map4



#Now to determione adjacency by creating a list of neighbors for each polygon
adjacency <- poly2nb(income_merged, row.names = income_merged$GEOID, queen = T)

##Now to create distance measures (Returns bizarre measurements, unclear why)
#Centroid Cooridnates
centers <- gCentroid(income_merged, byid = T)
centers <- spTransform(centers, CRS("+init=epsg:2062")) 
centroid.distance <- gDistance(centers, byid = T)

#Alternatively to create an adjacency matrix use the following command >> gTouches(income_merged, byid=T)


# Next Steps

# 1) Get census and overlay neighborhood population and demographic characteristics
# 2) overlay police pressence by neighborhood

  # registerPlugin(heatPlugin) %>%
  # onRender("function(el, x, data) {
  #          data = HTMLWidgets.dataframeToD3(data);
  #          data = data.map(function(val) { return [val.lat, val.long, val.mag*100]; });
  #          L.heatLayer(data, {radius: 25}).addTo(this);
  #          }", data = hnfs2017 %>% select(lat, lng))


# heatPlugin <- htmlDependency("Leaflet.heat", "99.99.99",
#                              src = c(href = "http://leaflet.github.io/Leaflet.heat/dist/"),
#                              script = "leaflet-heat.js")
# 
# registerPlugin <- function(map, plugin) {
#   map$dependencies <- c(map$dependencies, list(plugin))
#   map
# }