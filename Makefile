#!/usr/bin/make -f

# For `. .env` to work, even if /bin/sh is Dash:
SHELL=/bin/bash

NETWORK=local
FOUNDER = $(shell dfx identity get-principal)

BACKEND_CANISTERS = main order personhood payments pst CanDBIndex NacDBIndex ic_eth internet_identity

.PHONY: deploy
deploy: deploy-frontend

.PHONY: build
build: build-frontend

.PHONY: first-build
first-build: CanDBPartition.wasm NacDBPartition.wasm
	mops i
# `frontend` is needed for ~/.dfx/local/canisters/frontend/assetstorage.did used by `dfx generate`:
	dfx deploy frontend
	env -i scripts/read-env.sh
	dfx build internet_identity
	dfx generate main

.PHONY: install-backend
install-backend:
	for i in $(BACKEND_CANISTERS); do \
	  dfx canister install --network $(NETWORK) --mode=auto $$i; \
	done

.PHONY: install-frontend
install-frontend: install-backend
	dfx canister install --network $(NETWORK) --mode=auto frontend

.PHONY: build-backend
build-backend: do-build-backend CanDBPartition.wasm NacDBPartition.wasm

.PHONY: build-frontend
build-frontend: do-build-frontend CanDBPartition.wasm NacDBPartition.wasm

.PHONY: do-build-backend
do-build-backend:
	dfx build main

.PHONY: do-build-frontend
do-build-frontend:
	npm run build
	dfx build frontend

.PHONY: CanDBPartition.wasm
CanDBPartition.wasm:
	moc `mops sources` src/storage/CanDBPartition.mo

.PHONY: NacDBPartition.wasm
NacDBPartition.wasm:
	moc `mops sources` src/storage/NacDBPartition.mo

.PHONY: deploy-backend
deploy-backend: build-backend install-backend upgrade-partitions

.PHONY: deploy-frontend
deploy-frontend: build-frontend install-frontend upgrade-partitions

.PHONY: upgrade-partitions
upgrade-partitions:
	npx ts-node scripts/upgrade-candb.ts
	npx ts-node scripts/upgrade-nacdb.ts

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister --network $(NETWORK) call main init '()'
# FIXME: Which canisters to allow calls?
	. .env && dfx canister call --network $(NETWORK) payments init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\" })"
	. .env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"
	. .env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	. .env && dfx canister call --network $(NETWORK) order init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	mainItem=`dfx canister call --network $(NETWORK) main createItemData \
	  '(record { communal = true; price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { folder = null } })'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
