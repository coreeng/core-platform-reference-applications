FROM docker.io/golang:1.26.3-trixie

WORKDIR /opt/app

COPY go.mod ./
RUN go mod download

COPY ./ ./

RUN go test -c -o /tmp/integration.test && rm /tmp/integration.test

CMD ["go", "test", "-v", "./..."]
