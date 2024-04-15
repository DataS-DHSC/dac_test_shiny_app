# get shiny server and R from the rocker project
FROM rocker/r-ver:4.2.1

# System libraries
USER root

## install linux packages
RUN apt-get update && \
    apt-get install -y curl git

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean
    
# install npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 20.12.2

RUN mkdir -p $NVM_DIR

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# install node and npm
RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV PATH $NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH

# Create shiny_user to run tasks needed for shiny server and give access to directories
RUN useradd -ms /bin/bash shiny_user
RUN usermod -a -G staff shiny_user

# Create directory for server and code
RUN mkdir -p /srv/shiny-server/
RUN chown shiny_user /srv/shiny-server/
WORKDIR /srv/shiny-server/

# install MoJ shiny server
RUN npm i ministryofjustice/analytics-platform-shiny-server#fix-socket-reconnect-error
ENV SHINY_APP /srv/shiny-server/app.R
#ENV ALLOWED_PROTOCOLS xhr-polling, iframe-xhr-polling, jsonp-polling

COPY app.R app.R
COPY ./R ./R

RUN install2.r shiny \
    && rm -rf /tmp/downloaded_packages

#Run as shiny_user
USER shiny_user

CMD ["node", "node_modules/analytics-platform-shiny-server"]
