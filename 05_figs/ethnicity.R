#Loading packages
library(acs)
library(tigris)

# Obtaining the ACS Data begins with inputting the multi-use key
api.key.install(key="9e14fb5cda17c74f8b723def3de2ada902631d4c")

#Selecting the relevant tracts
city.blocks <- tracts(17,county = 031, year = 2016)
geo <- geo.make(state=17, county=031,tract = "*")

# Creating a Geographic Set for which to Grab Tabular Data from the ACS
# Then Pulling A General Race Table that also includes population totals in each tract
race <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                    table.number = c("B02001"), col.names = "pretty")

# convert to a data.frame for merging
race_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                               str_pad(race@geography$county, 3, "left", pad="0"),
                               str_pad(race@geography$tract, 6, "left", pad="0")),
                        race@estimate,
                        stringsAsFactors = FALSE)
rownames(race_df)<-1:nrow(race_df)
names(race_df)<-c("GEOID", "total", "white" , "black", "american.indian", "asian",
                  "native.hawian","other", "two.or.more", "two.or.more.including.some.other",
                    "two.or.more.including.some.other.and.three.or.more")

#Pulling up black/african american table to get total identifying as black in a tract
black <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                   table.number = c("B02009"), col.names = "pretty")
black_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                                      str_pad(race@geography$county, 3, "left", pad="0"),
                                      str_pad(race@geography$tract, 6, "left", pad="0")),
                               black@estimate,
                               stringsAsFactors = FALSE)
rownames(black_df)<-1:nrow(black_df)
names(black_df)<-c("GEOID", "black")

#Pulling up hispanic table (not included in race table)
latino <- acs.fetch(endyear = 2016, span = 5, geography = geo,
                    table.number = c("B03003"), col.names = "pretty")
latino_df <- data.frame(paste0(str_pad(race@geography$state, 2, "left", pad="0"),
                              str_pad(race@geography$county, 3, "left", pad="0"),
                              str_pad(race@geography$tract, 6, "left", pad="0")),
                       latino@estimate,
                       stringsAsFactors = FALSE)
rownames(latino_df)<-1:nrow(latino_df)
names(latino_df)<-c("GEOID", "total","not.latino","latino")

ethnicity <- data.frame(race_df$GEOID, race_df$total, black_df$black, latino_df$latino)
names(ethnicity) <- c("GEOID", "total","black","latino")
ethnicity$percentage.black <- ethnicity$black/ethnicity$total
ethnicity$percentage.latino <- ethnicity$latino/ethnicity$total
