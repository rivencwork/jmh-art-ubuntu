#!/bin/bash

# Script to delete and reload CMS web and API Docker images
# Usage: ./reload-docker-images.sh [service_name]
# If no service specified, will reload all services (api, cms, web)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to reload a specific service
reload_service() {
    local service_name=$1
    local image_name="registry.riven.work/jmh-art-${service_name}:latest"
    
    print_status "Processing service: ${service_name}"
    
    # Stop the container if running
    if docker ps -q -f name=jmh-art-${service_name} | grep -q .; then
        print_status "Stopping container jmh-art-${service_name}..."
        docker stop jmh-art-${service_name}
        print_success "Container jmh-art-${service_name} stopped"
    else
        print_warning "Container jmh-art-${service_name} is not running"
    fi
    
    # Remove the container if it exists
    if docker ps -aq -f name=jmh-art-${service_name} | grep -q .; then
        print_status "Removing container jmh-art-${service_name}..."
        docker rm jmh-art-${service_name}
        print_success "Container jmh-art-${service_name} removed"
    else
        print_warning "Container jmh-art-${service_name} does not exist"
    fi
    
    # Remove the image if it exists
    if docker images -q ${image_name} | grep -q .; then
        print_status "Removing image ${image_name}..."
        docker rmi ${image_name}
        print_success "Image ${image_name} removed"
    else
        print_warning "Image ${image_name} does not exist locally"
    fi
    
    # Pull the latest image
    print_status "Pulling latest image ${image_name}..."
    docker pull ${image_name}
    print_success "Image ${image_name} pulled successfully"
    
    # Start the service using docker compose
    print_status "Starting service ${service_name}..."
    docker compose up -d jmh-art-${service_name}
    print_success "Service ${service_name} started successfully"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [service_name]"
    echo ""
    echo "Available services:"
    echo "  api    - Reload jmh-art-api service"
    echo "  cms    - Reload jmh-art-cms service"
    echo "  web    - Reload jmh-art-web service"
    echo "  all    - Reload all services (api, cms, web)"
    echo ""
    echo "If no service specified, will reload all services"
}

# Main script logic
main() {
    print_status "Starting Docker image reload process..."
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in current directory"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Get the service name from command line argument
    local service_name=${1:-"all"}
    
    case $service_name in
        "api")
            reload_service "api"
            ;;
        "cms")
            reload_service "cms"
            ;;
        "web")
            reload_service "web"
            ;;
        "all")
            print_status "Reloading all services..."
            reload_service "api"
            echo ""
            reload_service "cms"
            echo ""
            reload_service "web"
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            print_error "Invalid service name: $service_name"
            show_usage
            exit 1
            ;;
    esac
    
    print_success "Docker image reload process completed!"
    
    # Show running containers
    print_status "Current running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Run main function
main "$@"
