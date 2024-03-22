#!/bin/bash

# Capture environment variables and write to .Renviron
env | grep DATALAKE_CONNECTION_STRING > /home/shiny/.Renviron

# Execute the main process
exec "/usr/bin/shiny-server"