# Multi-stage Dockerfile
# Customize for your tech stack

# =============================================================================
# Go Example
# =============================================================================

# Build stage
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /build

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build args for version injection
ARG GIT_COMMIT=unknown
ARG BUILD_TIME=unknown
ARG VERSION=dev

# Build with version info
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.Version=${VERSION} -X main.CommitHash=${GIT_COMMIT} -X main.BuildTime=${BUILD_TIME}" \
    -o server ./cmd/server

# Runtime stage
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

# Create non-root user
RUN adduser -D -u 1000 app
USER app

WORKDIR /app

COPY --from=builder /build/server /app/server

EXPOSE 8080

ENTRYPOINT ["/app/server"]

# =============================================================================
# Python Example (uncomment and customize)
# =============================================================================

# FROM python:3.12-slim
#
# WORKDIR /app
#
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
#
# COPY . .
#
# RUN useradd -m -u 1000 app
# USER app
#
# EXPOSE 8080
#
# CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

# =============================================================================
# Node.js Example (uncomment and customize)
# =============================================================================

# FROM node:20-alpine AS builder
#
# WORKDIR /app
#
# COPY package*.json ./
# RUN npm ci
#
# COPY . .
# RUN npm run build
#
# FROM node:20-alpine
#
# WORKDIR /app
#
# COPY package*.json ./
# RUN npm ci --production
#
# COPY --from=builder /app/dist ./dist
#
# RUN adduser -D -u 1000 app
# USER app
#
# EXPOSE 8080
#
# CMD ["node", "dist/index.js"]
