#!/bin/bash

# Secure Docker build and deployment script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="spring-boot-app"
TAG="${1:-latest}"
REGISTRY="${REGISTRY:-your-registry.com}"

echo -e "${GREEN}Building hardened Docker image...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found. Using .env.example as template.${NC}"
    if [ -f .env.example ]; then
        echo -e "${YELLOW}Please copy .env.example to .env and fill in your secrets.${NC}"
    fi
fi

# Build the Docker image with build args for any non-sensitive configuration
docker build \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
    --build-arg VERSION="${TAG}" \
    -t "${IMAGE_NAME}:${TAG}" \
    -t "${IMAGE_NAME}:latest" \
    .

echo -e "${GREEN}Image built successfully!${NC}"

# Security scan with Docker Scout (if available)
if command -v docker scout &> /dev/null; then
    echo -e "${GREEN}Running security scan...${NC}"
    docker scout cves "${IMAGE_NAME}:${TAG}"
fi

# Run security checks
echo -e "${GREEN}Running security checks...${NC}"

# Check if the image runs as non-root user
USER_CHECK=$(docker run --rm --entrypoint="" "${IMAGE_NAME}:${TAG}" whoami 2>/dev/null || echo "root")
if [ "$USER_CHECK" = "root" ]; then
    echo -e "${RED}WARNING: Image runs as root user!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Image runs as non-root user: $USER_CHECK${NC}"
fi

# Check image size
IMAGE_SIZE=$(docker images "${IMAGE_NAME}:${TAG}" --format "{{.Size}}")
echo -e "${GREEN}✓ Image size: $IMAGE_SIZE${NC}"

# Test the image
echo -e "${GREEN}Testing the image...${NC}"
docker run --rm -d --name test-container -p 8080:8080 "${IMAGE_NAME}:${TAG}"

# Wait for the application to start
echo "Waiting for application to start..."
sleep 10

# Health check
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    docker stop test-container
    exit 1
fi

# Stop test container
docker stop test-container

echo -e "${GREEN}All checks passed! Image is ready for deployment.${NC}"

# Tag for registry if registry is specified
if [ "$REGISTRY" != "your-registry.com" ]; then
    echo -e "${GREEN}Tagging for registry: $REGISTRY${NC}"
    docker tag "${IMAGE_NAME}:${TAG}" "${REGISTRY}/${IMAGE_NAME}:${TAG}"
    docker tag "${IMAGE_NAME}:latest" "${REGISTRY}/${IMAGE_NAME}:latest"
    
    echo -e "${GREEN}Pushing to registry...${NC}"
    docker push "${REGISTRY}/${IMAGE_NAME}:${TAG}"
    docker push "${REGISTRY}/${IMAGE_NAME}:latest"
fi

echo -e "${GREEN}Build and deployment script completed successfully!${NC}"
