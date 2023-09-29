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
deploy-backend: deploy-backend-without-main
	dfx deploy main

.PHONY: deploy-backend-without-main
deploy-backend-without-main:
	source .env && dfx deploy pst --argument "record { owner = principal \"$(FOUNDER)\"; subaccount = null; }"
	# TODO: Check principals used
	source .env && dfx deploy CanDBIndex --argument "vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" }"
	source .env && dfx deploy NacDBIndex --argument "vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" }"
#	dfx deploy CanDBIndex
#	dfx deploy pst
#	dfx deploy payments

.PHONY: deploy-frontend
deploy-frontend: deploy-backend-without-main
	dfx deploy frontend

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister call main init '()'
	dfx canister call payments init '()'
	dfx canister call CanDBIndex init '()'
	dfx canister call NacDBIndex init '()'
	mainItem=`dfx canister call main createItemData \
	  '(record { price = 0.0; locale = "en"; title = "The homepage"; description = ""; details = variant { communalCategory = null } })'`; \
	  dfx canister call main setRootItem "$$mainItem"
