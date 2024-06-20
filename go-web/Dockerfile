FROM golang:1.21.0-alpine3.18 AS builder
WORKDIR /app
COPY ./cmd /app/cmd
RUN ls /app/cmd
COPY go.mod /app
COPY go.sum /app


RUN go build -o go-web /app/cmd/service/main.go

FROM alpine:3.18

COPY --from=builder /app/go-web ./

RUN apk --no-cache add curl

CMD ["./go-web"]
