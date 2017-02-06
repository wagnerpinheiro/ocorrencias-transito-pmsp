# load libraries
# install.packages("leaflet")
# install.packages("dplyr")
suppressPackageStartupMessages(library(leaflet))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(dplyr))



#' load dataset for the year
#' @param int year of dataset, default 2015
#' @return datadrame
#'
TrafficAccidents.loadDataset <- function(year = 2015){
  dataset <- read.csv("./dados/2015/ocorrencias-transito-pmsp-2015.csv")
  
  dataset$DATE <- as.Date(dataset$DATA)
  dataset$TIME_HOUR <- as.integer(str_match(dataset$HORA, "([0-9]?[0-9])([0-9][0-9])")[,2])
  dataset$TIME_MINUTE <- as.integer(str_match(dataset$HORA, "([0-9]?[0-9])([0-9][0-9])")[,3])
  dataset$lng <- as.numeric(str_match(dataset$WKT, ".*\\((.*)\\s(.*)\\)")[,2])
  dataset$lat <- as.numeric(str_match(dataset$WKT, ".*\\((.*)\\s(.*)\\)")[,3])
  
  # add legenda com o TIPO_ACIDE
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CO"] <- "Collision / Colisão"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CF"] <- "Frontal collision / Colisão frontal"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CT"] <- "Rear collision / Colisão traseira"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CL"] <- "Side collision / Colisão lateral"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CV"] <- "Transverse Collision / Colisão Transversa"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CP"] <- "Rollover / Capotamento"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="TB"] <- "Overturning / Tombamento"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="AT"] <- "Run over by vehicle / Atropelamento"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="AA"] <- "Atropelamento animal"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="CH"] <- "Shock / Choque"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="QM"] <- "Fall motorcycle|bicycle / Queda moto|bicicleta"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="QV"] <- "Vehicle fall / Queda veículo"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="QD"] <- "Falling - Occupant inside / Queda ocupante dentro"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="QF"] <- "Falling - Occupant outside / Queda ocupante fora"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="OU"] <- "Other / Outros"
  dataset$TIPO_ACIDE_DESCR[dataset$TIPO_ACIDE=="SI"] <- "No Information / Sem informação"
  
  # normaliza numero de vitimas
  dataset$VITIMAS_NORM[dataset$VITIMAS < 100] <- dataset[dataset$VITIMAS < 100,17]
  dataset$VITIMAS_NORM[dataset$VITIMAS >= 100] <- dataset[dataset$VITIMAS >= 100,17] %/% 100
  dataset$VITIMAS_MORTE <- 0
  dataset$VITIMAS_MORTE[dataset$VITIMAS >= 100] <- dataset[dataset$VITIMAS >= 100,17] %% 100
  
  dataset
}

#' plot a leaflet plot with data
#' @param dataset the data frame with data 
#' @return leaflet plot
#'
TrafficAccidents.plotTrafficAccidents <- function(dataset, filter_by_type=NA){
  # clear NA for leaflet
  dataset <- dataset[complete.cases(dataset[,c("lat","lng")]),]
  
  if(!is.na(filter_by_type) && !filter_by_type=="NA"){
    message(paste("filter by:", filter_by_type))
    dataset <- dataset[dataset$TIPO_ACIDE==filter_by_type,]
  }
  
  # popup
  dataset$popup <- paste(dataset$TIPO_ACIDE_DESCR, "<br><br>victims:", dataset$VITIMAS_NORM, "<br>deaths:", dataset$VITIMAS_MORTE, "<br>date: ", dataset$DATA, "<br>location code: ", dataset$CADLOGA);
  
  # color
  dataset$color[dataset$COD_ACID==2] <- "blue"
  dataset$color[dataset$COD_ACID==4] <- "red" 
  
  
  # top 10 locations
  locations <- dataset %>%
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

  # cruza dados dos logradouros
  logradouros <- read.csv("./dados/logradouros.csv")
  # levels(logradouros$classificacao)
  logradouros <- logradouros %>% 
    filter(classificacao == "Transito Rápido", codlog5 != "NULL") %>%
    group_by(codlog5) %>%
    summarize(n=n())
  
  logradouros_rapido <- dataset %>%
    filter(CADLOGA %in% logradouros$codlog5)
    
  if(is.na(filter_by_type) || filter_by_type=="NA"){  
    # most run over
    run_over <- dataset[dataset$COD_ACID==4,] %>%
      group_by(WKT) %>%
      summarize(n=n(), vitimas=sum(VITIMAS_NORM), vitimas_morte=sum(VITIMAS_MORTE))
    
    run_over$lng <- as.numeric(str_match(run_over$WKT, ".*\\((.*)\\s(.*)\\)")[,2])
    run_over$lat <- as.numeric(str_match(run_over$WKT, ".*\\((.*)\\s(.*)\\)")[,3])
    
    run_over <- arrange(run_over, desc(n))
    run_over <- head(run_over, 5)
    run_over$popup <- paste("<b>Top 5 in run over</b><br><br>total accidents: ", run_over$n, "<br>victims: ", run_over$vitimas, "<br>deaths: ", run_over$vitimas_morte)
    
    # factpal <- colorFactor(topo.colors(17), dataset$TIPO_ACIDE, alpha = FALSE, ordered = TRUE)
  
  
    traffic_accidents_plot <- dataset %>% leaflet(width=800, height=500, padding=5) %>% addTiles() %>% 
      addCircleMarkers(data = dataset, popup=~popup, clusterOptions = markerClusterOptions(), group="all accidents", color=~color, radius = ~VITIMAS_NORM * 4, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
      addCircleMarkers(data = logradouros_rapido, popup=~popup, group="only in freeway", color=~color, radius = 8, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
      addCircleMarkers(data = dataset[dataset$COD_ACID==4,], popup=~popup, clusterOptions = markerClusterOptions(), group="run over by vehicle", color=~color, radius = ~VITIMAS_NORM * 4, weight = 3, fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
      addMarkers(data=top10, group="worst location", popup=~popup)%>%
      addMarkers(data=deadly, group="deadly", popup=~popup)%>%
      addMarkers(data=run_over, group="run over by vehicle", popup=~popup)%>%
      addLayersControl(
        baseGroups = c("all accidents", "run over by vehicle", "only in freeway"),
        #overlayGroups = c("accident", "run over", "top10", "deadly"),
        overlayGroups = c("worst location", "deadly"),
        options = layersControlOptions(collapsed = FALSE),
        position="bottomleft"
      )
  }else{
    traffic_accidents_plot <- dataset %>% leaflet(width=800, height=500, padding=5) %>% addTiles() %>% 
      addCircleMarkers(data = dataset, popup=~popup, clusterOptions = markerClusterOptions(), group="all accidents", color=~color, radius = ~VITIMAS_NORM * 4, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
      addCircleMarkers(data = logradouros_rapido, popup=~popup, group="only in freeway", color=~color, radius = 8, weight = 3,  fillOpacity = ~VITIMAS_MORTE + 0.2 ) %>%
      addMarkers(data=top10, group="worst location", popup=~popup)%>%
      addMarkers(data=deadly, group="deadly", popup=~popup)%>%
      addLayersControl(
        baseGroups = c("all accidents", "only in freeway"),
        overlayGroups = c("worst location", "deadly"),
        options = layersControlOptions(collapsed = FALSE),
        position="bottomleft"
      )
      
  } 
  
  
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

plotTrafficAccidents <- TrafficAccidents.plotTrafficAccidents