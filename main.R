# load libraries
# install.packages("leaflet")
# install.packages("dplyr")
suppressPackageStartupMessages(library(leaflet))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(dplyr))

plotTrafficAccidents <- function(){
  #load and clean
  data2015 <- read.csv("./dados/2015/ocorrencias-transito-pmsp-2015.csv")
  data2015$lng <- as.numeric(str_match(data2015$WKT, ".*\\((.*)\\s(.*)\\)")[,2])
  data2015$lat <- as.numeric(str_match(data2015$WKT, ".*\\((.*)\\s(.*)\\)")[,3])
  data2015 <- data2015[complete.cases(data2015[,c("lat","lng")]),]
  
  # add legenda com o TIPO_ACIDE
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CO"] <- "Collision / Colisão"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CF"] <- "Frontal collision / Colisão frontal"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CT"] <- "Rear collision / Colisão traseira"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CL"] <- "Side collision / Colisão lateral"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CV"] <- "Transverse Collision / Colisão Transversa"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CP"] <- "Rollover / Capotamento"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="TB"] <- "Overturning / Tombamento"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="AT"] <- "Run over by vehicle / Atropelamento"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="AA"] <- "Atropelamento animal"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="CH"] <- "Shock / Choque"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="QM"] <- "Fall bike|bicycle / Queda moto|bicicleta"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="QV"] <- "Vehicle fall / Queda veículo"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="QD"] <- "Falling - Occupant inside / Queda ocupante dentro"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="QF"] <- "Falling - Occupant outside / Queda ocupante fora"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="OU"] <- "Other / Outros"
  data2015$TIPO_ACIDE_DESCR[data2015$TIPO_ACIDE=="SI"] <- "No Information / Sem informação"
  
  # normaliza numero de vitimas
  data2015$VITIMAS_NORM[data2015$VITIMAS < 100] <- data2015[data2015$VITIMAS < 100,17]
  data2015$VITIMAS_NORM[data2015$VITIMAS >= 100] <- data2015[data2015$VITIMAS >= 100,17] %/% 100
  data2015$VITIMAS_MORTE <- 0
  data2015$VITIMAS_MORTE[data2015$VITIMAS >= 100] <- data2015[data2015$VITIMAS >= 100,17] %% 100
  
  # popup
  data2015$popup <- paste(data2015$TIPO_ACIDE_DESCR, "<br><br>victims:", data2015$VITIMAS_NORM, "<br>deaths:", data2015$VITIMAS_MORTE, "<br>date: ", data2015$DATA, "<br>location code: ", data2015$CADLOGA);
  
  # color
  data2015$color[data2015$COD_ACID==2] <- "blue"
  data2015$color[data2015$COD_ACID==4] <- "red" 
  
  # top 10 locations
  locations <- data2015 %>%
    group_by(WKT) %>%
    summarize(n=n(), vitimas=sum(VITIMAS_NORM), vitimas_morte=sum(VITIMAS_MORTE))
  
  locations$lng <- as.numeric(str_match(locations$WKT, ".*\\((.*)\\s(.*)\\)")[,2])
  locations$lat <- as.numeric(str_match(locations$WKT, ".*\\((.*)\\s(.*)\\)")[,3])
  # locations$lng1 <- locations$lng - 0.001
  # locations$lat1 <- locations$lat - 0.001
  # locations$lng2 <- locations$lng + 0.001
  # locations$lat2 <- locations$lat + 0.001
  
  locations <- arrange(locations, desc(n))
  
  top10 <- head(locations, 10)
  
  top10$popup <- paste("<b>TOP 10 in number of accidents</b><br><br>total accidents: ", top10$n, "<br>victims: ", top10$vitimas, "<br>deaths: ", top10$vitimas_morte)
  
  locations <- arrange(locations, desc(vitimas_morte))
  deadly <- head(locations, 10)
  deadly$popup <- paste("<b>Deadly Location</b><br><br>total accidents: ", deadly$n, "<br>victims: ", deadly$vitimas, "<br>deaths: ", deadly$vitimas_morte)
  
  # most run over
  run_over <- data2015[data2015$COD_ACID==4,] %>%
    group_by(WKT) %>%
    summarize(n=n(), vitimas=sum(VITIMAS_NORM), vitimas_morte=sum(VITIMAS_MORTE))
  
  run_over$lng <- as.numeric(str_match(run_over$WKT, ".*\\((.*)\\s(.*)\\)")[,2])
  run_over$lat <- as.numeric(str_match(run_over$WKT, ".*\\((.*)\\s(.*)\\)")[,3])
  
  run_over <- arrange(run_over, desc(n))
  run_over <- head(run_over, 5)
  run_over$popup <- paste("<b>Top 5 in run over</b><br><br>total accidents: ", run_over$n, "<br>victims: ", run_over$vitimas, "<br>deaths: ", run_over$vitimas_morte)
  
  # cruza dados dos logradouros
  logradouros <- read.csv("./dados/logradouros.csv")
  # levels(logradouros$classificacao)
  logradouros <- logradouros %>% 
    filter(classificacao == "Transito Rápido", codlog5 != "NULL") %>%
    group_by(codlog5) %>%
    summarize(n=n())
  
  run_over_rapido <- data2015 %>%
    filter(COD_ACID==4, CADLOGA %in% logradouros$codlog5)
  
  # factpal <- colorFactor(topo.colors(17), data2015$TIPO_ACIDE, alpha = FALSE, ordered = TRUE)
  
  traffic_accidents_plot <- data2015 %>% leaflet(width=800, height=500, padding=5) %>% addTiles() %>% 
    addCircleMarkers(data = data2015, popup=~popup, clusterOptions = markerClusterOptions(), group="all accidents", color=~color, radius = ~VITIMAS_NORM * 4, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
    addCircleMarkers(data = run_over_rapido, popup=~popup, group="atropelamentos nas vias expressas", color=~color, radius = 8, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
    addCircleMarkers(data = data2015[data2015$COD_ACID==4,], popup=~popup, clusterOptions = markerClusterOptions(), group="run over by vehicle", color=~color, radius = ~VITIMAS_NORM * 4, weight = 3, fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
    addMarkers(data=top10, group="worst location", popup=~popup)%>%
    addMarkers(data=deadly, group="deadly", popup=~popup)%>%
    addMarkers(data=run_over, group="run over by vehicle", popup=~popup)%>%
    addLayersControl(
      baseGroups = c("all accidents", "run over by vehicle", "atropelamentos nas vias expressas"),
      #overlayGroups = c("accident", "run over", "top10", "deadly"),
      overlayGroups = c("worst location", "deadly"),
      options = layersControlOptions(collapsed = FALSE),
      position="bottomleft"
    )
  
  traffic_accidents_plot
  
  # addRectangles(data=locations, lat1=~lat1, lng1=~lng1, lat2=~lat2, lng2=~lng2, group="top10", popup=~popup, color="orange")%>%
  
  #addCircleMarkers(popup = ~TIPO_ACIDE_DESCR, clusterOptions = markerClusterOptions(), color = ~factpal(TIPO_ACIDE), group = ~COD_ACID) %>%
  #addLayersControl(
  #    overlayGroups = c(2, 4),
  #    options = layersControlOptions(collapsed = FALSE)
  # )
  
  # addCircleMarkers(popup = ~TIPO_ACIDE_DESCR, clusterOptions = markerClusterOptions(), color = ~factpal(TIPO_ACIDE)) 
  
  # %>% addLegend(pal = factpal, values = ~TIPO_ACIDE_DESCR, opacity = 1, title = "Traffic Incidents - 2015")
}  