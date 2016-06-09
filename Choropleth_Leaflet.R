setwd("C:/Users/Pippo/Documents/Master Geoinformation Beuth/Masterarbeit/Daten/R_Codes/R_Choropleth_Leaflet")

library(rgdal)
berlin <- readOGR("LOR-Planungsraeume.kml", #name of file
                    #if your browser adds a .txt after downloading the file
                    #you can add it here, too!
                    "LOR_Planungsraum",     #name of layer
                    encoding="utf-8"           #if our data contains german Umlauts like ä, ö and ü
)
plot(berlin)


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


