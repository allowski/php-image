FROM php:8.4.27-apache
# Run update
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.UTF-8

# Install stuff
RUN apt update
RUN apt upgrade -y
RUN apt update && apt install -y zip unzip curl wget gnupg
RUN apt install -y imagemagick zlib1g libcurl4 libmcrypt-dev libicu-dev libldb-dev libldap2-dev libxml2-dev libssl-dev libzip-dev

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

# Google Chrome (stable), for beganovich/snappdf - Chromium-based PDF generation
# replacing wkhtmltopdf, whose bundled Qt has no working SSL. Installing the
# actual Chrome package (rather than a bare Chromium build) is what snappdf's
# own docs recommend for production, and it pulls its own runtime deps (fonts,
# libnss, etc.) via apt instead of us tracking that list by hand.
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

ENV SNAPPDF_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

RUN apt-get autoremove

# --- Security hardening -------------------------------------------------------
# Hardened php.ini (no php.ini existed before, so PHP ran on its built-in
# defaults: display_errors=On, expose_php=On, upload progress on, xdebug in
# develop mode). conf.d/*.ini is parsed after php.ini, so downstream images
# override single directives by adding a file to $PHP_INI_DIR/conf.d/.
COPY config/php/php.ini $PHP_INI_DIR/php.ini

# Apache: hide version info, disable TRACE, cap request bodies at 40 MiB,
# refuse dotfiles / secrets, no directory listings, nosniff header.
COPY config/apache/hardening.conf /etc/apache2/conf-available/hardening.conf
RUN sed -i -e 's/^ServerTokens .*/ServerTokens Prod/' \
           -e 's/^ServerSignature .*/ServerSignature Off/' \
           /etc/apache2/conf-available/security.conf \
    && a2enmod headers \
    && a2enconf hardening \
    && apache2ctl -t

# Self-check (also used by CI): fail the build if the hardening did not take effect.
COPY config/php/hardening-check.php /usr/local/bin/php-hardening-check
RUN chmod +x /usr/local/bin/php-hardening-check && php-hardening-check
