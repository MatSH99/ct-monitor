#!/bin/bash
set -e

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

echo "Building all components..."

# Build Server from fork
cd ../tesseract
go build -o "$PROJECT_ROOT/bin/ct_server" ./cmd/tesseract/aws

# Build Preloader from fork
cd ../certificate-transparency-go
go build -o "$PROJECT_ROOT/bin/preloader" ./preload/preloader/preloader.go

cd "$PROJECT_ROOT"
go build -o ./bin/api ./cmd/api/main.go
go build -o ./bin/indexer ./cmd/indexer/main.go

echo "All binaries built successfully in $PROJECT_ROOT/bin/"
