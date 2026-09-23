# User Documentation

## Overview

This document explains how to install, start, use, stop and troubleshoot the Inception infrastructure.

The project runs three Docker services:

- NGINX
- WordPress
- MariaDB

The website is available through HTTPS at:

```text
https://maabdulr.42.fr
```

---

## Requirements

Before starting, make sure the system has:

- Docker
- Docker Compose
- GNU Make
- Git
- A Linux environment or virtual machine

Check Docker:

```bash
docker --version
```

Check Docker Compose:

```bash
docker compose version
```

Check Make:

```bash
make --version
```

---

## Project Installation

Clone the repository:

```bash
git clone <repository-url>
```

Enter the project directory:

```bash
cd Inception
```

---

## Domain Configuration

The project uses the domain:

```text
maabdulr.42.fr
```

The domain must point to the machine running the project.

On Linux, edit:

```text
/etc/hosts
```

Add:

```text
127.0.0.1 maabdulr.42.fr
```

When running the project inside a virtual machine, replace `127.0.0.1` with the virtual machine IP address.

Example:

```text
192.168.1.50 maabdulr.42.fr
```

---

## Environment Configuration

The non-sensitive project configuration is stored in:

```text
srcs/.env
```

It contains values such as:

- Domain name
- Database name
- Database username
- WordPress usernames
- WordPress email addresses

Passwords must not be stored inside `.env`.

---

## Secret Files

Create the required secret files inside:

```text
secrets/
```

Required files:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

### `db_root_password.txt`

Contains only the MariaDB root password.

Example:

```text
strong_root_password
```

### `db_password.txt`

Contains only the WordPress database-user password.

Example:

```text
strong_database_password
```

### `credentials.txt`

Contains the WordPress passwords.

Example:

```text
WP_ADMIN_PASSWORD=strong_admin_password
WP_USER_PASSWORD=strong_user_password
```

Do not commit real password files to Git.

---

## Starting the Project

Build the images and start all containers:

```bash
make
```

The Makefile creates the persistent-data directories and runs Docker Compose.

Check the running containers:

```bash
docker ps
```

Expected containers:

```text
nginx
wordpress
mariadb
```

---

## Accessing WordPress

Open a browser and visit:

```text
https://maabdulr.42.fr
```

Because the TLS certificate is self-signed, the browser may display a security warning.

Accept the warning to continue.

---

## WordPress Login

Open:

```text
https://maabdulr.42.fr/wp-admin
```

Use the administrator username and password configured in the project.

The project also creates a second WordPress user with the `author` role.

---

## Makefile Commands

| Command        | Description                                      |
|----------------|--------------------------------------------------|
| `make`         | Build images and start the infrastructure.       |
| `make up`      | Start existing containers.                       |
| `make down`    | Stop and remove the containers.                  |
| `make clean`   | Stop the infrastructure.                         |
| `make fclean`  | Remove containers, volumes and persistent data.  |
| `make re`      | Remove and rebuild the complete infrastructure.  |

---

## Stopping the Project

Stop and remove the containers:

```bash
make down
```

The persistent data remains available.

---

## Restarting the Project

Start the existing containers again:

```bash
make up
```

WordPress and MariaDB data should still be present.

---

## Complete Cleanup

Remove containers, volumes and persistent data:

```bash
make fclean
```

This deletes the stored MariaDB and WordPress data.

The next execution of:

```bash
make
```

performs a completely fresh installation.

---

## Rebuilding the Project

Run:

```bash
make re
```

This performs:

```text
fclean
  ↓
complete rebuild
  ↓
fresh installation
```

---

## Checking the Containers

List running containers:

```bash
docker ps
```

List all containers:

```bash
docker ps -a
```

Check the restart policy:

```bash
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' nginx
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' wordpress
docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' mariadb
```

Expected result:

```text
always
```

---

## Viewing Logs

NGINX logs:

```bash
docker logs nginx
```

WordPress logs:

```bash
docker logs wordpress
```

