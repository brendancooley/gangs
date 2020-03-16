# DOCUMENTATION -----------------------------------------------------------
#   Author:     Jesse Bruhn
#   Contact:    jessebr@bu.edu
#   Updated:    8/14/19 
#   Project:    The Geography of Gang Violence
#   Purpose:    Clean Gang Maps

# PREAMBLE ----------------------------------------------------------------

#print date
Sys.Date()

#Clear workspace
rm(list=ls())

#load packages
pckgs <- c("tidyverse", "sf")
lapply(pckgs, library, character.only=TRUE)

#Set Options
options(scipen=100)

#Clean Workspace
rm(pckgs)

#Session Info for Reproducibility
sessionInfo()

# NOTES -------------------------------------------------------------------

#Chicago PD informed me there was no change between 2012 and 2013, hence
#the did not provide me with a 2013 map. I reflect this in the data
#by replicating the 2012 map in 2013


# CREATE USEFUL FUNCTIONS -------------------------------------------------

#function to load gang maps
gangReader <- function(file, yr, dt=NULL){
  
  dat <- read_sf(file)
  
  dat <- dat %>%
    mutate(year = yr) %>%
    select(year, 
           contains("gang"), 
           contains("area"),
           contains("len")
    )
  
  names(dat)[1:4] <- c("year", "gang", "area", "length")
  
  if(yr!=2017){
    dat <- rbind(dat, dt)
  }
  
  return(dat)
}

# LOAD DEPENDENCIES -------------------------------------------------------

#load gang maps
# setwd("~/Desktop/gangs/chicago/Bruhn Data")
gang.maps <- gangReader("raw_maps/gangs2017.shp", 2017) 
gang.maps <- gangReader("raw_maps/gangs2016.shp", 2016, gang.maps) 
gang.maps <- gangReader("raw_maps/gangs2015.shp", 2015, gang.maps) 
gang.maps <- gangReader("raw_maps/gangs2014.shp", 2014, gang.maps) 
gang.maps <- gangReader("raw_maps/gangs2012.shp", 2012, gang.maps)   
gang.maps <- gangReader("raw_maps/gangs2011.shp", 2011, gang.maps)  
gang.maps <- gangReader("raw_maps/gangs2010.shp", 2010, gang.maps)
gang.maps <- gangReader("raw_maps/gangs2009.shp", 2009, gang.maps) 
gang.maps <- gangReader("raw_maps/gang2008.shp", 2008, gang.maps)
gang.maps <- gangReader("raw_maps/gangs2007.shp", 2007, gang.maps)
gang.maps <- gangReader("raw_maps/gangs2006.shp", 2006, gang.maps)
gang.maps <- gangReader("raw_maps/gangs2005.shp", 2005, gang.maps)
gang.maps <- gangReader("raw_maps/gangs2004.shp", 2004, gang.maps)


# CLEAN DATA --------------------------------------------------------------

library(tigris)
library(rgdal)
library(sp)

city.blocks <- block_groups(17, county = 31, year = 2016)  ###Same CRS regardless of the 

#Now lets try again
gang.maps <- st_transform(gang.maps, crs=proj4string(city.blocks))

#Make gang names look nice
stringFixer <- function(x){
  return(tolower(trimws(x)))
}

gang.maps <- gang.maps %>%
  mutate(gang = stringFixer(gang))

#Fix name inconsistencies. 
#NOTE: I assume all gangs that appear in the same year are distinct organizations.  
#      Otherwise, I use my judgement to adjucate year-by-year inconsistencies in 
#      name spellings of gangs
gang.maps <- gang.maps %>% 
  mutate(gang = if_else(gang=="ylo cobras", "young latin organization cobras", gang), 
         gang = if_else(gang=="ylo disciples", "young latin organization disciples", gang),
         gang = if_else(gang=="young latin organization disciple", "young latin organization disciples", gang),
         gang = if_else(gang=="two six", "two-six", gang), 
         gang = if_else(gang=="krazy get down boys", "krazy getdown boys", gang),
         gang = if_else(gang=="black p stone", "black p stones", gang),
         gang = if_else(gang=="12th st players", "12th street players", gang))

