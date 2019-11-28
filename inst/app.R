library(shinydashboard)
library(shiny)
library(dplyr)
library(leaflet)
library(sf)
library(osmdata)
library(HydroData)
library(nhdplusTools)
source("../R/app_support_functions.R")

d = get_data(IPgeocode())
m = map(d)

# UI

body <- dashboardBody(
  fluidRow(
    column(width = 8,
           box(width = NULL, status = "primary",
               textInput(inputId = "search",   label = NULL, value = "Enter a Location", width = NULL, placeholder = "Search"),
               actionButton(inputId = "go",    label = "Search", icon = NULL),
               actionButton(inputId = "build", label = "Add Buildings", icon = NULL),
               actionButton(inputId = "roads", label = "Add Roads", icon = NULL),
               actionButton(inputId = "grid",  label = "Add Flood Grid", icon = NULL),
               actionButton(inputId = "hydro", label = "Add Hydrology", icon = NULL)
           ),
           box(width = NULL,
               leafletOutput("mymap", height = 500)
           )
    ), 
    column(width = 4, 
           box(width = NULL,
               DT::dataTableOutput("table"))
           )
  ),
  tags$footer(HTML("<p>Developed for: <a href=\"https://github.com/UFOKN\">Urban Flooding Open Knowledge Network</a></p>"))
)

ui = dashboardPage(
  dashboardHeader( title = "Flood Alerts" ),
  dashboardSidebar(disable = TRUE),
  body
)


server <- shinyServer(function(input, output) {
  
  #t =  DT::datatable(data.frame(`Impacted Structures` = c(rep(10,10))))

  observeEvent(input$go, {
    #tmp  = AOI::geocode("UCSB", pt = T)
    tmp <- AOI::geocode(input$search, pt = T)
    if(is.na(st_coordinates(tmp)[1])){ shape = shape} else {shape = tmp}

    d <<-  get_data(shape)
    m <<-  map(d)
   
    output$mymap <- renderLeaflet({ m })

  })
  
  observeEvent(input$build, { add_building(leafletProxy("mymap"), d) } )
  
  observeEvent(input$roads, { add_roads(leafletProxy("mymap"), d) } )
  
  observeEvent(input$grid, { add_flood_grid(leafletProxy("mymap"), d) } )
  
  observeEvent(input$hydro, { add_hydro(leafletProxy("mymap"), d) } )
  
  output$mymap <- renderLeaflet({ m })
  #output$table <- renderDataTable({ t })
})




# # Run the application
shinyApp(ui = ui, server = server)
