FROM php:8.1-apache-bullseye

LABEL maintainer.original="David Batranu <david.batranu@eaudeweb.ro>"
LABEL maintainer.current="Mycha de Vrees <m.devrees@gmail.com>"

ENV ROUNDCUBE_VERSION="1.6.1"
ENV DEBIAN_FRONTEND noninteractive

ENV MT_USER mailtrap
ENV MT_PASSWD mailtrap
ENV MT_MAILBOX_LIMIT 51200000
ENV MT_MESSAGE_LIMIT 10240000

RUN apt-get update && apt-get install -q -y \
    postfix \
    dovecot-imapd \
    sqlite3 \
    rsyslog \
    wget \
    libonig-dev \
    libicu-dev \
    nano \
    && \
    a2ensite 000-default && \
    a2enmod expires && \
    a2enmod headers

# RUN docker-php-ext-install -j$(nproc) sqlite3
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl

RUN pear channel-update pear.php.net && \
    pear install mail_mime mail_mimedecode net_smtp net_idna2-beta Auth_SASL Horde_ManageSieve crypt_gpg

WORKDIR /var/

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY postfix/* /etc/postfix/
COPY dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf

RUN wget https://github.com/roundcube/roundcubemail/releases/download/$ROUNDCUBE_VERSION/roundcubemail-$ROUNDCUBE_VERSION-complete.tar.gz -O roundcube.tar.gz && \
    rm -rf www && \
    tar -zxf roundcube.tar.gz && \
    mv roundcubemail-$ROUNDCUBE_VERSION www && \
    rm -rf /var/www/installer && \
    mkdir /var/www/db && \
    . /etc/apache2/envvars && \
    chown -R ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/www/temp /var/www/logs /var/www/db && \
    chmod 777 -R /var/mail


COPY config.inc.php /var/www/config/
COPY docker-entrypoint.sh /var/local/
RUN chmod 777 /var/local/docker-entrypoint.sh

EXPOSE 25 80

# RUN sed -i 's/Listen 80/Listen 8085/' /etc/apache2/ports.conf

ENTRYPOINT ["/var/local/docker-entrypoint.sh"]
