# ==========================================
# STAGE 1: Build the GoWA Binary
# ==========================================
FROM golang:1.21-alpine AS builder

# Install C bindings required by SQLite
RUN apk add --no-cache gcc musl-dev

WORKDIR /app

# Download dependencies first (this caches them for faster future builds)
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the GoWA source code
COPY . .

# Build the Go application with CGO enabled
RUN CGO_ENABLED=1 GOOS=linux go build -o gowa-app .

# ==========================================
# STAGE 2: Create the Lightweight Runner Image
# ==========================================
FROM alpine:latest

# Install basic certificates and timezone data (required for secure HTTPS webhooks)
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Create a specific directory for persistent data
RUN mkdir -p /app/data

# Copy the compiled binary and config file from the builder stage
COPY --from=builder /app/gowa-app .
COPY --from=builder /app/config.yaml . 

# Explicitly set Render's default port (though Render will inject $PORT automatically)
EXPOSE 10000

# Command to run the application
CMD ["./gowa-app"]