#drop area and length variables
#NOTE: I think they are wrong, so I'm going to calculate them manually later
#      if it turns out I need them. 
gang.maps <- gang.maps %>%
  select(-area, -length)

#Take gangs with territory name "NA" missing out of the dataset.   
missing.name.territory <- gang.maps %>% filter(is.na(gang))
gang.maps <- gang.maps %>% filter(!is.na(gang))

#NOTE: There are a number of observations listed as things like "mix unknown 
#      and traveling vice lords. I take this to mean both gangs occupy the area 
#      and add the territory to both gangs polygons.

#Create function to fix territorial boundary problems
boundaryFixer <- function(dt, problem.name, seperate.names){
  problem.years <- dt %>%
    filter(gang==problem.name) %>%
    .$year
  
  for (p.year in problem.years){
    print(p.year)
    for (s.name in seperate.names){
      print(s.name)
      joint.territory <- dt %>%
        filter(year==p.year & gang==problem.name) 
      
      individual.territory <- dt %>%
        filter(year==p.year & gang==s.name) 
      
      total.territory <- st_union(rbind(joint.territory, individual.territory)$geometry) %>%
        st_sf() %>%
        mutate(year = p.year, 
               gang = s.name) %>%
        select(year, gang, geometry)
      
      dt <- dt %>%
        filter(!(gang==s.name & year==p.year)) %>%
        rbind(total.territory)
    }
  }
  return(dt %>% filter(gang != problem.name)) 
}


