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
out/src/backend/personhood.wasm: out/src/storage/CanDBIndex.deploy out/src/storage/NacDBIndex.deploy $(DESTDIR)/ic_eth.deploy
out/src/backend/order.wasm: out/src/storage/CanDBIndex.deploy out/src/storage/NacDBIndex.deploy
out/src/backend/payments.wasm: out/src/backend/pst.deploy

.PHONY: deploy-backend
deploy-backend: deploy-main upgrade-candb upgrade-nacdb $(DESTDIR)/internet_identity.deploy

.PHONY: deploy-frontend
deploy-frontend: out/assetstorage.deploy

# hack
.PHONY: deploy-main
deploy-main: $(addprefix $(DESTDIR)/,$(addsuffix .deploy,$(CANISTERS))) \
	$(DESTDIR)/ic_eth.deploy \
	$(DESTDIR)/internet_identity.deploy

.PHONY: deploy-interface
deploy-interface: \
  $(addprefix $(DESTDIR)/,$(addsuffix .js,$(CANISTER_INTERFACES))) \
  $(addprefix $(DESTDIR)/,$(addsuffix .d.ts,$(CANISTER_INTERFACES)))

.PHONY: upgrade-candb
upgrade-candb: $(DESTDIR)/src/storage/CanDBPartition.wasm deploy-interface
	npx ts-node scripts/upgrade-candb.ts $<

.PHONY: upgrade-nacdb
upgrade-nacdb: $(DESTDIR)/src/storage/NacDBPartition.wasm deploy-interface
	npx ts-node scripts/upgrade-nacdb.ts $<

.PHONY: 
ic_eth: ic_eth
	dfx build ic_eth

.PHONY: $(DESTDIR)/ic_eth.deploy
$(DESTDIR)/ic_eth.deploy:
	dfx deploy ic_eth
	touch $(DESTDIR)/ic_eth.deploy

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
