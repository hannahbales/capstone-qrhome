#!/bin/bash
# This is meant to be run inside the docker container.
# Not for normal development.
go run github.com/steebchen/prisma-client-go db push
go run core/main.go
