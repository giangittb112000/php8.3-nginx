FROM alpine:3.20
LABEL Maintainer="Giangntdev <giang.nguyentruong@cellphones.com.vn>"
LABEL Description="Lightweight container with Nginx & PHP 8.3 based on Alpine Linux."

RUN echo "Asia/Ho_Chi_Minh" > /etc/timezone

# Setup document root
WORKDIR /var/www/html

RUN apk update && apk upgrade
RUN apk add --no-cache zip unzip curl vim nginx supervisor
RUN apk add --update nodejs npm

# Install packages and remove default server definition
RUN apk add --no-cache \
  php83 \
  php83-pdo \
  php83-pcntl \
  php83-zip \
  php83-pdo_mysql \
  php83-pdo_pgsql \
  php83-pecl-redis \
  php83-pecl-mongodb \
  php83-ctype \
  php83-posix \
  php83-curl \
  php83-dom \
  php83-fileinfo \
  php83-fpm \
  php83-gd \
  php83-intl \
  php83-mbstring \
  php83-mysqli \
  php83-opcache \
  php83-openssl \
  php83-phar \
  php83-session \
  php83-tokenizer \
  php83-xml \
  php83-xmlreader \
  php83-xmlwriter \
  php83-sockets 

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php83/php-fpm.d/www.conf
COPY config/php.ini /etc/php83/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nginx:nginx /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nginx

# Add application
COPY --chown=nginx src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/fpm-ping || exit 1