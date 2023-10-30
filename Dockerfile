# Base image
FROM rocker/shiny:latest
FROM rocker/tidyverse

#system libraries of general use
## install debian packages 
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libsqlite3-dev 
    
## update systems libraries
RUN apt-get update && \ 
    apt-get upgrade -y && \ 
    apt-get clean 
    
RUN R -e "install.packages(pkgs=c('ggplot2', 'tidyverse', 'ggsci', 'RColorBrewer', 'ggbeeswarm', 'qqman', 'shiny', 'shinythemes', 'shinydashboard', 'plotly', 'DT', 'shinyWidgets', 'dplyr'), repos='http://cran.rstudio.com/')"
                           
RUN mkdir /root/app

COPY R /root/shiny_save

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/shiny_save', host = '0.0.0.0', port=3838)"]
