#!/usr/bin/make -f

NETWORK = local

FOUNDER = racnx-sccpy-mgfgr-rgb67-bvwyx-gjkad-lyw33-prq23-yw24r-eb65i-oqe

.PHONY: all
all: deploy init

.PHONY: deploy
deploy:
	dfx deploy -vv

.PHONY: fabricate-cycles
	dfx ledger fabricate-cycles --amount 1000000000 --canister main

.PHONY: init
init: fabricate-cycles init-main init-CanDBIndex init-NacDBIndex init-items init-createItemData

.PHONY: init-main
init-main:
	dfx canister --network $(NETWORK) call main init '()'
# FIXME: Which canisters to allow calls?

#	. ./.env && dfx canister call --network $(NETWORK) payments init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\" })"

.PHONY: init-CanDBIndex
init-CanDBIndex:
	. ./.env && dfx canister call --network $(NETWORK) CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ITEMS\"; principal \"$$CANISTER_ID_PERSONHOOD\" })"

.PHONY: init-NacDBIndex
init-NacDBIndex:
	. ./.env && dfx canister call --network $(NETWORK) NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ITEMS\" })"

.PHONY: init-items
init-items:
	. ./.env && dfx canister call --network $(NETWORK) items init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-users
init-users:
	. ./.env && dfx canister call --network $(NETWORK) users init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; })"

.PHONY: init-createItemData
init-createItemData:
	mainItem=`dfx canister call --network $(NETWORK) items createItemData \
	  'record { data = record{price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { folder = null }}; communal = true }'`; \
	  dfx canister call --network $(NETWORK) main setRootItem "$$mainItem"
