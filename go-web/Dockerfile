FROM docker.io/golang:1.26.2-alpine3.23 AS build
WORKDIR /app
COPY ./cmd /app/cmd
COPY go.mod /app
COPY go.sum /app

RUN go build -o service /app/cmd/service/main.go

FROM docker.io/alpine:3.23.4
WORKDIR /app
COPY --from=build /app/service ./

CMD ["./service"]

EXPOSE 8080 8081
