#!/usr/bin/make -f

ICPRULESDIR = icp-make-rules
include $(ICPRULESDIR)/icp.rules

FOUNDER = $(shell dfx identity get-principal)

MOFILES = $(shell find src/backend src/libs src/storage)
CANISTERS = \
	src/storage/CanDBIndex src/storage/NacDBIndex \
	src/backend/order src/backend/personhood src/backend/payments src/backend/pst src/backend/main

out/src/backend/main.wasm: out/src/backend/order.deploy out/src/storage/CanDBIndex.deploy
out/src/backend/personhood.wasm: out/src/storage/CanDBIndex.deploy deploy-ic_eth
out/src/backend/order.wasm: out/src/storage/CanDBIndex.deploy out/src/storage/NacDBIndex.deploy
out/src/backend/payments.wasm: out/src/backend/pst.deploy

,PHONY: deploy-ic_eth
deploy-ic_eth:
	dfx deploy ic_eth
	touch out/ic_eth.deploy

,PHONY: deploy-internet_identity
deploy-internet_identity:
	dfx deploy internet_identity
	touch out/internet_identity.deploy

.PHONY: deploy-frontend
deploy-frontend: deploy-backend
	dfx deploy frontend
	touch out/frontend.deploy

.PHONY: deploy-backend
deploy-backend: deploy-main upgrade-candb upgrade-nacdb

.PHONY: deploy-main
deploy-main: $(addprefix $(DESTDIR)/,$(addsuffix .deploy,$(CANISTERS)))

.PHONY: upgrade-candb
upgrade-candb: $(DESTDIR)/src/storage/CanDBPartition.wasm
	npx ts-node scripts/upgrade-candb.ts $<

.PHONY: upgrade-nacdb
upgrade-nacdb: $(DESTDIR)/src/storage/NacDBPartition.wasm
	npx ts-node scripts/upgrade-nacdb.ts $<

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
