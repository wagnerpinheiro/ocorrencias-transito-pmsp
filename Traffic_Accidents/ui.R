#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# prepare dependency files to deploy on shiny server:
if (!file.exists("./main.R")) {
  file.copy("../main.R", "./main.R")
}
if (!file.exists("./dados/2015/ocorrencias-transito-pmsp-2015.csv")) {
  dir.create("./dados/2015/", recursive = TRUE)
  file.copy(
    "../dados/2015/ocorrencias-transito-pmsp-2015.csv",
    "./dados/2015/ocorrencias-transito-pmsp-2015.csv"
  )
}
if (!file.exists("./dados/logradouros.csv")) {
  file.copy("../dados/logradouros.csv", "./dados/logradouros.csv")
}

if (!file.exists("./the_app.png")) {
  file.copy("../presentation_app-figure/the_app2.png", "./the_app.png")
}

library(shiny)
library(leaflet)

# Define UI for application that draws a histogram
shinyUI(#fluidPage(
  # Application title
  # titlePanel("Traffic Accidents in São Paulo - 2015"),
  
  navbarPage(
    "Traffic Accidents in São Paulo - 2015",
    tabPanel("App",
             
             # Sidebar with a slider input for number of bins
             sidebarLayout(
               sidebarPanel(
                 selectInput(
                   "filter_type_accident",
                   "Filter by the by type of accident, to know where they occur most and where they are fatal:",
                   c(
                     "All / Todos" = NA,
                     "Collision / Colisão" = "CO",
                     "Frontal collision / Colisão frontal" = "CF",
                     "Rear collision / Colisão traseira" = "CT",
                     "Side collision / Colisão lateral" = "CL",
                     "Transverse Collision / Colisão Transversa" = "CV",
                     "Rollover / Capotamento" = "CP",
                     "Overturning / Tombamento" = "TB",
                     "Run over by vehicle / Atropelamento" = "AT",
                     "Atropelamento animal" = "AA",
                     "Shock / Choque" = "CH",
                     "Fall motorcycle|bicycle / Queda moto|bicicleta" = "QM",
                     "Vehicle fall / Queda veículo" = "QV",
                     "Falling - Occupant inside / Queda ocupante dentro" = "QD",
                     "Falling - Occupant outside / Queda ocupante fora" = "QF",
                     "Other / Outros" = "OU",
                     "No Information / Sem informação" = "SI"
                   ), selected = "QM"
                 ) #,
                 # hr(),
                 # h4("app debug info:"),
                 # pre(paste("dataset file found: ",file.exists("./dados/2015/ocorrencias-transito-pmsp-2015.csv"))),
                 # pre(paste("logradouros file found: ",file.exists("./dados/logradouros.csv"))),
                 # pre(paste("lib file found: ",file.exists("./main.R")))
               ),
               
               # Show a plot of the generated distribution
               mainPanel(leafletOutput("map_sp"))
             )
      ),
    tabPanel("Documentation",
             p("Interactive map of traffic accidents in the metropolitan region of São Paulo, clustered by region and type, during the year 2015."),
             p("Use the filter on the sidebar to calculate the deadly and worst places in São Paulo Transit.")
             
    )
  ))
