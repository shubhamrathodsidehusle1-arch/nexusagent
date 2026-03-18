.PHONY: help install build run test docker-build docker-up docker-down clean

help:
	@echo "NexusAgent Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  make install       - Install dependencies"
	@echo "  make build         - Build the server"
	@echo "  make run           - Run the server"
	@echo "  make test          - Run tests"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-up     - Start with Docker Compose"
	@echo "  make docker-down   - Stop Docker Compose"
	@echo "  make clean        - Clean build artifacts"

install:
	@echo "Installing dependencies..."
	cd server && dart pub get

build:
	@echo "Building server..."
	cd server && dart compile exe bin/main.dart -o bin/nexusagent

run:
	@echo "Starting NexusAgent..."
	cd server && dart run src/main.dart

test:
	@echo "Running tests..."
	cd server && dart test

docker-build:
	@echo "Building Docker image..."
	cd docker && docker build -t nexusagent/server:latest -f Dockerfile ..

docker-up:
	@echo "Starting Docker Compose..."
	cd docker && docker-compose up -d

docker-down:
	@echo "Stopping Docker Compose..."
	cd docker && docker-compose down

docker-logs:
	cd docker && docker-compose logs -f

clean:
	@echo "Cleaning..."
	cd server && dart clean
	rm -f server/bin/nexusagent
