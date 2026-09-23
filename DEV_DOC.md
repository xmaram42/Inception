# Developer Documentation

## Overview

This document explains the internal structure and development workflow of the Inception project.

The infrastructure contains three custom Docker services:

- NGINX
- WordPress with PHP-FPM
- MariaDB

Each service runs in its own container and is built from `debian:bullseye`.

---

## Architecture

```text
Browser
   │
   │ HTTPS :443
   ▼
NGINX
   │
   │ FastCGI :9000
   ▼
WordPress
   │
   │ MariaDB :3306
   ▼
MariaDB
```

Only NGINX is exposed to the host.

WordPress and MariaDB communicate only through the internal Docker network.

---

## Project Structure

```text
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

Each service directory contains:

```text
Dockerfile
conf/
tools/
.dockerignore
```

---

## Docker Compose

The Compose file defines:

- Three services
- One custom bridge network
- Two persistent volumes
- Three Docker Secrets

Services:

```text
mariadb
wordpress
nginx
```

Network:

```text
inception
```

Volumes:

```text
mariadb
wordpress
```

---

## Service Communication

| Source      | Destination | Port | Protocol |
|-------------|-------------|------|----------|
| Browser     | NGINX       | 443  | HTTPS    |
| NGINX       | WordPress   | 9000 | FastCGI  |
| WordPress   | MariaDB     | 3306 | MariaDB  |

Docker internal DNS allows containers to use service names:

```text
wordpress:9000
mariadb:3306
```

No container IP address is hardcoded.

---

## Environment Variables

Non-sensitive configuration is stored in:

```text
srcs/.env
```

Examples:

```text
DOMAIN_NAME
MYSQL_DATABASE
MYSQL_USER
WP_ADMIN_USER
WP_ADMIN_EMAIL
WP_USER
WP_USER_EMAIL
```

Passwords are not stored in `.env`.

---

## Docker Secrets

Sensitive values are stored in:

```text
secrets/
```

Docker mounts them inside containers under:

```text
/run/secrets/
```

The project uses secrets for:

- MariaDB root password
- MariaDB user password
- WordPress administrator password
- WordPress second-user password

Example:

```bash
DB_PASSWORD=$(cat /run/secrets/db_password)
```

---

## Persistent Storage

MariaDB data is stored at:

```text
/home/maabdulr/data/mariadb
```

WordPress data is stored at:

```text
/home/maabdulr/data/wordpress
```

Container mount points:

| Service     | Container Path      |
|-------------|---------------------|
| MariaDB     | `/var/lib/mysql`    |
| WordPress   | `/var/www/html`     |
| NGINX       | `/var/www/html`     |

The WordPress volume is shared with NGINX so NGINX can serve the website files.

---

## MariaDB Service

The MariaDB Dockerfile:

1. Uses Debian Bullseye.
2. Installs MariaDB Server.
3. Copies the configuration file.
4. Copies the initialization script.
5. Runs the script as the entrypoint.

MariaDB listens on:

```text
0.0.0.0:3306
```

Port 3306 is internal and is not published to the host.

The startup script:

```text
Reads secrets
    ↓
Initializes database files
    ↓
Starts MariaDB temporarily
    ↓
Creates the database and user
    ↓
Grants permissions
    ↓
Stops the temporary server
    ↓
Starts MariaDB in foreground
```

The final process is:

```bash
exec mysqld --user=mysql
```

---

## WordPress Service

The WordPress Dockerfile installs:

- PHP-FPM
- PHP MySQL support
- MariaDB client
- Curl
- WP-CLI

PHP-FPM listens on:

```text
0.0.0.0:9000
```

The port remains internal.

The startup script:

```text
Reads secrets
    ↓
Waits for MariaDB
    ↓
Downloads WordPress
    ↓
Creates wp-config.php
    ↓
Installs WordPress
    ↓
Creates the second user
    ↓
Starts PHP-FPM
```

The script waits for MariaDB because:

```text
depends_on
```

controls startup order only. It does not guarantee service readiness.

The final process is:

```bash
exec php-fpm7.4 -F
```

---

## NGINX Service

The NGINX Dockerfile:

1. Uses Debian Bullseye.
2. Installs NGINX and OpenSSL.
3. Copies the NGINX configuration.
4. Copies the startup script.
5. Exposes port 443.
6. Starts NGINX in foreground mode.

NGINX listens on:

```text
443
```

It forwards PHP requests to:

```text
wordpress:9000
```

TLS configuration allows:

```text
TLSv1.2
TLSv1.3
```

The final process is:

```bash
exec nginx -g "daemon off;"
```

---

## Foreground Processes

Each container must keep one main process running.

| Container | Main Process                    |
|-----------|---------------------------------|
| MariaDB   | `mysqld`                        |
| WordPress | `php-fpm7.4 -F`                 |
| NGINX     | `nginx -g "daemon off;"`        |

Using `exec` allows Docker signals to reach the main service correctly.

---

## Startup Order

```text
MariaDB
   ↓
WordPress
   ↓
NGINX
```

WordPress includes its own readiness check for MariaDB.

---

## Makefile Workflow

Running:

```bash
make
```

performs:

```text
Create data directories
        ↓
Build Docker images
        ↓
Create network and volumes
        ↓
Start all containers
```

Main commands:

| Command       | Purpose                              |
|---------------|--------------------------------------|
| `make`        | Build and start the project.         |
| `make up`     | Start existing containers.           |
| `make down`   | Stop containers.                     |
| `make fclean` | Remove containers, data and volumes. |
| `make re`     | Fully rebuild the project.           |

---

## Development Workflow

After changing a Dockerfile or copied configuration:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

After changing only Compose configuration:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

For a complete rebuild:

```bash
make re
```

---

## Debugging

Check container status:

```bash
docker ps -a
```

Read logs:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

Enter a container:

```bash
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

Check internal DNS:

```bash
docker exec wordpress getent hosts mariadb
docker exec nginx getent hosts wordpress
```

Inspect the network:

```bash
docker network inspect srcs_inception
```

Inspect volumes:

```bash
docker volume ls
```

---

## Security Rules

The implementation follows these rules:

- Only port 443 is published.
- MariaDB remains internal.
- PHP-FPM remains internal.
- Passwords use Docker Secrets.
- `.env` stores only non-sensitive data.
- TLS 1.2 and TLS 1.3 are enabled.
- Services use separate containers.
- Containers communicate through a private network.
- No service uses a pre-built WordPress, NGINX or MariaDB image.
- No infinite loop or `tail -f` is used to keep containers alive.

---

## Final Flow

```text
Makefile
   ↓
Docker Compose
   ↓
Build custom images
   ↓
Create network and volumes
   ↓
Initialize MariaDB
   ↓
Install WordPress
   ↓
Start PHP-FPM
   ↓
Start NGINX
   ↓
Serve the website through HTTPS
```