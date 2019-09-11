library(leaflet)
library(shinyWidgets)

shinyUI(
  navbarPage("DRUGS", id="drugs",
    tabPanel("Chicago", value="chicago",
      column(8,
        uiOutput("status"),
        leafletOutput("map")
      ),
      column(4,
        radioButtons("aggregation", "Aggregate by:", c("week", "month", "year")),
        sliderTextInput("time", "Time", choices = c(0), animate=T),
        radioButtons("crimeCat", "Crime Category", c("hnfs", "narcotics"))
      )
    )
  )
)

