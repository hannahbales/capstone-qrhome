#!/bin/bash
docker compose --profile dev down
rm -rf api/postgres_data
docker compose --profile dev up -d
cd api
printf "\033[2mWaiting for db to start...\033[0m"
sleep 5
if go run github.com/steebchen/prisma-client-go db push; then
    printf "\033[1;92m\tDatabase Refreshed\033[0m\n\n"
else
    printf "\033[1;91m\tFailure\033[0m\n\n"
fi

