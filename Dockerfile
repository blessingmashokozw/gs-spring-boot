# Multi-stage Dockerfile for Spring Boot application with hardening principles

# Stage 1: Build stage
FROM eclipse-temurin:17-jdk-alpine AS builder

# Install build dependencies
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy build files
COPY complete/build.gradle complete/settings.gradle complete/gradlew complete/gradle/ ./
COPY complete/src ./src

# Make gradlew executable
RUN chmod +x ./gradlew

# Build the application
RUN ./gradlew build --no-daemon

# Stage 2: Runtime stage with minimal distroless image
FROM gcr.io/distroless/java17-debian11 AS runtime

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Set environment variables for configuration (secrets should be passed at runtime)
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC -XX:+UseContainerSupport"
ENV SPRING_PROFILES_ACTIVE=prod

# Run application (distroless doesn't have shell, so we run jar directly)
ENTRYPOINT ["java", "-jar", "app.jar"]
