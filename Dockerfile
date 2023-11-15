# Base image
FROM rocker/shiny:latest

##system libraries of general use

RUN apt-get update -qq \ 
    && apt-get -y --no-install-recommends install \
        wget \
        libxml2-dev \
        libcairo2-dev \
        libsqlite3-dev \ 
    && apt-get update \ 
    && apt-get upgrade -y \ 
    && apt-get clean \
    && rm -rf /srv/shiny-server/*
    
WORKDIR /srv/shiny-server/
RUN Rscript -e 'install.packages(c("shiny","tidyverse", "ggplot2", "RColorBrewer", "ggbeeswarm", "qqman", "shinythemes", "shinydashboard", "plotly", "DT", "shinyWidgets", "dplyr", "ggsci"))'                    


## Download data from google drive
ENV FILEID=13JBnEUFkJj7C52h6MsSZHZGZ_H8F4beL
ENV FILENAME tmp.zip

RUN wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=$FILEID' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$FILEID" -O $FILENAME \
    && rm -rf /tmp/cookies.txt

COPY R ./

## Fix permissions and unzip data
RUN chown -R shiny:shiny . \
    && unzip tmp.zip \
    && rm tmp.zip

EXPOSE 3838

## Must not run as root user
USER shiny

CMD ["/usr/bin/shiny-server"]
