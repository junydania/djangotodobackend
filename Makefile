PROJECT_NAME ?= todobackend
ORG_NAME ?= odania
REPO_NAME ?= todobackend

DEV_COMPOSE_FILE := docker/dev/docker-compose.yml
REL_COMPOSE_FILE := docker/release/docker-compose.yml

REL_PROJECT := $(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(REL_PROJECT)dev

.PHONY: test build release clean

test: 
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) build
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up agent
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up test

build:
	${INFO} "Building application artifacts..."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${INFO} "Copying artifacts to target folder..."
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/. target
	${INFO} "Testing Complete"

release:
	${INFO} "Building images...."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) build
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up agent
	${INFO} "Collecting static files..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Running database migrations..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) run --rm app manage.py migrate --noinput
	${INFO} "Running acceptance tests..."
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) up test

clean:
	${INFO} "Destroying development environment...."
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) kill
	@ docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) rm -f -v
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) kill
	@ docker-compose -p $(REL_PROJECT) -f $(REL_COMPOSE_FILE) rm -f -v
	@ docker images -q -f dangling=true -f label=application=$(REPO_NAME) | xargs -I ARGS docker rmi -f 
	${INFO} "Clean Complete"


YELLOW := "\e[1 ;33m"
NC := "\e[0m"

#Shell function
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
	printf $(NC)' VALUE

