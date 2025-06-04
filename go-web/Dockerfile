FROM golang:1.24.3-alpine3.22 AS builder
WORKDIR /app
COPY ./cmd /app/cmd
COPY go.mod /app
COPY go.sum /app

RUN go build -o service /app/cmd/service/main.go

FROM alpine:3.22
WORKDIR /app
COPY --from=builder /app/service ./

CMD ["./service"]

EXPOSE 8080 8081
