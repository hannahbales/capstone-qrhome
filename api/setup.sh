#!/bin/bash
# Copy or symlink your .env file
ln -s ../.env
# Download Prisma for Go.
go get github.com/steebchen/prisma-client-go
go mod download github.com/steebchen/prisma-client-go
# If this folder still exists, kill it.
rm -rf ./db
# Generate ORM and push it to database.
go run github.com/steebchen/prisma-client-go db push
# Grab dependencies
go get -t ./...
