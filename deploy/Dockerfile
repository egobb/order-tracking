# ---- Build stage ----
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copia el POM primero para cachear dependencias
COPY app/pom.xml app/pom.xml
# Pre-descarga dependencias (cachea ~/.m2)
RUN --mount=type=cache,target=/root/.m2 mvn -f app/pom.xml -B -q -DskipTests dependency:go-offline

# Ahora el código
COPY app/src app/src
# Construye el jar
RUN --mount=type=cache,target=/root/.m2 mvn -f app/pom.xml -B -DskipTests package

# ---- Runtime stage ----
FROM eclipse-temurin:17-jre-alpine
WORKDIR /opt/app

# Opcional: etiqueta de metadatos
LABEL org.opencontainers.image.title="order-tracking" \
      org.opencontainers.image.source="https://github.com/egobb/order-tracking"

# Copia el JAR construido
COPY --from=build /workspace/app/target/order-tracking-*.jar app.jar

# Puerto por defecto de Spring Boot
EXPOSE 8080

# Healthcheck simple contra actuator (ajusta si cambias el path)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1:8080/actuator/health || exit 1

# Permite pasar flags por JAVA_OPTS (Xms/Xmx, perfiles, etc.)
ENV JAVA_OPTS=""
USER 1000

ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]
