#!/usr/bin/make -f

# For `. .env` to work, even if /bin/sh is Dash:
SHELL=/bin/bash

FOUNDER = $(shell dfx identity get-wallet)

.PHONY: build
build:

.PHONY: deploy
deploy: deploy-backend deploy-frontend

.PHONY: build
build:
	dfx build main

.PHONY: deploy-backend
deploy-backend:
	dfx deploy main

.PHONY: deploy-frontend
deploy-frontend: deploy-backend
	dfx deploy frontend

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister call main init '()'
	dfx canister call payments init '()'
	. .env && dfx canister call CanDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	. .env && dfx canister call NacDBIndex init "(vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" })"
	mainItem=`dfx canister call main createItemData \
	  '(record { price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { communalCategory = null } })'`; \
	  dfx canister call main setRootItem "$$mainItem"
