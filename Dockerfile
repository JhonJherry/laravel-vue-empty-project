# ================================
#  Etapa 1: Compilar assets con Node (Vite)
# ================================
FROM node:20-alpine AS build

WORKDIR /app

# Copiar dependencias del frontend
COPY package*.json ./
RUN npm ci

# Copiar todo el código (para compilar)
COPY . .

# Compilar assets de producción (Vite)
RUN npm run build


# ================================
#  Etapa 2: Preparar Laravel con PHP + Composer
# ================================
FROM php:8.3-fpm-alpine AS backend

# Instalar extensiones necesarias para Laravel
RUN apk add --no-cache \
    bash git curl zip unzip libpng-dev libjpeg-turbo-dev freetype-dev icu-dev oniguruma-dev libzip-dev mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd intl zip opcache

# Instalar Composer globalmente
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiar archivos de Laravel
COPY . .

# Copiar el build generado por Node
COPY --from=build /app/public/build ./public/build

# Instalar dependencias PHP sin las de desarrollo
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Limpiar caches y optimizar Laravel
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Establecer permisos correctos
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
