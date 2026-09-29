FROM docker.io/golang:1.27.1-trixie AS build

WORKDIR /opt/app

# Copy go.mod and go.sum first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the test sources and resources
COPY ./ ./

RUN CGO_ENABLED=0 go test -c -o /functional.test

FROM scratch
WORKDIR /opt/app
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /functional.test /functional.test
COPY features/ ./features/
USER 65532:65532
ENTRYPOINT ["/functional.test", "-test.v"]
