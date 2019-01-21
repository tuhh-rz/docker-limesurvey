FROM ubuntu:18.04

ENV VERSION '3.15.5+181115'
ENV REPOSITORY 'https://github.com/LimeSurvey/LimeSurvey.git'

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get upgrade -qy

RUN apt-get install -qy \
    apache2 \
    libapache2-mod-php \
    php \
    php-gd \
    php-imap \
    php-ldap \
    php-mbstring \
    php-mysql \
    php-zip
    
RUN apt-get install -qy \
    git
    
RUN apt-get clean

RUN git clone --branch "${VERSION}" "${REPOSITORY}" /app

COPY ./apache.sh /opt/apache.sh
RUN chmod +x /opt/apache.sh

COPY ./conf/supervisord.conf /etc/supervisord.conf

RUN rm /etc/apache2/sites-enabled/*
#ADD ./conf/default-ssl.conf /etc/apache2/sites-enabled
ADD ./conf/default.conf /etc/apache2/sites-enabled

ADD ./conf/remoteip.conf /etc/apache2/conf-available

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /app/upload

EXPOSE 80

CMD ["/opt/setup.sh"]

