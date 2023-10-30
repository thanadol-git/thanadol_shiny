### set up----
library(ggplot2)
library(tidyverse)
library(ggsci)
library(RColorBrewer)
library(ggbeeswarm)
library(qqman)
library(shiny)
library(shinythemes)
library(shinydashboard)
library(plotly)
library(DT)
library(shinyWidgets)
library(dplyr) 


### Dropbox token ----


# Timezone
Sys.setenv(TZ="Europe/Stockholm")



### theme ----
theme_simp <- 
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.spacing = unit(0.2, "lines"), 
        panel.background=element_rect(fill="white"),
        panel.border=element_blank(),
        plot.title = element_text(face = "bold",
                                  size = rel(1.3), hjust = 0.5),
        plot.subtitle=element_text(face = "bold",hjust = 0.5, size=rel(1),vjust=1),
        axis.title = element_text(face = "bold",size = rel(1)),
        axis.ticks = element_line(),
        axis.ticks.length = unit(.25, "cm"),
        axis.line = element_line(size = rel(1),color = 'black'),
        axis.text = element_text(color = 'black', size = rel(1)),
        legend.key = element_blank(),
        legend.position = "bottom",
        legend.text = element_text(size=rel(0.8)),
        legend.key.size= unit(0.7, "cm"),
        legend.title = element_text(size=rel(1)),
        plot.margin=unit(c(10,5,5,5),"mm"),
        strip.background=element_rect(colour="#f0f0f0",fill="#f0f0f0"),
        strip.text = element_text(face="bold"))


### ------1. data location -----------
Olink_assays_path <- './Upload/Olink_ensg_id_location.txt'
Genotype_anno_path <- './Upload/syn.Genotype_annotation.txt'
pQTL_candidate_path <- './Upload/pQTL_sig.txt'
Olink_exprs_path <- './Upload/syn.Olink_exprs.txt'
S2.FDA_path <- "./Upload/S2.FDA.txt"
pQTL.anno_path <- "./Upload/pQTL.anno.csv"

### ------2. data input -------
# Olink assay targets
Olink_assays_anno <-
  Olink_assays_path %>%
  read_delim(delim = '\t') %>% 
  distinct()

Olink_exprs <-
  Olink_exprs_path %>%
  read_delim(delim = '\t') %>%
  gather(Assay, NPX, -random_ID, -visit) %>% 
  left_join(Olink_assays_anno, by = 'Assay', relationship = "many-to-many") %>%
  mutate(visit = paste0('visit',visit))

SNP_anno <-
  Genotype_anno_path %>%
  read_delim(delim = '\t') 

pQTLs <-
  pQTL_candidate_path %>%
  read_delim(delim = '\t')

S2.FDA <- 
  S2.FDA_path %>%
  read_delim(delim = "\t")

pQTL.anno <-  pQTL.anno_path %>% 
  read_delim(delim = ",")

### 4. Dashboard ----
dashboard <- dashboardSidebar(
  sidebarMenu(
    menuItem("Intro", tabName = "Intro", icon = icon("book-reader")),
    menuItem("Instruction", tabName = "instruction", icon = icon("hand-point-right")),
    menuItem("Data", tabName = "data", icon = icon("flask")),
    menuItem("pQTLs", tabName = "pQTLs", icon = icon("filter")),
    menuItem("Visit", tabName = "visit", icon = icon("hourglass")),
    menuItem("FDA", tabName = "fda", icon = icon("capsules")), 
    menuItem("Questions", tabName = "question", icon = icon("question")),
    menuItem("HPA/Bonus", tabName = "HPA",icon = icon("spider")),
    menuItem("Contact", tabName = "contact", icon = icon("location-arrow"))
  ))


