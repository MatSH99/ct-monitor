FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

COPY tesseract/ ./tesseract/
COPY ct-monitor/ ./ct-monitor/
COPY certificate-transparency-go/ ./certificate-transparency-go/

# Build indexer and api
WORKDIR /app/ct-monitor
RUN go mod tidy
RUN go build -o /bin/indexer ./cmd/indexer/main.go
RUN go build -o /bin/api ./cmd/api/main.go

# Build TesseraCT server
WORKDIR /app/tesseract
RUN go build -o /bin/tesseract-bin ./cmd/tesseract/aws/main.go

# Build preloader
WORKDIR /app/certificate-transparency-go
RUN go build -o /bin/preloader_bin ./preload/preloader/preloader.go

# STAGE 2: Runtime
FROM alpine:latest
RUN apk add --no-cache ca-certificates bash jq curl

WORKDIR /app

# Copy binaries
COPY --from=builder /bin/ /usr/local/bin/

# Copy scripts
COPY ct-monitor/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Expose API port
EXPOSE 8080
