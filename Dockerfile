FROM linuxserver/baseimage
MAINTAINER Rob Shad <robertmshad@googlemail.com>

# disable interactive functions. 
ENV DEBIAN_FRONTEND noninteractive
ENV APTLIST="php5 php5-sqlite lftp libssh2-php sqlite3 apache2 libapache2-mod-php5 expect"

RUN echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-key E5267A6C && \
	apt-get update -q && \
	apt-get install $APTLIST -qy && \
	apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

#ADD init/ /etc/my_init.d/
RUN chmod -v +x /etc/service/*/run && \
  chmod -v +x /etc/my_init.d/*.sh

# Install composer for PHP dependencies
RUN cd /tmp && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Enable apache mods.
RUN a2enmod php5 && \
	a2enmod rewrite && \
	# Update the PHP.ini file, enable <? ?> tags and quieten logging.
	sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini && \
	sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini && \
	# Generate ssh pub key
	ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && \
	ln -s /config/locomotive-config.yml root/.locomotive && \
	chmod -v +x /app/locomotive && \
	crontab -l | { cat; echo "cd app && ./locomotive -vvv $(printenv REMOTE_SERVER)"; } | crontab -

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
#ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND

# expose container at port 80
EXPOSE 80
VOLUME ["/config", "/app", "/target", "/tmp"]