### 5. Body ----
body <-dashboardBody(
  
  tabItems(
    
    
    tabItem(
      tabName = "data",
      h1("Start from experimental data"),
     tabsetPanel(type = "tabs",
        tabPanel("SNP",
            DT::dataTableOutput("snp.table"),
            downloadButton('downSNP', 'Download')
            ),
        tabPanel("Olink",
            DT::dataTableOutput("olink.table"),
            downloadButton('downOlink', 'Download')
            ),
        tabPanel("Tip!",
          HTML('<iframe width="560" height="315" src="https://www.youtube.com/embed/V6AR_Hi7p5Q" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>')
          )
      )
    ),
    
    
    tabItem(tabName = "pQTLs",
              tabsetPanel(type = "tabs",
                tabPanel("Manhatton", 
                         plotOutput("manhatton.plot", width=800)),
                tabPanel("Location", 
                         plotOutput("location.plot", width =800)),
                tabPanel("Data table", 
                         downloadButton('downloadData', 'Download'), 
                         DT::dataTableOutput("dt.qQTL")
                         ) ),
              hr(), 
              hr(),
              hr(),
            
              fluidRow(
                
                column(3, 
                       h4("p-value controller"),
                       numericInput("rawpvalue", "p-value cutoff", value = 1e-30, width = "60%")
                       
                       ),
                column(4, 
                       sliderInput("logpvalue", "Select -log10(p-value) cutoff:", min =5, max = 50, value =30, step = 0.02),
                       radioGroupButtons(
                         inputId = "pexample",
                         label = "Examples",
                         choices = c("5e-8" = 5e-8, 
                                     "6e-11" = 6e-11),
                         justified = TRUE,
                         checkIcon = list(
                           yes = icon("ok", 
                                      lib = "glyphicon")))
                       )
              ),
              strong("It may take time to render a large number of values!")
                  
    ),
    
    
    tabItem(tabName = "visit",
            textInput("gene.name", "Select your protein (GeneCards Symbol):", value = "BST1"), 
            actionButton("PlotVisit","Plot!", class = "btn-primary"), 
            plotOutput("Visit.plot", width = 500)
    ),
    
    
    tabItem(tabName = "contact",
            column(6, h2(strong("Contact us")),
            #plotOutput("kthlogo"),
            h4("Fredrik Edfors: instructor"),
            h4("Thanadol Sutantiwanichkul: TA, web developer"),
            h6("For further questions on this exercise, please send a mail to 
               thanadol@kth.se with", em("#CB2030"), "."),
            h6("Version 2023.1.0"))
    ),
    
    
    tabItem(tabName = "Intro",
            fluidRow(
              
              h2(strong("CB2030 on the Wellness study")), 
              
              box(
                width = 12,
                title = "Intended Learning Outcomes (ILOs)",
                "After this lab, you will be able to describe the concept 
                of single nucleotide polymorphisms and how they may affect protein 
                expression levels in eukaryotic systems. You will be able to identify 
                and differentiate between genes that have a strong genetic 
                linkage based on the measured protein level.  After completing the 
                optional Bonus Exercise, you will be able to describe conceptual 
                differences when studying secreted vs non-secreted proteins and 
                relate this to the challenges of today’s clinical diagnostic approaches, 
                especially when measuring single protein biomarkers in large human 
                populations."
              ),
              box(
                width = 12,
                title = "Introduction",
                "This computer exercise has been designed to let you explore a 
                unique dataset containing paired genetics and proteomics measurements 
                in a healthy cohort. The original set includes whole genome 
                sequencing data covering ~7.3 million SNPs with paired longitudinal 
                data over 2 years. We will focus on 
                the proteins that are present in human blood plasma, which is 
                important for many biological processes and harbours common targets 
                for diagnostics and therapy. It is therefore of great interest 
                to understand the interplay between genetic and environmental 
                factors to determine the specific protein levels in individuals. 
                This can aid us in our understanding of the importance of genetic 
                architecture related to the individual variability of plasma levels 
                of proteins during adult life."
              ),
              box(
                width = 12,
                title = "Method",
                "You will analyze a dataset combined of whole-genome sequencing, 
                multiplex plasma protein profiling and clinical parameters. 
                The dataset is artificial in the sense that we have masked and 
                randomized parameters from the original dataset to not reveal any personal data."
              ),
              box(width = 12,
                  em("Note. We cannot share or publish any individual data. 
                      The data have been modified, imputed, and anonymized. 
                      The individual identities that you see in this exercises 
                      have been generated randomly from the most common names in Sweden. 
                      We do not intend to offend any particular person. 
                      Most of the exercise will be based on population-level 
                     and/or aggregated data. Please consider this when evaluating 
                     and interpreting the data from the biological point of 
                     view, when comparing results to published work etc. 
                     This may be the root cause of why you see discrepancies 
                     between the original publication and this exercise.")  
                  )
            )
    ),
    
    tabItem(tabName = "HPA",
            h1("The Human Protein Atlas"),
            tabsetPanel(
              tabPanel(title = "Preparation",
                       h5("Please carefully review this paper"),
                       tags$iframe(style = "height:800px; width:100%;scrolling=yes", src = "eaaz0274.full.pdf")
                       
                       ),
              tabPanel(title = "Bonus exercise",
                       tags$iframe(style = "height:800px; width:100%;scrolling=yes", src = "Bonus.manual.pdf")
                       )
            )
    ), 
    
    tabItem(tabName = "instruction", 
            box(width =12, 
                title = "Lab instructions",
                "All questions and exercises can be solved using the online R Shiny toolbar developed for this lab exercise, but you will have to work with the data manually. You can either use simple spreadsheet handling softwares (such as Microsoft Excel or similar), or use R, Python or Matlab combined with simple operations.",
                tags$br(), tags$br(),
                "Please answer the following questions (Q1-Q8) in the worksheet to complete the lab exercise. These should be handed in through Canvas.
                All data needed to complete this exercise can be viewed in the RShiny app,",
                tags$a(href="thanadol.shinyapps.io/CB2030", "thanadol.shinyapps.io/CB2030"),
                ", and also can be downloaded from",
                tags$a(href="https://canvas.kth.se/courses/25851", "Canvas"), "."
                ),
            # box(width = 12, 
            #     HTML('<iframe width="560" height="315" src="https://www.youtube.com/embed/Bkhtbj9tPMk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>')
            #     
            # ),
            
            
            box(
              width = 12,
              title = "Preparations",
              em("Note. Please carefully read these papers before the computer lab."),
              tabsetPanel(type = "tabs",
                          tabPanel("Wellness",
                                   tags$iframe(style = "height:800px; width:100%;scrolling=yes", src = "msb.20145728.pdf")
                          ),
                          tabPanel("Plasma proteome",
                                   tags$iframe(style = "height:800px; width:100%;scrolling=yes", src = "msb.20145728.pdf")
                          )
              )
            )
    ),
    
    tabItem(tabName = "fda", 
            DT::dataTableOutput("S2.FDA"),
            downloadButton('downFDA', 'Download')
    ),
    
    tabItem(tabName = "question",
            box(width = 12, title = "See the worksheet!",
            "To finish this exercise, you need to answer the question that we provided in the file below. 
               There are a few questions that will encourage you to understand this study even better.
               The worksheet will also contain the bonus questions from Max Karlsson. 
               The instruction for his study is provided in the HPA tab, Nevertheless, if you are struggling at some point,
               please just write an e-mail to thanadol@kth.se. Good luck and have a lot of fun!",
            tags$br(), tags$br(),
            downloadLink("worksheet", "Download worksheet!") 
            )
            ),
    
    tabItem(tabName = "answer", 
            DT::dataTableOutput("summarise.qQTL")
            )
    ))                       

### 7. Header ----
header <- dashboardHeader(title = "CB2030: Lab4")