#fix "black p stone & mickey cobras"
problem.name <- "black p stone & mickey cobras"
seperate.names <- c("black p stones", "mickey cobras")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "mickey cobras & cvl & black p stone"
problem.name <- "mickey cobras & cvl & black p stone"
seperate.names <- c("black p stones", "mickey cobras", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "black p stones mickey cobras cvl"
problem.name <- "black p stones mickey cobras cvl"
seperate.names <- c("black p stones", "mickey cobras", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "mix unknown & traveling vice lords"
problem.name <- "mix unknown & traveling vice lords"
seperate.names <- c("unknown vice lords", "traveling vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "4ch bps cvl"
problem.name <- "4ch bps cvl"
seperate.names <- c("four corner hustlers", "black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "four corner hustlers & black p stones"
problem.name <- "four corner hustlers & black p stones"
seperate.names <- c("four corner hustlers", "black p stones")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "gangster disciples & black disciples"
problem.name <- "gangster disciples & black disciples"
seperate.names <- c("gangster disciples", "black disciples")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bd gd imperial vice lords"
problem.name <- "bd gd imperial vice lords"
seperate.names <- c("gangster disciples", "black disciples", "imperial insane vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bd bps cvl"
problem.name <- "bd bps cvl"
seperate.names <- c("black disciples", "black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#fix "bps cvl"
problem.name <- "bps cvl"
seperate.names <- c("black p stones", "conservative vice lords")
gang.maps <- boundaryFixer(gang.maps, problem.name, seperate.names)

#Add in 2013 gang map
#NOTE: Chicago PD informed me there was no change between 2012 and 2013, hence
#       the did not provide me with a 2013 map. I reflect this information here
#       by replicating the 2012 map in 2013
gang.maps <- gang.maps %>%
  filter(year==2012) %>%
  mutate(year=2013) %>%
  rbind(gang.maps) %>%
  arrange(gang, year) %>%
  as_tibble() %>%
  st_sf()

# OUTPUT TARGETS ----------------------------------------------------------

#save gang maps
save(gang.maps, file="gangMaps.rda")
# gang.maps$gang %>% unique()

#MAKING SURE GANGS DON'T OVERLAP
library(tidyverse)
library(tigris)
library(sp)
library(raster)

gang.maps <- as(gang.maps, 'Spatial') #Transform to an SP object too
city.blocks <- tracts(17, county = 031, year = 2016) #FOR TRACTS
gang.maps <- spTransform(gang.maps, proj4string(city.blocks)) #projecting the gang maps


#A loop will go through checking whether gangs overlap for every given year
gang.names <- unique(gang.maps$gang) 
gangs1 <- vector()
gangs2 <- vector()
overlap1 <- vector()
overlap2 <- vector()
years <- vector()

for (m in 2004:2017) { #Loop Over Years
  
  gang_maps_y <- gang.maps[gang.maps$year==m,]
  overlap_y <- matrix(NA, nrow=length(gang.names), ncol=length(gang.names)) 
  print(paste0("year: ", m))
  
  for (i in 1:length(gang.names)) { #Big Loop Selecting A Single Gang
    print(paste0("gang: ", gang.names[i]))
    gang_maps_yi <- gang_maps_y[gang_maps_y$gang==gang.names[i],]
    if (nrow(gang_maps_yi) != 0) { #Does that gang hold territory in that year
      gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = "+proj=moll")
      gang_maps_yi <- gBuffer(gang_maps_yi, byid = T, width = -1)
      gang_maps_yi <- spTransform(gang_maps_yi, CRSobj = proj4string(city.blocks))
      for (j in 1:length(gang.names)) { #If so run an inner loop on all the gangs
        gang_maps_xi <- gang_maps_y[gang_maps_y$gang==gang.names[j],]
        if(nrow(gang_maps_xi) != 0){ #Does the inner llop gang hold territory
        gang_maps_xi <- spTransform(gang_maps_xi, CRSobj = "+proj=moll")
        gang_maps_xi <- gBuffer(gang_maps_xi, byid = T, width = -1)
        gang_maps_xi <- spTransform(gang_maps_xi, CRSobj = proj4string(city.blocks))
        if(gIntersects(gang_maps_yi, gang_maps_xi)){ #Do those two gangs intersect
          intersection_yij <- gIntersection(gang_maps_yi, gang_maps_xi)
          overlap_y[i,j] <- area(intersection_yij)/area(gang_maps_xi)
        }
        else { #If the gangs do not intersect
          overlap_y[i,j] <- 0
        }
        } #End if inner loop gang holds terriotry
        else{
          overlap_y[i,j] <- 0
        }
      } #End of inner loop
    } else { #What if the outerloop gang does not hold territory that year
      for (j in 1:length(gang.names)) {
        overlap_y[i,j] <- 0
      }
    } #End of what if outerloop gang does not hold territory that year
  } #End of outerloop running over each gang in a given year
  assign(paste("overlap",m,sep = ""), overlap_y)
  exceptions <- matrix(0,nrow = 1,ncol = 2)
  already.counted<-0
  counter <- 1
  for(k in 1:74){#new outerloop
   for(l in 1:74){#new inner loop 
    if(overlap_y[k,l]>0&k!=l){# test whether two gangs actually overlapped
      #now check whether this case was already picked up
      for(p in 1:nrow(exceptions))
      {
        if(exceptions[p,1]==k&exceptions[p,2]==l){
          already.counted <- 1
        }
      }
      if(already.counted==0)
      {
      gangs1[counter] <- gang.names[k]
      gangs2[counter] <- gang.names[l]
      overlap1[counter] <- overlap_y[k,l]
      overlap2[counter] <- overlap_y[l,k]
      years[counter] <- m
      temp <- c(l,k)
      exceptions <- rbind(exceptions,temp)
      counter <- counter+1
      }
      already.counted <-0
    }
  }
  }
}  #Loop for each year

potential.mergers <- data.frame(years,gangs1,gangs2,overlap1,overlap2)
library(readr)
write_csv(potential.mergers, path = "C:/Users/Noam Reich/Desktop", ".csv")


testing1 <- gang.maps[gang.maps$year==2016,]
testing1 <- testing1[testing1$gang=="insane unknowns",]
map5 <- leaflet() %>%
       addProviderTiles(providers$CartoDB.Positron) %>%
       addPolygons(data = testing1)
map5
