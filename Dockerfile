FROM php:7.2-apache

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.UTF-8

RUN apt update
RUN apt upgrade -y
RUN apt update && apt install -y bash git zip unzip curl firebird-dev wget
RUN apt install -y imagemagick

RUN apt install -y libcurl4
RUN apt install -y libmcrypt-dev
RUN apt install -y libicu-dev
RUN apt install -y libldb-dev
RUN apt install -y libldap2-dev
RUN apt install -y libxml2-dev
RUN apt install -y libssl-dev

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && tar vxf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && cp wkhtmltox/bin/wk* /usr/local/bin/

RUN wkhtmltopdf --version

RUN docker-php-ext-install interbase
RUN docker-php-ext-install pdo_firebird
RUN docker-php-ext-install mbstring
RUN a2enmod rewrite

RUN mkdir -p /app/src

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
