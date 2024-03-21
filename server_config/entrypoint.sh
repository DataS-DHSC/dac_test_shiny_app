#!/bin/bash

# Capture environment variables and write to .Renviron
env | grep datalakeconnectionstring > /home/shiny/.Renviron

# Execute the main process
exec "/usr/bin/shiny-server"