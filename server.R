#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    
    ## TRENDLINE
    
    output$trendline_header <- renderText(paste(input$metric, "posted daily 2019 and 2020, 7-day average"))
    
    output$trendline <- renderPlot({
        
        metric <- ifelse(input$metric=="Number of ads", "antall_annonser", "antall_stillinger")
        
        
        synth_viz %>% 
            ggplot(aes(dayofyear, eval(parse(text=metric)), group=viz_source, label=label)) +
            geom_line(aes(color=line_color)) +
            geom_line(data=subset(synth_viz, viz_source == 'API'), aes(color=line_color)) +
            geom_point(aes(color=line_color)) +
            geom_point(data=subset(synth_viz, viz_source == 'API'), aes(color=line_color)) +
            geom_text_repel(nudge_y      = -200,
                            segment.color = "grey50",
                            direction     = "x") +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            xlab("Day of year") +
            ylab(input$metric) +
            scale_colour_identity() +
            theme_bw() +
            theme(
                panel.border = element_blank()
            )
        
        
        # 
        # datetable %>% 
        #     group_by(year, dayofyear, cur_date) %>% 
        #     summarize(antall_annonser = sum(antall_annonser, na.rm=T),
        #               antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
        #     mutate(label = case_when(
        #         cur_date=='2020-03-12' ~ "Shutdown", 
        #         cur_date=='2020-03-06' ~ "100 cases",
        #         cur_date=='2020-02-26' ~ "First case",
        #         TRUE ~ "")) %>%
        #     ggplot(aes(dayofyear, eval(parse(text=metric)), group=year, label=label)) +
        #     geom_line(aes(color=year) ) +
        #     geom_point(aes(color=year )) +
        #     geom_text_repel(nudge_y      = -5000,
        #                     segment.color = "grey50",
        #                     direction     = "x") +
        #     scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
        #     theme_bw() + 
        #     xlab("Day of year") +
        #     ylab(input$metric)
        
    })
    
    # output$maxdiff <- renderText({ 
    #     delta <- ifelse(input$metric=="Number of ads", "antall_annonser", "antall_stillinger")
    #     
    #     datetable %>% 
    #         group_by(year, dayofyear) %>% 
    #         summarize(value = sum(eval(parse(text=delta)), na.rm=T) ) %>% 
    #         ungroup() %>% 
    #         pivot_wider(names_from=year, values_from=value, names_prefix="Y") %>% 
    #         mutate(delta = Y2020 - Y2019) -> twoyear
    #     
    #     
    #     max(abs(twoyear[["delta"]]), na.rm=T) 
    # }) 
    # 
    # output$meandiff <- renderText({ 
    #     delta <- ifelse(input$metric=="Number of ads", "antall_annonser", "antall_stillinger")
    #     
    #     datetable %>% 
    #         group_by(year, dayofyear) %>% 
    #         summarize(value = sum(eval(parse(text=delta)), na.rm=T) ) %>% 
    #         ungroup() %>% 
    #         pivot_wider(names_from=year, values_from=value, names_prefix="Y") %>% 
    #         mutate(delta = Y2020 - Y2019) -> twoyear
    #     
    #     round(mean(abs(twoyear[["delta"]]), na.rm=T)) 
    # })
    # 
    # output$trendline_text <- renderText(paste("The number of posted positions in 2019 has varied from",
    #                                           min(twoyear$antall_stillinger.y), "to", max(twoyear$antall_stillinger.y),
    #                                           ". For 2020, the same numbers were", min(twoyear$antall_stillinger.x), "and",  max(twoyear$antall_stillinger.x)))
    # 
    # 
    
    
    ## INDUSTRY
    
    output$industry_header <- renderText(paste("Total", input$nace, "first half 2019 and 2020"))
    
    output$nace <- renderPlot({
        
        metric <- ifelse(input$metric_nace=="Number of ads", "antall_annonser", "antall_stillinger")
        
        datetable %>% 
            filter(naering==input$nace) %>% 
            group_by(cur_date, year, dayofyear) %>% 
            summarize(antall_annonser = sum(antall_annonser, na.rm=T),
                      antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
            mutate(label = case_when(
                cur_date=='2020-03-12' ~ "Shutdown", 
                cur_date=='2020-03-06' ~ "100 cases",
                cur_date=='2020-02-26' ~ "First case",
                TRUE ~ "")) %>%
            ggplot(aes(dayofyear, eval(parse(text=metric)), group=year, label=label)) +
            geom_line(aes(color=year)) +
            geom_point(aes(color=year)) +
            geom_text_repel(nudge_y      = -200,
                            segment.color = "grey50",
                            direction     = "x") +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab("Number of ads") +
            theme(
                panel.border = element_blank()
            )
        
    })
    
    output$totdiff_nace <- renderText({ 
        
        metric <- ifelse(input$metric_nace=="Number of ads", "antall_annonser", "antall_stillinger")
        
        nacewide %>% 
            filter(naering==input$nace) %>% 
            filter(measure == metric) -> tmp
        
        tmp[["delta"]][[1]]
        
    }) 
    
    output$pctdiff_nace <- renderText({ 
        
        metric <- ifelse(input$metric_nace=="Number of ads", "antall_annonser", "antall_stillinger")
        
        nacewide %>% 
            filter(naering==input$nace) %>% 
            filter(measure == metric) -> tmp
        
        paste(tmp[["deltapct"]][[1]], "%")
    }) 
    
    
    ## OCCUPATION
    
    output$occupation_header <- renderText(paste("Total", input$occgroup, "first half 2019 and 2020"))


    output$occ <- renderPlot({
        
        metric <- ifelse(input$metric_occ=="Number of ads", "antall_annonser", "antall_stillinger")
        
        datetable %>% 
            filter(yrke_grovgruppe==input$occgroup) %>% 
            group_by(cur_date, year, dayofyear) %>% 
            summarize(antall_annonser = sum(antall_annonser, na.rm=T),
                      antall_stillinger = sum(antall_stillinger, na.rm=T)) %>% 
            mutate(label = case_when(
                cur_date=='2020-03-12' ~ "Shutdown", 
                cur_date=='2020-03-06' ~ "100 cases",
                cur_date=='2020-02-26' ~ "First case",
                TRUE ~ "")) %>%
            ggplot(aes(dayofyear, eval(parse(text=metric)), group=year, label=label)) +
            geom_line(aes(color=year)) +
            geom_point(aes(color=year)) +
            geom_text_repel(nudge_y      = -200,
                            segment.color = "grey50",
                            direction     = "x") +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab("Number of ads") +
            theme(
                panel.border = element_blank()
            )
        
    })
    
    output$totdiff_occ <- renderText({ 
        
        metric <- ifelse(input$metric_occ=="Number of ads", "antall_annonser", "antall_stillinger")
        
        occwide %>% 
            filter(measure == metric)  %>% 
            filter(yrke_grovgruppe == input$occgroup) -> tmp
        
        tmp[["delta"]][[1]]
    }) 
    
    output$pctdiff_occ <- renderText({ 
        
        metric <- ifelse(input$metric_occ=="Number of ads", "antall_annonser", "antall_stillinger")
        
        occwide %>% 
            filter(measure == metric)  %>% 
            filter(yrke_grovgruppe == input$occgroup) -> tmp
        
        paste(tmp[["deltapct"]][[1]], "%")
    }) 
    
    
    ## LIVE
    
    output$live <- renderPlot({
        
        livemetric <- ifelse(input$livemetric=="Number of ads", "annonser", "stillinger")

        pubdf %>% 
            filter(published>='2020-06-17') %>% 
            filter(occ_level1==input$liveoccgroup) %>% 
            group_by(year, dayofyear) %>% 
            summarize(annonser = sum(annonser, na.rm=T),
                      stillinger = sum(stillinger, na.rm=T)) %>% 
            ggplot(aes(dayofyear, eval(parse(text=livemetric)))) +
            geom_line() +
            geom_point() +
            expand_limits(y=0) +
            scale_x_continuous(labels = function(x) format(as.Date(as.character(x), "%j"), "%d-%b")) +
            theme_bw() + 
            xlab("Day of year") +
            ylab(input$livemetric) +
            theme(
                panel.border = element_blank()
            )
    })
    
    output$live_header <- renderText({
        paste("Running 7-day average of jobs published, for occupation", input$liveoccgroup) 
    })

}
)

# Run the application 
#shinyApp(ui = ui, server = server)
