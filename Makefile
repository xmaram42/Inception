LOGIN = maabdulr
DATA_DIR = /home/$(LOGIN)/data
COMPOSE = docker compose -f srcs/docker-compose.yml

all:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up --build -d

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down --remove-orphans

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down -v --remove-orphans
	docker run --rm -v $(DATA_DIR):/data debian:bullseye sh -c "rm -rf /data/mariadb /data/wordpress"

re: fclean all

.PHONY: all up down clean fclean re
