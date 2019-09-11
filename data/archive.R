


#########################################ENDS Here###################################################

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



###Testing Whether Census Tracts overlap
###Now obtain the census data
#Begin downloading all the available years of census shapefiles for the desired 
years <- seq(2007,2017) 
for (i in years) {
  container <- tracts(city[1], county = city[2], year = "2016") #toSstring replaces "2016" #command is from the tigris package
  container2 <- tracts(city[1],county = city[2],year = "2017")
}

#Testing whether the borders overlap or not
Results<-gIntersects(container,container2,byid=TRUE)
rownames(Results)<-container$GEOID
colnames(Results)<-container2$GEOID


###Mapping covariates etc###

CHY <- list()  # homicides and nfs by year
CNY <- list()  # narcotics by year

for (i in 1:length(unique(crimes$Year))) {
  year <- unique(crimes$Year)[i]
  crimesY <- crimes %>% filter(Year == year)
  summary(crimesY)
  
  unique(crimesY$`Primary Type`) %>% sort
  unique(crimesY$`IUCR`)
  
  
  
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

###Plotting Crime
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

# Lealet map of the census economic data
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