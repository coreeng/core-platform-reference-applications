FROM docker.io/golang:1.26.0-trixie

WORKDIR /opt/app

# Copy go.mod and go.sum first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application
COPY ./ ./

# Pre-compile test dependencies
RUN go test -c -o /dev/null

CMD ["go", "test", "-v"]
