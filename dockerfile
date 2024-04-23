# checkov:skip=CKV_DOCKER_2:Healthcheck instructions have not been added to container images
# checkov:skip=CKV_DOCKER_3:"Ensure that a user for the container has been created"
# hadolint global ignore=DL3008

ARG r=4.2.1
FROM rocker/r-ver:${r}

ARG shinyserver=1.5.20.1002
ENV SHINY_SERVER_VERSION=${shinyserver}
ENV PANDOC_VERSION=default
RUN /rocker_scripts/install_shiny_server.sh

ENV STRINGI_DISABLE_PKG_CONFIG=true \
  AWS_DEFAULT_REGION=eu-west-1 \
  TZ=Etc/UTC \
  LC_ALL=C.UTF-8

WORKDIR /srv/shiny-server

# Cleanup shiny-server dir
RUN rm -rf ./*

# Make sure the directory for individual app logs exists
RUN mkdir -p /var/log/shiny-server

# Ensure Python venv is installed (used by reticulate).
RUN apt-get update -y && \
  apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  libxml2-dev \
  libssl-dev \
  libudunits2-dev \
  libgdal-dev \
  libgeos-dev \
  libproj-dev\
  gdal-bin \
  git \
  libssl-dev \
  libsqlite3-dev \
  python3-boto \
  xtail \
  dos2unix


# APT Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/

# copy across server files
COPY ./server_config/shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY ./server_config/shiny-server.sh /usr/bin/shiny-server.sh
COPY ./server_config/gather_env_vars.py .

# make sure script doesn't contain any non-unix characters
RUN dos2unix /usr/bin/shiny-server.sh

# install renv and dependencies
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
COPY renv.lock renv.lock
ENV RENV_PATH_PATHS_LIBRARY renv/library
RUN R -e "renv::restore()"

# coy across app files - is there a better way to do this? maybe with an app folder
COPY app/app.R app.R
COPY app/R ./R

# Patch the shiny server to allow custom headers
RUN sed -i 's/createWebSocketClient(pathInfo)/createWebSocketClient(pathInfo, conn.headers)/' /opt/shiny-server/lib/proxy/sockjs.js
RUN sed -i "s/'referer'/'referer', 'x-ms-client-principal-name'/" /opt/shiny-server/node_modules/sockjs/lib/transport.js

# Shiny runs as 'shiny' user, adjust app directory permissions
RUN groupmod -g 998 shiny
RUN usermod -u 998 -g 998 shiny
RUN chown -R 998:998 .
RUN chown -R 998:998 /etc/shiny-server
RUN chown -R 998:998 /var/lib/shiny-server

RUN chown -R 998:998 /opt/shiny-server
RUN chown -R 998:998 /var/log/shiny-server
RUN chown -R 998:998 /etc/init.d/shiny-server
RUN chown -R 998:998 /usr/local/lib/R/etc
RUN chown -R 998:998 /usr/local/lib/R/site-library
RUN chown 998:998 /usr/bin/shiny-server.sh
RUN chmod +x /usr/bin/shiny-server.sh

RUN chown 998:998 /etc/profile

EXPOSE 9999

USER shiny
CMD ["/usr/bin/shiny-server.sh"]
