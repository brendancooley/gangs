library(tidyverse)
library(lubridate)
library(acs)
library(tigris)

### Crimes ###

crimes <- read_csv('chi_crimes.csv') 

crimes$dateChr <- substr(crimes$Date, 1, 10)
crimes$date <- as.Date(crimes$dateChr, format="%m/%d/%Y")
crimes$month <- floor_date(crimes$date, "month")
crimes$week <- floor_date(crimes$date, "week")
crimes$year <- as.Date(paste0(crimes$Year, "-01-01"))

crimes$lat <- crimes$Latitude
crimes$lng <- crimes$Longitude

hnfs <- c("0110", "0130", "041A", "041B")
crimes$hnfs <- ifelse(crimes$IUCR %in% hnfs, 1, 0)
crimes$narcotics <- ifelse(crimes$`FBI Code` == '18', 1, 0)

crimesClean <- crimes %>% filter(hnfs==1 | narcotics==1) %>% filter(!is.na(lat) & !is.na(lng) & lat > 40) %>% select(date, year, month, week, lat, lng, hnfs, narcotics)
write_csv(crimesClean, 'chi_clean.csv')

### Census ###


years <- c(2009, 2016)

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
  income_df$capita[income_df$capita < 0] <- 1  # use 1 so log still works
  
  income_df$ln_capita <- log(income_df$capita)
  
  # income_df$rounded <- as.numeric(round(income_df$capita, digits = -3))/1000
  
  income_df <- income_df %>% as_tibble()
  
  # export to clean 
  write_csv(income_df, paste0("income", i, "_clean.csv"))
}
