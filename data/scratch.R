library(tidyverse)

cook.blocks <-  block_groups("Illinois", county = "031", year = "2016")   #Cook County Block Groups

v <- read_csv("violence.csv")
v <- geo_join(cook.blocks, v, "GEOID", "GEOID")

hist(v$event.count)


popup <- paste0("GEOID: ", v$GEOID, "<br>", "Event Count: ", v$event.count)
pal <- colorNumeric(
  palette = "YlGnBu",
  domain = v$event.count)

map4 <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = v, 
              fillColor = ~pal(event.count), 
              color = "#b2aeae", # you need to use hex colors
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values =  v$event.count, 
            position = "bottomright", 
            title = "Violent Events in the dataset for all Block Groups") 

map4



# master$crimes <- NULL
# master$status <- "loading"

# delay(250, master$crimes <- read_csv('chi_clean.csv'))

# observeEvent(master$status, {
#   if(master$status == 'loading') {
#     output$status <- renderUI({helpText("Loading data...")})
#   }
#   else {
#     output$status <- renderUI({ })
#   }
# })

# observeEvent(master$crimes, {
#   if(!is.null(master$crimes)) {
#     print('hello')
#     master$status <- "complete"
#   }
# })