# Use the official PHP image as the base image
FROM php:7.4-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git \
  curl \
  libpng-dev \
  libjpeg62-turbo-dev \
  libfreetype6-dev \
  zip \
  unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -rf /usr/src/php/ext/*/.libs

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install mysqli

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  chmod +x /usr/local/bin/composer

# Verify Composer installation
RUN /usr/local/bin/composer --version

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www

# Ensure storage and bootstrap/cache directories are writable
RUN chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Install Laravel dependencies
RUN /usr/local/bin/composer install --no-interaction --optimize-autoloader

# Set the correct permissions for Laravel folders
RUN chown -R www-data:www-data /var/www/bootstrap/cache /var/www/storage

# Change current user to www
USER www-data

# Generate application key and set it in .env
RUN php artisan key:generate && \
  echo "APP_KEY=$(php artisan key:generate --show)" > /var/www/.env

# Expose port 8000 and start php-fpm server
EXPOSE 8000

CMD ["php-fpm"]

ENTRYPOINT [ "bash", "start-php-server.sh" ]