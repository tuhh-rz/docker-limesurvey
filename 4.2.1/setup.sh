#!/bin/bash

mkdir -p /var/limesurvey/runtime/
chown www-data.www-data /var/limesurvey/runtime/

chown -Rf www-data.www-data /var/www/app/

if [[ ${ENABLE_SSL} == "true" ]]; then
    sed -i '/SSLCertificateFile/d' /etc/apache2/sites-available/default-ssl.conf
    sed -i '/SSLCertificateKeyFile/d' /etc/apache2/sites-available/default-ssl.conf
    sed -i '/SSLCertificateChainFile/d' /etc/apache2/sites-available/default-ssl.conf

    sed -i 's/SSLEngine.*/SSLEngine on\nSSLCertificateFile \/etc\/apache2\/ssl\/cert.pem\nSSLCertificateKeyFile \/etc\/apache2\/ssl\/private_key.pem\nSSLCertificateChainFile \/etc\/apache2\/ssl\/cert-chain.pem/' /etc/apache2/sites-available/default-ssl.conf

    ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/

    /usr/sbin/a2enmod ssl
else
    /usr/sbin/a2dismod ssl
    [ -e /etc/apache2/sites-enabled/default-ssl.conf ] && rm /etc/apache2/sites-enabled/default-ssl.conf
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

rsync -rc /opt/limesurvey/* "/var/www/app"
chown -Rf www-data.www-data "/var/www/app"

find /var/www/app -type f -print0 | xargs -0 chmod 660
find /var/www/app -type d -print0 | xargs -0 chmod 770

# Configuration

if ! [ -e /var/www/app/application/config/config.php ]; then
    echo >&2 "No config file in $(pwd) Copying default config file..."
    cp /var/www/app/application/config/config-sample-mysql.php /var/www/app/application/config/config.php
fi

export MYSQL_HOST=${MYSQL_HOST:-db}
export MYSQL_PORT=${MYSQL_PORT:-3306}
export MYSQL_DATABASE=${MYSQL_DATABASE:-limesurvey}

perl -i -pe "s/^(\s*'connectionString' => ').*(',)/\1mysql:host=\$ENV{'MYSQL_HOST'};port=\$ENV{'MYSQL_PORT'};dbname=\$ENV{'MYSQL_DATABASE'};\2/g" /var/www/app/application/config/config.php
perl -i -pe "s/^(\s*'username' => ').*(',)/\1\$ENV{'MYSQL_USER'}\2/g" /var/www/app/application/config/config.php
perl -i -pe "s/^(\s*'password' => ').*(',)/\1\$ENV{'MYSQL_PASSWORD'}\2/g" /var/www/app/application/config/config.php

### https://raw.githubusercontent.com/adamzammit/limesurvey-docker/master/docker-entrypoint.sh
if [[ $USE_INNODB == "true" ]]; then
    #If you want to use INNODB - remove MyISAM specification from LimeSurvey code
    sed -i "/ENGINE=MyISAM/s/\(ENGINE=MyISAM \)//1" /var/www/app/application/core/db/MysqlSchema.php
    #Also set mysqlEngine in config file
    sed -i "/\/\/ Update default LimeSurvey config here/s//'mysqlEngine'=>'InnoDB',/" /var/www/app/application/config/config.php
    DBENGINE=InnoDB
    export DBENGINE
fi

if [ -n "$LIMESURVEY_ADMIN_USER" ] && [ -n "$LIMESURVEY_ADMIN_PASSWORD" ]; then
    su -s /bin/bash -c 'php /var/www/app/application/commands/console.php updatedb' www-data ||
        su -s /bin/bash -c "php /var/www/app/application/commands/console.php install '$LIMESURVEY_ADMIN_USER' '$LIMESURVEY_ADMIN_PASSWORD' '$LIMESURVEY_ADMIN_NAME' '$LIMESURVEY_ADMIN_EMAIL' verbose" www-data
    su -s /bin/bash -c "php /var/www/app/application/commands/console.php resetpassword '$LIMESURVEY_ADMIN_USER' '$LIMESURVEY_ADMIN_PASSWORD'" www-data
fi

su -s /bin/bash -c 'php /var/www/app/application/commands/console.php updatedb' www-data

exec /usr/bin/supervisord -nc /etc/supervisord.conf
