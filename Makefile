#!/usr/bin/make -f

SHELL = /bin/bash

deploy:

include metaconfig.mk
include deps.mk

NETWORK = local

FOUNDER = $(shell dfx identity --network $(NETWORK) get-principal)

.PHONY: deps
deps:
	dfx rules -o deps.mk

.PHONY: all
all: deploy init

.PHONY: deploy
deploy: canister@CanDBPartition canister@NacDBPartition
	current="$$(git branch --show-current)"; \
	  cleanup() { \
	    rm -f src/libs/configs/stage/* src/frontend/assets/.well-known/ii-alternative-origins; \
	    test -e .env && cp -f .env .env.$(NETWORK); \
	    git checkout "$$current"; \
	  } && \
	  trap "cleanup" EXIT && \
	  if test "$(NETWORK)" != local; then git checkout stable; fi; \
	  if test "$(NETWORK)" = local; then \
	    rm -f src/frontend/assets/.well-known/ii-alternative-origins; \
	  else \
	    cp -f src/frontend/ii-alternative-origins src/frontend/assets/.well-known/; \
	  fi; \
	  mkdir -p src/libs/configs/stage && \
	  cp -f $(CONFIGS_REPO)/$(NETWORK)/* src/libs/configs/stage/ && \
	  cp .env.$(NETWORK) .env && \
	  make deploy@frontend && \
	  export DFX_NETWORK=$(NETWORK) && \
	    npx ts-node scripts/upgrade-candb.ts $(NETWORK) && \
	    npx ts-node scripts/upgrade-nacdb.ts $(NETWORK); \
	  if test "$(NETWORK)" != local; then echo "!!!UPDATED FROM stable BRANCH!!!"; fi

.PHONY: fabricate-cycles
	test "$(NETWORK)" = local && dfx ledger fabricate-cycles --amount 100000000 --canister main

.PHONY: init
init: fabricate-cycles init-main init-call init-battery init-CanDBIndex init-NacDBIndex init-items init-createItemData

.PHONY: init-main
init-main:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	dfx canister --network $(NETWORK) call main init '()'

.PHONY: init-CanDBIndex
init-CanDBIndex:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_BATTERY\"; principal \"$$CANISTER_ID_ITEMS\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"

.PHONY: init-NacDBIndex
init-NacDBIndex:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_BATTERY\"; principal \"$$CANISTER_ID_ITEMS\" })"

.PHONY: init-items
init-items:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) items init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-users
init-users:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) users init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-call
init-call:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) call init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ITEMS\"; })"

.PHONY: init-battery
init-battery:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	. ./.env && dfx canister call --network $(NETWORK) battery init "(vec { principal \"$(FOUNDER)\"; })"

.PHONY: init-createItemData
init-createItemData:
	cleanup() { test -e .env && cp -f .env .env.$(NETWORK); } && \
	cp -f .env.$(NETWORK) .env && \
	mainItem=`dfx canister call --network $(NETWORK) items createItemData \
	  '(record { data = record{price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { folder = null }}; communal = true }, "")'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