MariaDB logs:

```bash
docker logs mariadb
```

Display the last 30 lines:

```bash
docker logs wordpress --tail=30
```

Follow logs continuously:

```bash
docker logs -f wordpress
```

Press `Ctrl+C` to stop following the logs.

---

## Checking the Docker Network

List networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect srcs_inception
```

The output should show all three containers connected to the same network.

Containers communicate using service names:

```text
nginx
wordpress
mariadb
```

---

## Checking Persistent Volumes

List volumes:

```bash
docker volume ls
```

Inspect the MariaDB volume:

```bash
docker volume inspect mariadb
```

Inspect the WordPress volume:

```bash
docker volume inspect wordpress
```

The persistent host directories are:

```text
/home/maabdulr/data/mariadb
/home/maabdulr/data/wordpress
```

---

## Checking WordPress Users

Enter MariaDB:

```bash
docker exec -it mariadb mysql -u root -p
```

Select the WordPress database:

```sql
USE wordpress;
```

Display the WordPress users:

```sql
SELECT ID, user_login, user_email FROM wp_users;
```

Exit MariaDB:

```sql
exit;
```

---

## Checking HTTPS

Test TLS 1.2:

```bash
openssl s_client \
-connect maabdulr.42.fr:443 \
-tls1_2
```

Test TLS 1.3:

```bash
openssl s_client \
-connect maabdulr.42.fr:443 \
-tls1_3
```

TLS 1.0 should not work:

```bash
openssl s_client \
-connect maabdulr.42.fr:443 \
-tls1
```

---

## Common Problems

### Website does not open

Check that the containers are running:

```bash
docker ps
```

Check the domain configuration in the hosts file.

Check NGINX logs:

```bash
docker logs nginx
```

---

### WordPress cannot connect to MariaDB

Check MariaDB:

```bash
docker logs mariadb
```

Check WordPress:

```bash
docker logs wordpress
```

Confirm both containers are on the same network:

```bash
docker network inspect srcs_inception
```

---

### Port 443 is already in use

Find the process using port 443:

```bash
sudo lsof -i :443
```

Stop the conflicting service before starting the project again.

---

### WordPress users are missing

Check the WordPress logs:

```bash
docker logs wordpress
```

Check the database users:

```sql
USE wordpress;
SELECT ID, user_login FROM wp_users;
```

For a completely fresh installation:

```bash
make fclean
make
```

Warning: this deletes all persistent WordPress and database data.

---

### Permission problems on persistent folders

Check the folder ownership:

```bash
ls -la /home/maabdulr/data
```

Check the MariaDB data:

```bash
ls -la /home/maabdulr/data/mariadb
```

Check the WordPress data:

```bash
ls -la /home/maabdulr/data/wordpress
```

---

## Data Persistence Test

Create a WordPress post or page.

Stop the infrastructure:

```bash
make down
```

Start it again:

```bash
make up
```

Open the website.

The created content should still exist.

This confirms that the persistent volumes work correctly.

---

## Security Notes

- Only port 443 is published.
- Port 9000 remains internal to WordPress.
- Port 3306 remains internal to MariaDB.
- Passwords are read from Docker Secrets.
- `.env` contains only non-sensitive configuration.
- The project uses HTTPS.
- Containers communicate through a private Docker bridge network.

---

## Useful Commands

Enter the NGINX container:

```bash
docker exec -it nginx bash
```

Enter the WordPress container:

```bash
docker exec -it wordpress bash
```

Enter the MariaDB container:

```bash
docker exec -it mariadb bash
```

Leave a container:

```bash
exit
```

---

## Final Verification

Before using or evaluating the project, verify:

- All three containers are running.
- The website opens with HTTPS.
- WordPress contains an administrator and a second user.
- MariaDB stores the WordPress database.
- Data survives container restarts.
- Only port 443 is exposed.
- TLS 1.2 and TLS 1.3 work.
- Passwords are not stored in `.env`.