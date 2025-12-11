# QRHome - BSU Senior Capstone
QRHome is a full-stack, cross-platform solution designed to streamline the housing application process for individuals experiencing homelessness. It is designed to securely store universal application information and generate a shareable QR code, allowing case workers and housing providers to quickly access a client’s information across multiple programs.

Built over multiple months as a Boise State University senior capstone project, this system was developed in collaboration with real community sponsors. The project emphasizes security, accessibility, and real-world usability, with features like email-based two-factor authentication, encrypted data, and a responsive onboarding flow.

The project was successfully delivered, documented, and handed off to the sponsors at the end of the semester.

## Features
Registration

- New users can access a signup form upon entering application
- New users can select role during registration
- New users can only sign up as admin with an authorized email address

Account

- Users can log into their account.
- Users can delete their account.
- Case Workers are promted (required) to verify their login via an emailed 2 factor authentication.
- Clients can opt to use emailed 2 factor authentication.
- Admins can view all users on the platform.

Data Management

- Clients can add and update their personal information.
- Clients can add multiple family members to their household.
- Clients can store their financial information, per person and for the household.
- Clients can upload supporting documents required for housing applications.
- Clients can generate QR code containing personal information for easy sharing.
- Clients can see who is linked to their account.
- Clients can revoke links to their account.
- Clients can regenerate their QR code for security reasons. 
- Case Workers can revoke links to Clients.
- Clients can view and delete their uploaded documents.
- Clients can view an overview of all their information.

## My Contributions
As one of the four developers on the team, I contributed mostly to the backend of the project. Though I contributed in many areas of the project, my main focus was:

User Two Factor Authentication: 

- I implemented the full 2FA flow across the backend API, email service, and frontend UI. This included designing endpoints, sending and storing secure email verification codes, and creating the user-facing confirmation experience.

## Tech Stack

Backend:
  - Go (Golang)
  - Prisma
  - PostgreSQL
  - SMTP (Gmail)

Frontend:
  - Flutter / Dart

Infrastructure:
- Docker, Docker Compose

## Getting Started
Things you'll need:
- [Docker Desktop](https://www.docker.com/get-started/)
- [Docker Compose](https://docs.docker.com/compose/install/)
  - This should be installed by default with Docker Desktop, but occasionally it doesn't.

## Production Instructions
To launch the docker compose for production, use the following commands:

```bash
# Compiles API/Webserver into separate image
docker compose --profile prod build
# Starts API/Webserver and Postgres containers
docker compose --profile prod up -d
```

See environment variables for configuration.

## Development Instructions
To launch the postgres instance, use the dev profile:

```bash
docker compose --profile dev up -d
```

See environment variables for configuration.

Head to the [API README](/api/README.md) for how to launch the API.

## Environment Variables
Here is a template for your `.env` file:

```
POSTGRES_USER=<DB Username>
POSTGRES_PASSWORD=<DB Password>
DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_USER}"

API_PORT=3456
HOST_PORT=<Host Port, defaults to 80>
HTML_ROOT=<Root of HTML, default is nothing>

SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="<gmail@gmail.com>"
SMTP_PASS="<Email Password>"
```

Have your `.env` file located in the root of the project.

## License
SPDX-License-Identifier: [MPL-2.0](/LICENSE)
