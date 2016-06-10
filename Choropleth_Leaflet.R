#setwd("C:/Users/Pippo/Documents/Master Geoinformation Beuth/Masterarbeit/Daten/R_Codes/R_Choropleth_Leaflet")

library(rgdal)
library(mapview)
library(htmltools)
library(htmlwidgets)
library(maptools)

berlin <- readOGR("LOR-Planungsraeume.kml", #name of file
                  #if your browser adds a .txt after downloading the file
                  #you can add it here, too!
                  "LOR_Planungsraum",     #name of layer
                  encoding="utf-8"           #if our data contains german Umlauts like ä, ö and ü
)

mapview(berlin)
#plot(berlin)


Auslaender2007 <- read.csv("LOR_Auslaender_2007.csv", encoding="latin1", sep=",", dec=".")
Auslaender2008 <- read.csv("LOR_Auslaender_2008.csv", encoding="latin1", sep=",", dec=".")

library(leaflet)

palette <- colorBin(c('#fef0d9',
                      '#fdd49e',
                      '#fdbb84',
                      '#fc8d59',
                      '#e34a33',
                      '#b30000'),
                    Auslaender2008$ANTEIL, bins = 6, pretty=TRUE, alpha = TRUE)

popup2007 <- paste0("<strong>Auslaender 2007</strong></span>",
                    "<br><strong>LOR </strong></span>", 
                    Auslaender2007$LORNAME, 
                    "<br><strong> Relativer Auslaenderanteil </strong></span>", 
                    Auslaender2007$ANTEIL
                    ,"<br><strong>Absoluter Auslaenderanteil</strong></span>", 
                    Auslaender2007$AUSLAENDER   
)

popup2008 <- paste0("<strong>Auslaender 2007</strong></span>",
                    "<br><strong>LOR </strong></span>", 
                    Auslaender2008$LORNAME, 
                    "<br><strong> Relativer Auslaenderanteil </strong></span>", 
                    Auslaender2008$ANTEIL
                    ,"<br><strong>Absoluter Auslaenderanteil</strong></span>", 
                    Auslaender2008$AUSLAENDER  
)

mymap <- leaflet() %>% 
  addProviderTiles("Esri.WorldGrayCanvas",
                   options = tileOptions(minZoom=10, maxZoom=16)) %>% #"freeze" the mapwindow to max and min zoomlevel
  
  addPolygons(data = berlin, 
              fillColor = ~palette(Auslaender2007$ANTEIL),  ## we want the polygon filled with 
              ## one of the palette-colors
              ## according to the value in student1$Anteil
              fillOpacity = 1,         ## how transparent do you want the polygon to be?
              color = "darkgrey",       ## color of borders between districts
              weight = 1.5,            ## width of borders
              popup = popup2007,         ## which popup?
              group="<span style='font-size: 11pt'><strong>2007</strong></span>")%>%  
  ## which group?
  ## the group's name has to be the same as later in "baseGroups", where we define 
  ## the groups for the Layerscontrol. Because for this layer I wanted a specific 
  ## color and size, the group name includes some font arguments.  
  
  ## for the second layer we mix things up a little bit, so you'll see the difference in the map!
  addPolygons(data = berlin, 
              fillColor = ~palette(Auslaender2008$ANTEIL), 
              fillOpacity = 1, 
              color = "darkgrey", 
              weight = 1.5, 
              popup = popup2008, 
              group="<span style='font-size: 11pt'><strong>2008</strong></span>")%>%
  
  addLayersControl(
    baseGroups = c("<span style='font-size: 11pt'><strong>2007</strong></span>", "<span style='font-size: 11pt'><strong>2008</strong></span>"
                   
    ),
    options = layersControlOptions(collapsed = FALSE))%>% ## we want our control to be seen right away
  
  addLegend(position = 'topleft', pal = palette, values = Auslaender2008$ANTEIL, opacity = 1, title = "Relativer<br>Auslaenderanteil") 


print(mymap)


## given that Auslaender2007$LORNAME & berlin@data$Name are not written identically
## we sort both according to these columns and then spCbind them  
berlin_srtd <- berlin[order(berlin$Name), ]
row.names(berlin_srtd) <- as.character(1:length(berlin_srtd))
mapview(berlin_srtd, zcol = "Name") # i like checkin what i've done

Auslaender <- list(Auslaender2007,
                   Auslaender2008)

date <- as.Date(c("2007-01-01", "2008-01-01"))

Auslaender_srtd <- lapply(seq(Auslaender), function(i) {
  current <- Auslaender[[i]]
  srtd <- current[order(current$LORNAME), ]
  row.names(srtd) <- as.character(1:nrow(srtd))
  srtd$start <- date[i]
  srtd$end <- date[i]
  return(srtd)
})

final_list <- append(list(berlin_srtd), Auslaender_srtd)

berlin_sp <- Reduce(spCbind, final_list)

mapview(berlin_sp, zcol = c("ANTEIL", "ANTEIL.1"))

## this is beyond me as I don't know what L.timeline expects
## we should get @timelyportfolio involved, I'm sure he'll know how to 
## structure the data correctly
berlin_json <- geojson_json(power,lat="Latitude",lon="Longitude")

## time slider
mymap$dependencies[[length(mymap$dependencies)+1]] <- htmlDependency(
  name = "leaflet-timeline",
  version = "1.0.0",
  src = c("href" = "http://skeate.github.io/Leaflet.timeline/"),
  script = "javascripts/leaflet.timeline.js",
  stylesheet = "stylesheets/leaflet.timeline.css"
)

# use the new onRender in htmlwidgets to run
#  this code once our leaflet map is rendered
#  I did not spend time perfecting the leaflet-timeline
#  options
mymap %>%
  onRender(sprintf(
    'function(el,x){
    var power_data = %s;
    
    var timeline = L.timeline(power_data, {
    pointToLayer: function(data, latlng){
    var hue_min = 120;
    var hue_max = 0;
    var hue = hue_min;
    return L.circleMarker(latlng, {
    radius: 10,
    color: "hsl("+hue+", 100%%, 50%%)",
    fillColor: "hsl("+hue+", 100%%, 50%%)"
    });
    },
    steps: 1000,
    duration: 10000,
    showTicks: true
    });
    timeline.addTo(HTMLWidgets.find(".leaflet"));
    }
    ',
    berlin_sp
  ))


