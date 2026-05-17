# Usamos la imagen oficial de MySQL versión 8.0 como base
FROM mysql:8.0

-- Definir el directorio de trabajo dentro del contenedor
WORKDIR /app

# Configurar variables de entorno por defecto (pueden ser sobrescritas al correrlo)
ENV MYSQL_ROOT_PASSWORD=root_password_seguro
ENV MYSQL_DATABASE=db_despachos

# Copiar el script SQL a la carpeta de inicialización nativa de MySQL
# Todos los scripts en esta carpeta se ejecutan en orden alfabético al arrancar por primera vez
COPY init.sql /docker-entrypoint-initdb.d/

# Exponer el puerto estándar de MySQL
EXPOSE 3306