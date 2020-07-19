library(shiny)





shinyUI(
  fluidPage(
  tags$head(
    # Include our custom CSS
    includeCSS("www/styles.css")
  ),
  # Application title
  h1("Advertised jobs in Norway"),
  tabsetPanel(type="tabs",
              
              ## TRENDLINE
              tabPanel("Total numbers",
                         fluidRow(column(12,
                                         h2(textOutput("trendline_header")),
                                         plotOutput("trendline")
                         )
                       ),
                       
                       fluidRow(column(10,
                       div(class="jumbotron", 
                           h2("New jobs monitor"),
                           p("New jobs and new job ads posted to nav.no, 7-day rolling average. 2019 shown in grey for reference, 2020 consists of two different data sources: 
                           Historical data (through june) in light blue, and daily new data from the jobs API in darker blue. 
                             The two data sources differ significantly, and the levels have been adjusted to homoginize the time series."),
                           p("Data is updated daily, around 07:10 CET")
                           )),
                       column(2, selectInput("metric", "Measure", choices=c("Number of ads", "Number of positions") )
                       
                       ))
                      
                       
              ),
              
              ## INDUSTRY
              tabPanel("Industry",
                       
                       fluidRow(column(12,
                                       h2(textOutput("industry_header")),
                                       plotOutput("nace")
                       )
                       ),
                       
                       fluidRow(class="details",
                                column(width=2,
                                       div(class="thumbnail",
                                           div(class="caption", h3(class="boxtitle", align="center", "Total difference 2019-2020")),
                                           h2(class="content", textOutput("totdiff_nace"))
                                       )
                                ),
                                column(width = 2,
                                       div(class="thumbnail",
                                           div(class="caption", h3(class="boxtitle", align="center", "Percent difference 2019 - 2020")),
                                           h2(class="content", textOutput("pctdiff_nace"))
                                       )
                                ),
                                column(4, 
                                       selectInput("nace",
                                                   "Næring",
                                                   choices = sort(unique(datetable$naering))) ),
                                column(4, selectInput("metric_nace", "Measure", choices=c("Number of ads", "Number of positions"))
                       )
                       )
              
              ),
              
              ## OCCUPATION
              tabPanel("Occupation",
                       fluidRow(column(12,
                                       h2(textOutput("occupation_header")),
                                       plotOutput("occ")
                       )
                       ),

                       fluidRow(class="details",
                                column(width=2,
                                       div(class="thumbnail",
                                           div(class="caption", h3(class="boxtitle", align="center", "Total difference 2019 - 2020")),
                                           h2(class="content", textOutput("totdiff_occ"))
                                       )
                                ),
                                column(width = 2,
                                       div(class="thumbnail",
                                           div(class="caption", h3(class="boxtitle",align="center", "Percent difference 2019 - 2020")),
                                           h2(class="content", textOutput("pctdiff_occ"))
                                       )
                                ),
                                column(4, 
                                       selectInput("occgroup",
                                                   "Occupation",
                                                   choices = sort(unique(datetable$yrke_grovgruppe))) ),
                                column(4, selectInput("metric_occ", "Measure", choices=c("Number of ads", "Number of positions")) )
                       )
                       ),
              
              ## LIVE
              tabPanel("Live",
                       
                       fluidRow(column(12,
                                       h2(textOutput("live_header")),
                                       plotOutput("live")
                       )
                       ),
                       fluidRow(column(10,
                                       div(class="jumbotron", 
                                           h2("Live jobs monitor"),
                                           p("New jobs and new job ads retrieved through the nav.no API, 7-day rolling average."),
                                           p("Data is updated daily, around 07:10 CET")
                                       )),
                                column(2, 
                                       selectInput("livemetric", "Measure", choices=c("Number of ads", "Number of positions")),
                                       selectInput("liveoccgroup",
                                                   "Occupation",
                                                   choices = sort(unique(pubdf$occ_level1)))
                                       
                                ) )
              )
)
)
  
)

