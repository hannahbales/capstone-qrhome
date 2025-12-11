#!/bin/bash
if docker-compose --profile prod build; then
    printf "\n\033[92;1m\tBuild Passed\033[0m\n"
    exit 0
else
    printf "\n\033[91;1m\tBuild Failed\033[0m\n"
    exit 1
fi
