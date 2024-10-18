# Dockerfile
# Use an official node image to build the assets
FROM node:latest AS node-builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker caching
COPY package.json package-lock.json ./

# Install node dependencies
RUN npm install

# Copy the rest of your code and build assets
COPY . .
RUN npm run build

# Use PHP official image for Laravel (e.g., php-fpm)
FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    zip unzip curl git libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql gd bcmath

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www

# Copy built assets from node-builder stage
COPY --from=node-builder /app/public /var/www/html/public

# Copy Laravel code
COPY . .

# Set file permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]
