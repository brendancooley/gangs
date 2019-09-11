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


# cpdURL <- 'https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD'
# crimes <- read_csv(cpdURL)
# write_csv(crimes, 'chi_crimes.csv')

crimes <- read_csv('data/chi_crimes.csv')

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


  # Per capita income given by , "B19301"

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
  capita <- acs.fetch(endyear = i, span = 5, geography = geo,
                      table.number = c("B19301"), col.names = "pretty")

  income_df$capita <- as.numeric(capita@estimate)
  income_df$capita[income_df$capita <0] <- 0

  # income_df$rounded <- as.numeric(round(income_df$capita, digits = -3))/1000

  income_df <- income_df %>% as_tibble()

  # export to clean
  # write_csv(income_df, paste0("income", i, "_clean.csv"))  # this is done in 01_fetch.R
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


##Merging the crime and socio-economic data






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
