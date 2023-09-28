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
	source .env && dfx deploy pst --argument "record { owner = principal \"$(FOUNDER)\"; subaccount = null; }"
	# TODO: Check canisters used
	source .env && dfx deploy CanDBIndex --argument "vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" }"
	source .env && dfx deploy NacDBIndex --argument "vec { principal \"$(FOUNDER)\"; principal \"$$CANISTER_ID_MAIN\"; principal \"$$CANISTER_ID_ORDER\" }"
#	dfx deploy CanDBIndex
#	dfx deploy pst
#	dfx deploy payments
	dfx deploy main

.PHONY: deploy-frontend
deploy-frontend: deploy-backend
	dfx deploy frontend

.PHONY: init
init:
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister call main init '()'
	dfx canister call payments init '()'
	dfx canister call CanDBIndex init '()'
	dfx canister call NacDBIndex init '()'
