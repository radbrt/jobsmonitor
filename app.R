#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DBI)
library(bigrquery)
library(janitor)
library(tidyverse)
bq_auth(path = "_jobsdashboard_bq_key.json")


con <- dbConnect(
    bigrquery::bigquery(),
    project = "radjobads",
    dataset = "radjobads",
    billing = "radjobads"
)



datetable <- dbReadTable(con, "history_occ_nace") %>% 
    mutate(year = format(cur_date, "%Y"),
           dayofyear = as.numeric(format(cur_date, "%j")),
           naering = replace_na(naering, "Unknown"))






# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Advertised jobs in Norway"),
    tabsetPanel(type="tabs",
                tabPanel("Total numbers",
                             sidebarLayout(
                                 sidebarPanel(
                                     selectInput("metric", "Measure", choices=c("Number of ads", "Number of positions"))
                                 ),
                                 
                                 
                                 # Show a plot of the generated distribution
                                 mainPanel(
                                     plotOutput("trendline")
                                 )
                             )
                         ),
                tabPanel("Industry",
                         sidebarLayout(
                             sidebarPanel(
                                 selectInput("nace",
                                             "Næring",
                                             choices = sort(unique(datetable$naering))) ),
                             # Show a plot of the generated distribution
                             mainPanel(
                                 plotOutput("nace")
                             )
                         )
                ),
                tabPanel("Occupation",
                         sidebarLayout(
                             sidebarPanel(
                                 selectInput("occgroup",
                                             "Næring",
                                             choices = sort(unique(datetable$yrke_grovgruppe))) ),
                             # Show a plot of the generated distribution
                             mainPanel(
                                 plotOutput("occ")
                             )
                         )
                )
    )
    # Sidebar with a slider input for number of bins 

)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$trendline <- renderPlot({
        
        metric <- ifelse(input$metric=="Number of ads", "antall_annonser", "antall_stillinger")
        
        datetable %>% 
            group_by(year, dayofyear) %>% 
            summarize(antall_annonser = sum(antall_annonser, na.rm=T),
                      antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
            ggplot(aes(dayofyear, eval(parse(text=metric)), group=year, color=year)) +
            geom_line() +
            geom_point() +
            geom_vline(xintercept = 72) +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab(input$metric) +
            ggtitle(paste("Total", input$metric, "by day"))
    })
    
    output$nace <- renderPlot({
        
        datetable %>% 
            filter(naering==input$nace) %>% 
            group_by(year, dayofyear) %>% 
            summarize(antall_annonser = sum(antall_annonser, na.rm=T),
                      antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
            ggplot(aes(dayofyear, antall_annonser, group=year, color=year)) +
            geom_line() +
            geom_point() +
            geom_vline(xintercept = 72) +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab("Number of ads") +
            ggtitle(paste("Total number of active job ads by day, in industry", input$nace))
        
    })
    
    output$occ <- renderPlot({
        
        datetable %>% 
            filter(yrke_grovgruppe==input$occgroup) %>% 
            group_by(year, dayofyear) %>% 
            summarize(antall_annonser = sum(antall_annonser, na.rm=T),
                      antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
            ggplot(aes(dayofyear, antall_annonser, group=year, color=year)) +
            geom_line() +
            geom_point() +
            geom_vline(xintercept = 72) +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab("Number of ads") +
            ggtitle(paste("Total number of active job ads by day, for occupation", input$occgroup))
        
    })

}

# Run the application 
shinyApp(ui = ui, server = server)
