# ==========================================================
# 🏗️ ETAPA 1: Construcción del frontend con Node + Vite
# ==========================================================
FROM node:20-alpine AS build

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos necesarios
COPY package*.json ./
RUN npm ci

# Copiar todo el proyecto
COPY . .

# Desactivar el plugin Wayfinder en producción (si lo usas)
ENV NODE_ENV=production

# Ejecutar build de Vite (no necesita PHP)
RUN npm run build

# ==========================================================
# 🧩 ETAPA 2: Backend con PHP-FPM + Composer
# ==========================================================
FROM php:8.3-fpm-alpine AS backend

# Instalar dependencias del sistema
RUN apk add --no-cache \
    bash git curl zip unzip libpng-dev libjpeg-turbo-dev freetype-dev icu-dev oniguruma-dev libzip-dev mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd intl zip opcache

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar composer desde una imagen oficial (más rápido)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copiar archivos del proyecto
COPY . .

# Copiar los assets compilados desde la etapa anterior
COPY --from=build /app/public/build ./public/build

# Instalar dependencias PHP
RUN composer install --no-dev --optimize-autoloader

# Permisos correctos para Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Puerto expuesto por PHP-FPM
EXPOSE 9000

# Comando final
CMD ["php-fpm"]
