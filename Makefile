#!/usr/bin/make -f

SHELL = /bin/bash
include metaconfig.mk

NETWORK = local

FOUNDER = $(shell dfx identity --network $(NETWORK) get-principal)

.PHONY: all
all: deploy init

.PHONY: deploy
deploy: compile-candbpart compile-nacdbpart
	test "$(NETWORK)" != local && git checkout stable
	cleanup() { rm -f src/libs/configs/stage/*; test -e .env && cp -f .env .env.$(NETWORK); } && \
	  trap "cleanup" EXIT && \
	  mkdir -p src/libs/configs/stage && \
	  cp -f $(CONFIGS_REPO)/$(NETWORK)/* src/libs/configs/stage/ && \
	  cp .env.$(NETWORK) .env && \
	  dfx deploy --yes --network $(NETWORK) ic_eth && \
	  dfx generate -v CanDBPartition && \
	  dfx generate -v NacDBPartition && \
	  dfx generate -v main && \
	  dfx generate -v items && \
	  dfx generate -v personhood && \
	  dfx deploy personhood && \
	  python3 node_modules/passport_client_dfinity/scripts/update-canisters.py && \
	  dfx deploy --yes --network $(NETWORK) -v frontend && \
	  export DFX_NETWORK=$(NETWORK) && \
	    npx ts-node scripts/upgrade-candb.ts $(NETWORK) && \
	    npx ts-node scripts/upgrade-nacdb.ts $(NETWORK)

.PHONY: generate
generate:
	cleanup() { rm -f src/libs/configs/stage/*; test -e .env && cp -f .env .env.$(NETWORK); } && \
	  trap "cleanup" EXIT && \
	  mkdir -p src/libs/configs/stage && \
	  cp -f $(CONFIGS_REPO)/$(NETWORK)/* src/libs/configs/stage/ && \
	  cp .env.$(NETWORK) .env && \
	  dfx generate -v CanDBPartition && \
	  dfx generate -v NacDBPartition && \
	  dfx generate --network $(NETWORK) -v

.PHONY: compile-candbpart
compile-candbpart:
	mkdir -p .dfx/$(NETWORK)/canisters/CanDBPartition
	`dfx cache show`/moc -o .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm \
	  `mops sources` src/storage/CanDBPartition.mo

.PHONY: compile-nacdbpart
compile-nacdbpart:
	mkdir -p .dfx/$(NETWORK)/canisters/NacDBPartition
	`dfx cache show`/moc -o .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm \
	  `mops sources` src/storage/NacDBPartition.mo

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
