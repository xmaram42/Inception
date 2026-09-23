*This project has been created as part of the 42 curriculum by maabdulr.*

# Inception

> **Inception** is a Docker-based System Administration project from the 42 curriculum. It deploys a secure WordPress infrastructure composed of **NGINX**, **WordPress (PHP-FPM)** and **MariaDB** using **Docker Compose**, **Docker Secrets** and **persistent volumes**.

---

# 📖 Description

The objective of this project is to build a complete web infrastructure using Docker Compose.

Instead of installing applications directly on the operating system, every service runs inside its own isolated Docker container.

This project consists of three services:

* 🌐 NGINX – Reverse Proxy and HTTPS Web Server
* 📝 WordPress – PHP-FPM Application
* 🗄️ MariaDB – Database Server

The services communicate through a **custom Docker bridge network**, while persistent data is stored using **Docker volumes backed by bind mounts**.

Sensitive information is protected using **Docker Secrets**, while non-sensitive configuration is stored inside **.env**.

The entire infrastructure can be built, stopped and rebuilt using the provided **Makefile**.

---

# 📑 Table of Contents

* [Description](#-description)
* [Project Architecture](#-project-architecture)
* [Docker Workflow](#-docker-workflow)
* [Project Structure](#-project-structure)
* [Services](#-services)
* [Instructions](#-instructions)
* [Makefile Commands](#-makefile-commands)
* [Verification](#-verification)
* [Design Choices](#-design-choices)
* [Technology Comparison](#-technology-comparison)
* [AI Usage](#-ai-usage)
* [Resources](#-resources)
* [Author](#-author)

---

# 🏗️ Project Architecture

```text
                                 HTTPS (443)
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │         NGINX           │
                         │ Reverse Proxy + TLS     │
                         └───────────┬─────────────┘
                                     │
                             FastCGI │ :9000
                                     ▼
                         ┌─────────────────────────┐
                         │      WordPress          │
                         │       PHP-FPM           │
                         └───────────┬─────────────┘
                                     │
                          MariaDB    │ :3306
                                     ▼
                         ┌─────────────────────────┐
                         │        MariaDB          │
                         │      SQL Database       │
                         └─────────────────────────┘


                  Docker Custom Bridge Network
                         ┌─────────────────┐
                         │   inception     │
                         └─────────────────┘


Persistent Data

/home/maabdulr/data/
├── mariadb/
└── wordpress/
```

---

# ⚙️ Docker Workflow

```text
                    make
                      │
                      ▼
             docker compose up
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
 Build Docker Images      Create Network & Volumes
        │                           │
        └─────────────┬─────────────┘
                      ▼
             Start MariaDB
                      │
                      ▼
            Wait Until Ready
                      │
                      ▼
            Start WordPress
                      │
                      ▼
         Download & Configure WordPress
                      │
                      ▼
              Start PHP-FPM
                      │
                      ▼
               Start NGINX
                      │
                      ▼
        https://maabdulr.42.fr
```

---

# 📁 Project Structure

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
│
└── srcs/
    ├── .env
    ├── docker-compose.yml
    │
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── setup.sh
        │
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── nginx.sh
        │
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup.sh
```

---

# 🚀 Services

## 🌐 NGINX

* Reverse Proxy
* TLS/SSL termination
* HTTPS only (Port 443)
* Forwards PHP requests to WordPress through FastCGI

---

## 📝 WordPress

* PHP-FPM application
* Downloads WordPress automatically
* Creates `wp-config.php`
* Installs WordPress
* Creates the administrator account
* Creates a second author account
* Connects to MariaDB

---

## 🗄️ MariaDB

* Stores all WordPress data
* Automatically initializes the database
* Creates the SQL user
* Creates the WordPress database
* Uses Docker Secrets for passwords

---

# 🚀 Instructions

Clone the repository:

```bash
git clone <repository-url>
cd Inception
```

Build the infrastructure:

```bash
make
```

Open the website:

```text
https://maabdulr.42.fr
```

---

# 🛠️ Makefile Commands

| Command       | Description                               |
| ------------- | ----------------------------------------- |
| `make`        | Build images and start all containers.    |
| `make up`     | Start existing containers.                |
| `make down`   | Stop and remove containers.               |
| `make clean`  | Stop the infrastructure.                  |
| `make fclean` | Remove containers, volumes and host data. |
| `make re`     | Completely rebuild the project.           |

---

# ✅ Verification

Check running containers:

```bash
docker ps
```

Check Docker images:

```bash
docker images
```

Check Docker volumes:

```bash
docker volume ls
```

Check Docker networks:

```bash
docker network ls
```

View container logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

---

# 🧠 Design Choices

The project was designed by following the requirements of the 42 Inception subject while applying Docker best practices.

Each service has a **single responsibility** and runs inside its own isolated container.

The containers communicate through a custom **Docker bridge network**, while persistent data is stored outside the containers using **Docker volumes backed by bind mounts**.

Sensitive information is stored using **Docker Secrets**, while non-sensitive configuration is stored inside an **environment file (.env)**.

---

## Why Docker?

Docker allows applications to run inside isolated containers instead of installing them directly on the operating system.

### Advantages

* Lightweight virtualization.
* Fast startup.
* Reproducible environments.
* Easy deployment.
* Independent services.
* Simplified maintenance.

---

## Why Three Separate Containers?

Each service performs only one task.

| Container     | Responsibility                            |
| ------------- | ----------------------------------------- |
| **NGINX**     | Handles HTTPS requests and reverse proxy. |
| **WordPress** | Runs the PHP application using PHP-FPM.   |
| **MariaDB**   | Stores all website data.                  |

Separating the services provides:

* Better security.
* Easier debugging.
* Independent updates.
* Better scalability.
* Cleaner architecture.

---

## Why Docker Secrets?

Sensitive information should never be stored inside the source code or Docker images.

Docker Secrets securely provide confidential data to containers through files located in:

```text
/run/secrets/
```

Secrets used in this project:

* MariaDB Root Password
* MariaDB User Password
* WordPress Administrator Password
* WordPress Author Password

---

## Why Environment Variables?

Environment variables store configuration that is **not sensitive**.

Examples include:

* Domain name
* Database name
* Database username
* WordPress usernames
* Email addresses

Keeping configuration outside the source code makes the infrastructure easier to configure on different systems.

---

# ⚖️ Technology Comparison

## Virtual Machines vs Docker

| Virtual Machine           | Docker                 |
| ------------------------- | ---------------------- |
| Full operating system     | Shares the host kernel |
| Large disk size           | Lightweight            |
| Slow startup              | Fast startup           |
| More memory usage         | Less memory usage      |
| Strong hardware isolation | Process isolation      |

---

## Docker Secrets vs Environment Variables

| Docker Secrets          | Environment Variables             |
| ----------------------- | --------------------------------- |
| Secure storage          | Plain text values                 |
| Stored as mounted files | Stored in the process environment |
| Best for passwords      | Best for configuration            |
| Harder to expose        | Easier to expose accidentally     |

---

## Docker Bridge Network vs Host Network

| Docker Bridge Network                  | Host Network                |
| -------------------------------------- | --------------------------- |
| Containers communicate by service name | Shares the host network     |
| Network isolation                      | No network isolation        |
| Better security                        | Less secure                 |
| Default choice for this project        | Rarely used in this project |

---

## Docker Volumes vs Bind Mounts

| Docker Volumes    | Bind Mounts                    |
| ----------------- | ------------------------------ |
| Managed by Docker | Managed by the host filesystem |
| Portable          | Host-path specific             |
| Easier backups    | Easy to inspect manually       |

This project uses **Docker named volumes** configured with **bind mounts** so the persistent data is stored under:

```text
/home/maabdulr/data/
├── mariadb/
└── wordpress/
```

---

# 🤖 AI Usage

Artificial Intelligence (AI) was used as a learning assistant throughout this project.

AI was used to:

* Explain Docker concepts.
* Explain Linux commands.
* Review Dockerfiles and shell scripts.
* Explain Docker networking, volumes and secrets.
* Review the project against the official subject requirements.
* Improve project documentation.

Every AI-generated explanation or code suggestion was **manually reviewed, tested and understood** before being included in the final project.

---

# 📚 Resources

The following official resources were used during the project:

* Docker Documentation
* Docker Compose Documentation
* NGINX Documentation
* MariaDB Documentation
* WordPress Documentation
* WP-CLI Documentation
* PHP Documentation
* PHP-FPM Documentation
* OpenSSL Documentation

---

# 👤 Author

**42 Abu Dhabi**

**Login:** `maabdulr`

---

# 📄 License

This project was developed as part of the **42 Abu Dhabi Common Core Curriculum** and is intended for educational purposes only.
