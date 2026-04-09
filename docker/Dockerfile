FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

COPY tesseract/ ./tesseract/
COPY certificate-transparency-go/ ./certificate-transparency-go/

COPY cmd/ ./ct-monitor/cmd/
COPY go.mod go.sum ./ct-monitor/
COPY scripts/ ./ct-monitor/scripts/

# Build indexer and api
WORKDIR /app/ct-monitor
RUN go mod tidy
RUN go build -o /bin/indexer ./cmd/indexer
RUN go build -o /bin/api ./cmd/api

# Build TesseraCT server
WORKDIR /app/tesseract
RUN go mod tidy
RUN go build -o /bin/tesseract-bin ./cmd/tesseract/aws

# Build preloader
WORKDIR /app/certificate-transparency-go
RUN [ -f go.mod ] && go mod tidy || true
RUN go build -o /bin/preloader_bin ./preload/preloader

# STAGE 2: Runtime
FROM alpine:latest
RUN apk add --no-cache ca-certificates bash jq curl
WORKDIR /app
COPY --from=builder /bin/ /usr/local/bin/

COPY --from=builder /app/ct-monitor/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 8080
