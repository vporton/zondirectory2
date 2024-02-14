#!/usr/bin/make -f

# For `. .env` to work, even if /bin/sh is Dash:
SHELL=/bin/bash

NETWORK=local
FOUNDER = $(shell dfx identity get-principal)

.PHONY: install-backend
install-backend:
	dfx install main

.PHONY: install-frontend
install-frontend:
	dfx install frontend

.PHONY: build
build: build-frontend

.PHONY: deploy
deploy: deploy-frontend

.PHONY: deploy-backend
deploy-backend: ic_eth compile-my-wasm deploy-main upgrade-partitions

.PHONY: upgrade-partitions
upgrade-partitions:
	npx ts-node scripts/upgrade-candb.ts
	npx ts-node scripts/upgrade-nacdb.ts

.PHONY: deploy-main
deploy-main: ic_eth
	dfx deploy --network $(NETWORK) main
	dfx generate
	env -i scripts/read-env.sh

.PHONY: compile-my-wasm
compile-my-wasm: CanDBPartition.wasm NacDBPartition.wasm

.PHONY: CanDBPartition.wasm
CanDBPartition.wasm: ic_eth
	. .env && moc `mops sources` --actor-idl ./src/ic_eth --actor-alias ic_eth $$CANISTER_ID_ic_eth src/storage/CanDBPartition.mo
#	. .env && moc `mops sources` --actor-idl .dfx/local/lsp --actor-alias ic_eth $$CANISTER_ID_ic_eth src/storage/CanDBPartition.mo

.PHONY: NacDBPartition.wasm
NacDBPartition.wasm:
	moc `mops sources` src/storage/NacDBPartition.mo

.PHONY: ic_eth
ic_eth:
	dfx deploy ic_eth

.PHONY: deploy-frontend
deploy-frontend: compile-my-wasm do-deploy-frontend upgrade-partitions

# FIXME: VERY slow!!
.PHONY: do-deploy-frontend
do-deploy-frontend: deploy-main
	dfx deploy --network $(NETWORK) frontend

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister --network $(NETWORK) call main init '()'
	. .env && dfx canister call --network $(NETWORK) payments init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\" })"
	. .env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"
	. .env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	. .env && dfx canister call --network $(NETWORK) order init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	mainItem=`dfx canister call --network $(NETWORK) main createItemData \
	  '(record { price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { communalCategory = null } })'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
