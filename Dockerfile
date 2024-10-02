FROM openjdk:17-slim AS base

WORKDIR /app
COPY SpringApp-0.0.1-SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]