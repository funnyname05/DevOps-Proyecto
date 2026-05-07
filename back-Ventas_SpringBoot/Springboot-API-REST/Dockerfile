# Etapa 1: Compilación (Build)
# Usamos una imagen de Maven con JDK 17 para compilar el proyecto
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar el archivo pom.xml para descargar las dependencias
# Esto ayuda a aprovechar la caché de Docker si el pom no cambia
COPY pom.xml .

# Descargar dependencias (modo offline para acelerar builds posteriores)
RUN mvn dependency:go-offline

# Copiar el código fuente
COPY src ./src

# Compilar el proyecto y generar el JAR (omitiendo tests para agilizar)
RUN mvn clean package -DskipTests

# Etapa 2: Ejecución (Runtime)
# Usamos una imagen ligera de JRE 17 para correr la aplicación
FROM eclipse-temurin:17-jre-alpine

# Directorio de trabajo en el contenedor
WORKDIR /app

# Copiar el JAR generado desde la etapa de compilación
# El nombre del JAR se basa en el artifactId y version de tu pom.xml
COPY --from=build /app/target/Springboot-API-REST-0.0.1-SNAPSHOT.jar app.jar

# Exponer el puerto por defecto de Spring Boot
EXPOSE 8080

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]