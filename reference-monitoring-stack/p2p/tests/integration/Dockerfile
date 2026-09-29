FROM docker.io/golang:1.27.1-trixie AS build

WORKDIR /opt/app

COPY go.mod ./
RUN go mod download

COPY ./ ./

RUN CGO_ENABLED=0 go test -c -o /integration.test

FROM scratch
WORKDIR /opt/app
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /integration.test /integration.test
USER 65532:65532
ENTRYPOINT ["/integration.test", "-test.v"]
