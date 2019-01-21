#!/bin/bash
# `/sbin/setuser memcache` runs the given command as the user `memcache`.
# If you omit that part, the command will be run as root.
# exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1

source /etc/apache2/envvars

# logs should go to stdout / stderr
set -ex \
	&& ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log"

apache2 -D FOREGROUND
