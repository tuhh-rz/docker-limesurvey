FROM ubuntu:18.04

ARG VERSION=${VERSION}
ENV VERSION=$VERSION
RUN echo $VERSION

ARG DOWNLOAD=${DOWNLOAD}
ENV DOWNLOAD=$DOWNLOAD
RUN echo $DOWNLOAD

LABEL \
  de.tuhh.ci_repository_url=$CI_REPOSITORY_URL \
  de.tuhh.ci_commit_short_sha=$CI_COMMIT_SHORT_SHA \
  de.tuhh.build-date=$BUILD_DATE \
  de.tuhh.version=$VERSION \
  de.tuhh.eol=20230501


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
    supervisor \
    wget

RUN apt-get clean

RUN wget "${DOWNLOAD}" -O /tmp/download.tar.gz
RUN tar xf /tmp/download.tar.gz -C /opt && rm /tmp/download.tar.gz

COPY ./apache.sh /opt/apache.sh
RUN chmod +x /opt/apache.sh

COPY ./setup.sh /opt/setup.sh
RUN chmod +x /opt/setup.sh

COPY ./conf/supervisord.conf /etc/supervisord.conf

RUN rm /etc/apache2/sites-enabled/*
#ADD ./conf/default-ssl.conf /etc/apache2/sites-enabled
ADD ./conf/default.conf /etc/apache2/sites-enabled

ADD ./conf/remoteip.conf /etc/apache2/conf-available

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#VOLUME /app/upload

WORKDIR /var/www/app

EXPOSE 80

CMD ["/opt/setup.sh"]
