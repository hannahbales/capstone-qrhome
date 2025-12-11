# Build Stage
FROM instrumentisto/flutter:latest AS builder
WORKDIR /usr/src/out

ARG FLUTTER_BASE_URL=

COPY ./app ./
RUN flutter build web --base-href ${FLUTTER_BASE_URL}/

# Run Stage
FROM golang:1.23
WORKDIR /usr/src/app

COPY ./api/ .
COPY .env* .
COPY --from=builder /usr/src/out/build/web ./app

# RUN go mod download
RUN go get github.com/steebchen/prisma-client-go
RUN go mod download github.com/steebchen/prisma-client-go
RUN go run github.com/steebchen/prisma-client-go generate
RUN go get -t ./...
RUN go mod verify
RUN go build -v -o /usr/local/bin/api ./core/main.go

CMD ["./start_api.sh"]
