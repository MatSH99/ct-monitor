FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git gcc musl-dev

WORKDIR /app

# 1. Copia i sottomoduli (che Docker vede come cartelle locali)
COPY tesseract/ ./tesseract/
COPY certificate-transparency-go/ ./certificate-transparency-go/

# 2. Copia il codice del monitor (che è nella cartella corrente) 
# dentro una sottocartella /app/ct-monitor per mantenere i tuoi path di build
COPY cmd/ ./ct-monitor/cmd/
COPY go.mod go.sum ./ct-monitor/
COPY scripts/ ./ct-monitor/scripts/

# --- Il resto rimane uguale ---
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

# STAGE 2: Runtime (Invariato)
FROM alpine:latest
RUN apk add --no-cache ca-certificates bash jq curl
WORKDIR /app
COPY --from=builder /bin/ /usr/local/bin/

# Correzione script: ora sono in /app/ct-monitor/scripts nello stage builder
COPY --from=builder /app/ct-monitor/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 8080
