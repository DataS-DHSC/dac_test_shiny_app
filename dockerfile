# get shiny server and R from the rocker project
FROM rocker/shiny-verse:4.2.1

# System libraries
USER root

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean
    
RUN apt-get update -y && apt-get install -y dos2unix

#Create shiny_user to run tasks needed for shiny server and give access to directories
RUN useradd -ms /bin/bash shiny_user
RUN sudo usermod -a -G staff shiny_user

#Add shiny user to staff group to give access to directories
RUN sudo usermod -a -G staff shiny    

# Remove sample apps bundled in shiny-verse
RUN sudo rm -rf /srv/shiny-server/01_hello
RUN sudo rm -rf /srv/shiny-server/02_text
RUN sudo rm -rf /srv/shiny-server/03_reactivity
RUN sudo rm -rf /srv/shiny-server/04_mpg
RUN sudo rm -rf /srv/shiny-server/05_sliders
RUN sudo rm -rf /srv/shiny-server/06_tabsets
RUN sudo rm -rf /srv/shiny-server/07_widgets
RUN sudo rm -rf /srv/shiny-server/08_html
RUN sudo rm -rf /srv/shiny-server/09_upload
RUN sudo rm -rf /srv/shiny-server/10_download
RUN sudo rm -rf /srv/shiny-server/11_timer
RUN sudo rm /srv/shiny-server/index.html
RUN sudo rm -rf /srv/shiny-server/sample-apps

RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(renv.config.pak.enabled = FALSE, repos = c(CRAN = 'https://cran.ma.imperial.ac.uk/'), download.file.method = 'libcurl')" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site

#Run as shiny_user
USER shiny_user

WORKDIR /srv/shiny-server/

COPY ./server_config/entrypoint.sh entrypoint.sh

# Copy updated shiny-server.conf to increase wait/idle time (useful when packages need to install or be loaded for the first time)
COPY ./server_config/shiny-server.conf /etc/shiny-server/shiny-server.conf

COPY app.R app.R
COPY ./R ./R

#RUN R -e 'install.packages("renv")'
#COPY renv.lock renv.lock
#RUN R -e 'options(repos = c(CRAN = "https://cran.ma.imperial.ac.uk/")); renv::restore()'
#RUN R -e 'install.packages("arrow")'
RUN R -e 'install.packages("AzureStor")'
#RUN R -e 'install.packages("curl")'
#RUN R -e 'install.packages("httr")'
#RUN R -e 'install.packages("shiny")'
#RUN R -e 'install.packages("stringr")'
#RUN R -e 'install.packages("tidyr")'

USER root
RUN dos2unix entrypoint.sh
RUN chmod +x entrypoint.sh

#Start Shiny Server and Run as shiny
USER shiny
CMD ["/srv/shiny-server/entrypoint.sh"]