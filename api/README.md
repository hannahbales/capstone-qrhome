# QRHome - API
A backend service built with Go, Prisma, and PostgreSQL, designed for compatibility with Vercel Serverless Functions while also supporting containerized production deployments.
This API powers the core functionality of QRHome, including authentication flows, case worker features, and secure data operations.

## Getting Started
**You must start the postgres container before starting these steps**

[Get Go](https://go.dev/doc/install) (v1.22.x^)

To setup the project for development, you need to do that following things:
1. Download Prisma for Go
2. Generate/Push schema to Postgres
3. Grab dependencies

Make sure your `../.env` file is setup.

## Environment Setup (Manual)
```bash
# Copy or symlink your .env file
ln -s ../.env
# Download Prisma for Go.
go get github.com/steebchen/prisma-client-go
go mod download github.com/steebchen/prisma-client-go
# Generate ORM and push it to database.
go run github.com/steebchen/prisma-client-go db push
# Grab dependencies
go get -t ./...
```
## Environment Setup (Automatic)
Running the `setup.sh` script does the above steps, however, sometimes it is finicky. So the first time the environment is setup, it is best to do so manually:

```bash
./setup.sh
```

## Run the API
To run the API, use the following command:

```bash
go run ./core/
```

## Modules
### `/handler.go`
The handler module is for Vercel Serverless Functions. It redirects http traffic to
our primary handlers.

### `/core/main.go`
The main module is the standalone application version of the API meant to run in development
and in the production container. This serves our primary server on a provided port.

### `/core/server/server.go`
The server module handles our actual endpoints and the lifetime of the echo server and route handlers.

## API Documentation
The following is a crude representation of the API.

#### Example Endpoints
| Endpoint | Method | Parameters | Description |
| - | - | - | - |
| / | `GET` | - | Test endpoint that returns "Hello World" |
| `/api/push` | `POST` | `message=string` | Pushes a new message to the database. |
| `/api/all` | `GET` | - | Gets all messages on the database. |

## Resources
- [Golang - Getting started with Go](https://go.dev/doc/tutorial/getting-started)
- [Echo - Docs](https://echo.labstack.com/docs/quick-start)