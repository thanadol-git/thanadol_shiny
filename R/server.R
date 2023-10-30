library(shiny)
source("global.R", local = T)
source("ui.R", local = T)

### 6. Server ----

server <- function(input, output, session) {
  
  # SNP data table output
  output$snp.table <- DT::renderDataTable({
    SNP_anno
  })
  
  # Olink data table output
  output$olink.table <- DT::renderDataTable({
    Olink_exprs
  })
  
  # Summarise output variants after cutoff
  output$summarise.qQTL <- DT::renderDataTable(
    {
      filter.manhattan_minimum_qQTL() %>% 
        filter(SNP_type != "nonsig") %>% 
        group_by(SNP_type, Type_variant) %>% 
        summarise( n = n()) %>% ungroup()
    }
  )
  
  # Main pvalue
  pvalue <- reactive({
    input$rawpvalue
  })
  
  # Radio button pvalue
  observe({
    updateNumericInput(
      session = session,
      inputId = "rawpvalue",
      value = input$pexample
    )
  })
  
  
  # Slide bar pvalue
  observe({
    updateNumericInput(
      session = session,
      inputId = "rawpvalue",
      value = 10^-input$logpvalue
    )
  })
  
  # Filtered p value dataset
  filter.minimum_snp_olink <- reactive({
    pQTL.anno %>%
      mutate(SNP_type = ifelse(P <= pvalue(), SNP_type, 'nonsig')) %>% 
      group_by(OlinkID, protein_gene_name) %>%
      filter(P == min(P)) %>%
      filter(BP == min(BP)) 
  })
  
  # Filtered 
  output$dt.qQTL <- DT::renderDataTable({
    filter.manhattan_minimum_qQTL() %>% 
      select(-tot, -BPcum, -is_annotate)
  })
  
  #Filtered gene visit plot
  filter.gene <- eventReactive(input$PlotVisit,{
    filter.minimum_snp_olink() %>%
      filter(protein_gene_name == input$gene.name) %>%
      ungroup() %>%
      select(protein_gene_name, CHR, BP) %>%
      distinct(protein_gene_name, CHR, BP)
  })
  
  #Visit plot
  output$Visit.plot <- renderPlot({
    data <- data.frame(filter.gene())
    
    protein <- data$protein_gene_name
    position <- data$BP
    chromosome <- paste0("chr", data$CHR,sep = "")
    
    qQTL_example_genotype <- SNP_anno %>%
      filter(CHROM == chromosome, POS == position) %>%
      distinct(random_ID, genotype_simp)
    
    plot <- Olink_exprs %>%
      filter(gene_name == protein) %>%
      left_join(qQTL_example_genotype, by = 'random_ID') 
    
    ggplot(plot, aes(x = visit, y = NPX))+
      geom_point(aes(color = genotype_simp))+
      geom_line(aes(color = genotype_simp, group = random_ID))+
      labs(title = protein,
           subtitle = paste(chromosome, position, sep = ': '))+
      scale_color_aaas()+ theme_simp
  }, width = 600, height  = 450, res = 100)
  
  output$filter.table <- DT::renderDataTable({
    filter.manhattan_minimum_qQTL() %>% 
      mutate(logP = -log10(P))
  })
  
  filter.manhattan_minimum_qQTL <- reactive({
    filter.minimum_snp_olink() %>%
      group_by(CHR) %>%
      summarise(chr_len = max(BP)) %>%
      mutate(tot=cumsum(chr_len)-chr_len) %>%
      dplyr::select(-chr_len) %>%
      left_join(filter.minimum_snp_olink(), ., by=c("CHR"="CHR")) %>%
      arrange(CHR, BP) %>%
      mutate(BPcum=BP+tot) %>%
      mutate(is_annotate=ifelse(P< pvalue(), "yes", "no")) 
  })
  #Location plot
  filter.pQTL <- reactive({
    pQTL.anno %>% 
      filter(P <= pvalue())
  })
  
  output$location.plot <- renderPlot({
    data <- filter.pQTL()
    data %>%
      ggplot(aes(x = BP, y = protein_begin+(protein_end-protein_begin)/2))+
      geom_point(aes(color = SNP_type),linewidth =1)+
      facet_grid(protein_chr_name~CHR)+
      xlab('pQTL position')+
      ylab('Protein position')+
      labs(title = "pQTL variants and associated proteins") +
      theme_simp+
      theme(axis.text = element_blank(),
            axis.ticks = element_blank(),
            axis.line = element_line(colour="black",size=0.2),
            panel.spacing = unit(0, "lines"), 
            panel.background=element_rect(fill="white"),
            panel.border=element_rect(colour="black",fill=NA,size=0.2),
            strip.background=element_blank(), plot.title = element_text(hjust = 0.5))
  }, width = 600, height  = 450, res = 100)
  
  #Manhatton plot
  
  output$manhatton.plot <- renderPlot({
    
    data <- filter.manhattan_minimum_qQTL()
    
    axisdf <- data %>% 
      group_by(CHR) %>% 
      summarize(center=(max(BPcum) + min(BPcum) ) / 2 )
    
    chromo_cols <- setNames(c(rep(c('grey40','grey80'),11),'grey40'),seq(1,23))
    
    ggplot(data, aes(x=BPcum, y=-log10(P), label = protein_gene_name)) +
      geom_point( aes(color=as.factor(CHR)), alpha=0.8, size=1) +
      scale_color_manual(values = c(chromo_cols,
                                    'Cis'='#F8766D',
                                    'Trans'='#00BFC4')) +
      scale_x_continuous(label = axisdf$CHR, breaks= axisdf$center ) +
      geom_point(data=subset(filter.manhattan_minimum_qQTL(), is_annotate=="yes"), aes(color = SNP_type), size=1) +
      labs(x = 'Chromosome', title ="Manhatton plot of the sentinel pQTL per protein")+
      geom_text(data=subset(filter.manhattan_minimum_qQTL(), is_annotate=="yes"), aes(label=protein_gene_name, color = SNP_type), size=2.5,vjust = -1, check_overlap = T) +
      theme_simp+ geom_hline(yintercept = -log10(pvalue()), color="grey15", linetype="dashed") +
      theme(legend.position = 'none', plot.title = element_text(hjust = 0.5))
  }, width = 1200, height  = 450, res = 100)
  
  
  
  #Download Buttons
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("filter", ".txt", sep = "")
    },
    content = function(file) {
      write.table(filter.manhattan_minimum_qQTL(), file, row.names = FALSE)
    }
  )
  
  output$downSNP <- downloadHandler(
    filename = function() {
      paste("SNP", ".txt", sep = "")
    },
    content = function(file) {
      write.table(SNP_anno, file, row.names = FALSE)
    }
  )
  
  output$downOlink <- downloadHandler(
    filename = function() {
      paste("olink", ".txt", sep = "")
    },
    content = function(file) {
      write.table(Olink_exprs, file, row.names = FALSE)
    }
  )
  
  output$downFDA <- downloadHandler(
    filename = function() {
      paste("FDA", ".txt", sep = "")
    },
    content = function(file) {
      write.table(S2.FDA, file, row.names = FALSE)
    }
  )
  
  output$S2.FDA <- DT::renderDataTable({
    S2.FDA
  })
  
  output$worksheet <- downloadHandler(
    filename = "CB2030.worksheet_NAMEXXX.docx",
    content = function(file){
      file.copy("Exercise/CB2030_wellness_exercise.21.docx", file)
    }
  )
  
  output$bonus.file <- downloadHandler(
    filename = "CB2030.worksheet_NAMEXXX.docx",
    content = function(file){
      file.copy("Exercise/CB2030_wellness_exercise.docx", file)
    }
  )
  
  
  
  
  
  
  
  
}



###9. ShinyAPP ----
shinyApp(ui = ui, server = server)
