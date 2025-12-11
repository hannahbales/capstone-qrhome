#!/bin/bash
cd api
if go test -v ./...; then
    printf "\n\033[92;1m\tGo Unit Tests Passed\033[0m\n\n"
else
    printf "\n\033[91;1m\tGo Unit Tests Failed\033[0m\n\n"
    exit 1
fi

cd ../app

if flutter test; then
    printf "\n\033[92;1m\tFlutter Unit Tests Passed\033[0m\n\n"
    exit 0
else
    printf "\n\033[91;1m\tFlutter Unit Tests Failed\033[0m\n\n"
    exit 2
fi

