FROM php:7.3-apache

ENV VERSION '3.15.5+181115'
ENV REPOSITORY 'https://github.com/LimeSurvey/LimeSurvey.git'

RUN \
    apt-get update && \
    apt-get upgrade -qy
    
RUN apt-get install -qy \
    git
    
RUN apt-get clean

RUN git clone --branch "${VERSION}" "${REPOSITORY}" /app

VOLUME /app/upload

EXPOSE 80

