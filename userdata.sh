#!/bin/bash
sudo apt-get update -y 
sudo apt-get upgrade -y
sudo snap install docker
git clone https://github.com/sukhpreet-41/react-weather-app.git
cd react-weather-app
sudo docker-compose -f docker-compose-dev.yml -f docker-compose-prod.yml up -d --build

