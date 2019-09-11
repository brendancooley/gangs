### TODO ###

# get population data layer

### SETUP ###


# libs <- c("readr", "dplyr", "leaflet", "shiny", "shinyjs", "shinyWidgets", "leaflet.extras")
# sapply(libs, library, character.only = TRUE)
library(tidyverse)
library(leaflet)
library(shiny)
library(shinyjs)
library(shinyWidgets)
library(leaflet.extras)
library(acs)
library(tigris)


crimes <- read_csv("chi_clean.csv") 

cook.blocks <-  block_groups("Illinois", county = "031", year = "2016")   #Cook County Block Groups

income2009 <- read_csv("income2016_clean.csv") %>% filter(capita > 1000)  # drop super low incomes
income2016 <- read_csv("income2016_clean.csv") %>% filter(capita > 1000)
summary(income2009)

# Next merge the geographic boundaries dataset with the ACS data
income_merged2009 <- geo_join(cook.blocks, income2009, "GEOID", "GEOID")
income_merged2016 <- geo_join(cook.blocks, income2016, "GEOID", "GEOID")

# There are some tracts with no land that we should exclude
income_merged2009 <- income_merged2009[income_merged2009$ALAND>0, ]
income_merged2016 <- income_merged2016[income_merged2016$ALAND>0, ]


shinyServer(function(session, input, output) {
  
  master <- reactiveValues()
  master$crimesT <- crimes %>% filter(year==as.Date("1900-01-01"))

  observeEvent(input$aggregation, {
    
    if(input$aggregation=="week") {
      tVal <- crimes$week
    }
    if(input$aggregation=="month") {
      tVal <- crimes$month
    }
    if(input$aggregation=="year") {
      tVal <- crimes$year
    }
    
    tValS <- sort(unique(tVal))
    updateSliderTextInput(session, "time", choices=tValS)
    
  })
  
  observeEvent(c(input$time, input$crimeCat), {
    
    if (input$time != 0) {
      
      t <- input$time
      print(t)
      
      # income
      if (t > as.Date("2012-06-01")) {
        income <- income_merged2016
      }
      else {
        income <- income_merged2009
      }
      
      popup <- paste0("GEOID: ", income$GEOID, "<br>", "Per Capita Income: ", income$ln_capita)
      pal <- colorNumeric(
        palette = "YlGnBu",
        domain = income$ln_capita)
      
      leafletProxy("map") %>% clearShapes() %>%
        addPolygons(data = income, 
                    fillColor = ~pal(ln_capita), 
                    color = "#b2aeae", # you need to use hex colors
                    fillOpacity = 0.7, 
                    weight = 1, 
                    smoothFactor = 0.2
        )
                    # popup = popup
        #             ) %>%
        # addLegend(pal = pal,
        #           values = income$ln_capita,
        #           position = "bottomright",
        #           title = "Per Capita Income in 2016")
      
      # crimes
      h <- ifelse(input$crimeCat=="hnfs", 1, 0)
      n <- ifelse(input$crimeCat=="narcotics", 1, 0)
      
      if(input$aggregation=="week") {
        master$crimesT <- crimes %>% filter(week==t, narcotics==n, hnfs==h)
      }
      if(input$aggregation=="month") {
        master$crimesT <- crimes %>% filter(month==t, narcotics==n, hnfs==h)
      }
      if(input$aggregation=="year") {
        master$crimesT <- crimes %>% filter(year==t, narcotics==n, hnfs==h)
      }
      
      lng <- master$crimesT %>% pull(lng)
      lat <- master$crimesT %>% pull(lat)
      leafletProxy("map") %>% clearHeatmap() %>% addHeatmap(lng=lng, lat=lat, radius=5, blur=10, gradient="YlOrRd")
      
      
    }
    
  })
  
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% addProviderTiles(providers$CartoDB.Positron) %>%
      fitBounds(min(crimes$lng), min(crimes$lat), max(crimes$lng), max(crimes$lat))
  })
  
})