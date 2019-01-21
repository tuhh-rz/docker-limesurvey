#!/bin/bash

chown -Rf www-data.www-data /var/www/html/

if [[ ${ENABLE_SSL} == "true" ]]; then
    sed -i '/SSLCertificateFile/d' /etc/apache2/sites-available/default-ssl.conf
    sed -i '/SSLCertificateKeyFile/d' /etc/apache2/sites-available/default-ssl.conf
    sed -i '/SSLCertificateChainFile/d' /etc/apache2/sites-available/default-ssl.conf

    sed -i 's/SSLEngine.*/SSLEngine on\nSSLCertificateFile \/etc\/apache2\/ssl\/cert.pem\nSSLCertificateKeyFile \/etc\/apache2\/ssl\/private_key.pem\nSSLCertificateChainFile \/etc\/apache2\/ssl\/cert-chain.pem/' /etc/apache2/sites-available/default-ssl.conf

    ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/

    /usr/sbin/a2enmod ssl
else
    /usr/sbin/a2dismod ssl
    rm /etc/apache2/sites-enabled/default-ssl.conf
fi

/usr/sbin/a2enmod rewrite
/usr/sbin/a2enmod authnz_ldap
/usr/sbin/a2enconf remoteip
/usr/sbin/a2enmod remoteip

perl -i -pe 's/^(\s*LogFormat ")%h( %l %u %t \\"%r\\" %>s %O \\"%\{Referer\}i\\" \\"%\{User-Agent\}i\\"" combined)/\1%a\2/g' /etc/apache2/apache2.conf


# Limits: Default values
export UPLOAD_MAX_FILESIZE=${UPLOAD_MAX_FILESIZE:-300M}
export POST_MAX_SIZE=${POST_MAX_SIZE:-300M}
export MAX_EXECUTION_TIME=${MAX_EXECUTION_TIME:-360}
export MAX_FILE_UPLOADS=${MAX_FILE_UPLOADS:-20}
export MAX_INPUT_VARS=${MAX_INPUT_VARS:-1000}
export MEMORY_LIMIT=${MEMORY_LIMIT:-512M}

# Limits
perl -i -pe 's/^(\s*;\s*)*upload_max_filesize.*/upload_max_filesize = $ENV{'UPLOAD_MAX_FILESIZE'}/g' /etc/php/7.2/apache2/php.ini
perl -i -pe 's/^(\s*;\s*)*post_max_size.*/post_max_size = $ENV{'POST_MAX_SIZE'}/g' /etc/php/7.2/apache2/php.ini
perl -i -pe 's/^(\s*;\s*)*max_execution_time.*/max_execution_time = $ENV{'MAX_EXECUTION_TIME'}/g' /etc/php/7.2/apache2/php.ini
perl -i -pe 's/^(\s*;\s*)*max_file_uploads.*/max_file_uploads = $ENV{'MAX_FILE_UPLOADS'}/g' /etc/php/7.2/apache2/php.ini
perl -i -pe 's/^(\s*;\s*)*max_input_vars.*/max_input_vars = $ENV{'MAX_INPUT_VARS'}/g' /etc/php/7.2/apache2/php.ini
perl -i -pe 's/^(\s*;\s*)*memory_limit.*/memory_limit = $ENV{'MEMORY_LIMIT'}/g' /etc/php/7.2/apache2/php.ini

perl -i -pe 's/<\/VirtualHost>/<Directory \/var\/www\/html>\nAllowOverride ALL\n<\/Directory>\n<\/VirtualHost>/' /etc/apache2/sites-available/000-default.conf

rsync -rc /opt/limesurvey/* "/var/www/html"
chown -Rf www-data.www-data "/var/www/html"

find /var/www/html -type f -print0 | xargs -0 chmod 660
find /var/www/html -type d -print0 | xargs -0 chmod 770

exec /usr/bin/supervisord -nc /etc/supervisord.conf
