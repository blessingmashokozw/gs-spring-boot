# Build stage
FROM gradle:8-jdk17 AS build
WORKDIR /app
COPY complete/ .
RUN ./gradlew build

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/build/libs/spring-boot-complete-0.0.1-SNAPSHOT.jar app.jar
RUN mkdir -p /app/logs
ENTRYPOINT ["java","-jar","app.jar"]
