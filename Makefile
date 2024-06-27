#!/usr/bin/make -f

SHELL = /bin/bash
include metaconfig.mk

NETWORK = local

FOUNDER = $(shell dfx identity --network $(NETWORK) get-principal)

.PHONY: all
all: deploy init

.PHONY: deploy
deploy: compile-candbpart compile-nacdbpart 
	cleanup() { rm -f src/libs/configs/stage/*; mv -f .env .env.$(NETWORK); } && \
	  trap "cleanup" EXIT && \
	  mkdir -p src/libs/configs/stage && \
	  cp -f $(CONFIGS_REPO)/$(NETWORK)/* src/libs/configs/stage/ && \
	  cp .env.$(NETWORK) .env \
	  dfx generate --network $(NETWORK) -v CanDBPartition && \
	  dfx generate --network $(NETWORK) -v NacDBPartition && \
	  dfx deploy --network $(NETWORK) -v frontend && \
	  npx ts-node scripts/upgrade-candb.ts $(NETWORK) && \
	  npx ts-node scripts/upgrade-nacdb.ts $(NETWORK)

.PHONY: generate
generate:
	cleanup() { rm -f src/libs/configs/stage/*; ; mv -f .env .env.$(NETWORK); } && \
	  trap "cleanup" EXIT && \
	  mkdir -p src/libs/configs/stage && \
	  cp -f $(CONFIGS_REPO)/$(NETWORK)/* src/libs/configs/stage/ && \
	  cp .env.$(NETWORK) .env \
	  dfx generate --network $(NETWORK) -v CanDBPartition && \
	  dfx generate --network $(NETWORK) -v NacDBPartition && \
	  dfx generate --network $(NETWORK) -v

compile-candbpart:
	mkdir -p .dfx/$(NETWORK)/canisters/CanDBPartition
	`dfx cache show`/moc -o .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm \
	  `mops sources` src/storage/CanDBPartition.mo

compile-nacdbpart:
	mkdir -p .dfx/$(NETWORK)/canisters/NacDBPartition
	`dfx cache show`/moc -o .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm \
	  `mops sources` src/storage/NacDBPartition.mo

.PHONY: fabricate-cycles
	test "$(NETWORK)" = local && dfx ledger fabricate-cycles --amount 100000000 --canister main

.PHONY: init
init: fabricate-cycles init-main init-battery init-CanDBIndex init-NacDBIndex init-items init-call init-createItemData

.PHONY: init-main
init-main:
	dfx canister --network $(NETWORK) call main init '()'

#	. ./.env && dfx canister call --network $(NETWORK) payments init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\" })"

.PHONY: init-CanDBIndex
init-CanDBIndex:
	. ./.env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_BATTERY\"; principal \"$$CANISTER_ID_ITEMS\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"

.PHONY: init-NacDBIndex
init-NacDBIndex:
	. ./.env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_BATTERY\"; principal \"$$CANISTER_ID_ITEMS\" })"

.PHONY: init-items
init-items:
	. ./.env && dfx canister call --network $(NETWORK) items init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-users
init-users:
	. ./.env && dfx canister call --network $(NETWORK) users init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-call
init-call:
	. ./.env && dfx canister call --network $(NETWORK) call init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ITEMS\"; })"

.PHONY: init-battery
init-battery:
	. ./.env && dfx canister call --network $(NETWORK) battery init "(vec { principal \"$(FOUNDER)\"; })"

.PHONY: init-createItemData
init-createItemData:
	mainItem=`dfx canister call --network $(NETWORK) items createItemData \
	  '(record { data = record{price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { folder = null }}; communal = true }, "")'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
