#!/usr/bin/make -f

ICPRULESDIR = icp-make-rules
include $(ICPRULESDIR)/icp.rules

FOUNDER = $(shell dfx identity get-principal)

MOFILES = $(shell find src/backend src/libs src/storage)
CANISTERS = \
	src/storage/CanDBIndex src/storage/NacDBIndex \
	src/backend/order src/backend/personhood src/backend/main
CANISTER_INTERFACES = $(CANISTERS) src/storage/CanDBPartition src/storage/NacDBPartition

out/src/backend/main.wasm: out/src/backend/order.deploy out/src/storage/CanDBIndex.deploy
out/src/backend/personhood.wasm: out/src/storage/CanDBIndex.deploy $(DESTDIR)/ic_eth.deploy
out/src/backend/order.wasm: out/src/storage/CanDBIndex.deploy out/src/storage/NacDBIndex.deploy
out/src/backend/payments.wasm: out/src/backend/pst.deploy

,PHONY: deploy-internet_identity
deploy-internet_identity:
	dfx deploy internet_identity
	touch out/internet_identity.deploy

.PHONY: deploy-backend
deploy-backend: deploy-main upgrade-candb upgrade-nacdb deploy-internet_identity

.PHONY: deploy-frontend
deploy-frontend: deploy-interface out/frontend.deploy

# hack
.PHONY: deploy-main
deploy-main: $(addprefix $(DESTDIR)/,$(addsuffix .deploy,$(CANISTERS))) \
	$(DESTDIR)/ic_eth.deploy

.PHONY: deploy-interface
deploy-interface: $(addprefix $(DESTDIR)/,$(addsuffix .ts,$(CANISTER_INTERFACES)))

.PHONY: upgrade-candb
upgrade-candb: $(DESTDIR)/src/storage/CanDBPartition.wasm
	npx ts-node scripts/upgrade-candb.ts $<

.PHONY: upgrade-nacdb
upgrade-nacdb: $(DESTDIR)/src/storage/NacDBPartition.wasm
	npx ts-node scripts/upgrade-nacdb.ts $<

$(DESTDIR)/ic_eth.wasm: ./target/wasm32-unknown-unknown/release/ic_eth.wasm
	cp -f $< $@

./target/wasm32-unknown-unknown/release/ic_eth.wasm:
	cd src/ic_eth && cargo build --target wasm32-unknown-unknown --release

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister --network $(NETWORK) call main init '()'
# FIXME: Which canisters to allow calls?
#	. ./.env && dfx canister call --network $(NETWORK) payments init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\" })"
	. ./.env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"
	. ./.env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	. ./.env && dfx canister call --network $(NETWORK) order init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	mainItem=`dfx canister call --network $(NETWORK) main createItemData \
	  '(record { communal = true; price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { folder = null } })'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
