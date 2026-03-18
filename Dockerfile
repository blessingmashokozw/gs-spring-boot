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

# Stage 2: Runtime stage with minimal base image
FROM gcr.io/distroless/java17-debian11 AS runtime

# Create non-root user and group
# Note: distroless images don't support user creation, so we use a different approach
# For production, consider using a minimal image like alpine that supports user management

# Alternative using alpine for better user management:
FROM alpine:3.18 AS runtime-alpine

# Install runtime dependencies (minimal)
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# Set environment variables for configuration (secrets should be passed at runtime)
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC -XX:+UseContainerSupport"
ENV SPRING_PROFILES_ACTIVE=prod

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
