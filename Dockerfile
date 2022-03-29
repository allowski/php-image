FROM php:8.0-apache

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.UTF-8

RUN apt update
RUN apt upgrade -y
RUN apt update && apt install -y zip unzip curl wget
RUN apt install -y imagemagick zlib1g

RUN apt install -y libcurl4
RUN apt install -y libmcrypt-dev
RUN apt install -y libicu-dev
RUN apt install -y libldb-dev
RUN apt install -y libldap2-dev
RUN apt install -y libxml2-dev
RUN apt install -y libssl-dev
RUN apt install -y libzip-dev

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && tar vxf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && cp wkhtmltox/bin/wk* /usr/local/bin/

RUN wkhtmltopdf --version

# Install Postgre PDO
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd xdebug

RUN a2enmod rewrite

RUN mkdir -p /app/src

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
