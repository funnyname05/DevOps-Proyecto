# Etapa 1: Construcción (Build)
# Usamos una imagen de Maven con JDK 17 basada en Alpine para que sea ligera
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build

# Definir el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo pom.xml para descargar las dependencias primero
# Esto aprovecha el sistema de capas de Docker para no descargar todo cada vez
COPY pom.xml .

# Descargar las dependencias necesarias
RUN mvn dependency:go-offline

# Copiar el código fuente del proyecto
COPY src ./src

# Compilar y empaquetar el proyecto saltando los tests para acelerar el proceso
RUN mvn clean package -DskipTests

# Etapa 2: Ejecución (Runtime)
# Usamos el JRE (Java Runtime Environment) 17, suficiente para correr la app
FROM eclipse-temurin:17-jre-alpine

# Definir el directorio de trabajo
WORKDIR /app

# Copiar el archivo .jar generado en la etapa anterior
# Ajustado según el <artifactId> y <version> de tu pom.xml
COPY --from=build /app/target/Springboot-API-REST-DESPACHO-0.0.1-SNAPSHOT.jar app.jar

# Exponer el puerto estándar de Spring Boot
EXPOSE 8080

# Ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]