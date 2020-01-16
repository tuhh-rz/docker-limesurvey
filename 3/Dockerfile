FROM ubuntu:18.04


ARG VERSION=${VERSION:-3.21.3+191219}
ENV VERSION=$VERSION
RUN echo $VERSION

ARG MAJOR_VERSION=${MAJOR_VERSION:-3}
ENV MAJOR_VERSION=$MAJOR_VERSION
RUN echo $MAJOR_VERSION


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
    php-xml \
    php-zip
    
RUN apt-get install -qy \
    git \
    rsync \
    supervisor
    
RUN apt-get clean

RUN git clone --branch "${VERSION}" "${REPOSITORY}" /opt/limesurvey

COPY ${MAJOR_VERSION}/apache.sh /opt/apache.sh
RUN chmod +x /opt/apache.sh

COPY ${MAJOR_VERSION}/setup.sh /opt/setup.sh
RUN chmod +x /opt/setup.sh

COPY ${MAJOR_VERSION}/conf/supervisord.conf /etc/supervisord.conf

RUN rm /etc/apache2/sites-enabled/*
#ADD ${MAJOR_VERSION}/conf/default-ssl.conf /etc/apache2/sites-enabled
ADD ${MAJOR_VERSION}/conf/default.conf /etc/apache2/sites-enabled

ADD ${MAJOR_VERSION}/conf/remoteip.conf /etc/apache2/conf-available

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#VOLUME /app/upload

EXPOSE 80

CMD ["/opt/setup.sh"]

