FROM golang:1.22-alpine3.21 AS builder
WORKDIR /app
COPY ./cmd /app/cmd
COPY go.mod /app
COPY go.sum /app

RUN go build -o service /app/cmd/service/main.go

FROM alpine:3.21
WORKDIR /app
COPY --from=builder /app/service ./

CMD ["./service"]

EXPOSE 8080 8081
