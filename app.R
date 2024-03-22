#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Test app 2"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      uiOutput("headers")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      h3("Headers passed into Shiny"),
      verbatimTextOutput("summary"),
      h3("Value of specified header"),
      verbatimTextOutput("value"),
      h3("Date from file"),
      verbatimTextOutput("max_date")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$summary <- renderText({
    ls(env=session$request)
  })
  
  output$headers <- renderUI({
    selectInput("header", "Header:", ls(env=session$request))
  })
  
  output$value <- renderText({
    if (nchar(input$header) < 1 || is.null(input$header) || !exists(input$header, envir=session$request)){
      return("NULL");
    }
    return (get(input$header, envir=session$request));
  })
  
  output$max_date <- renderText({read_max_date()})
}

# Run the application 
shinyApp(ui = ui, server = server)
