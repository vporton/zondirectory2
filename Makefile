#!/usr/bin/make -f

.PHONY: build
build:

.PHONY: deploy
deploy: deploy-backend deploy-frontend

FOUNDER = principal "racnx-sccpy-mgfgr-rgb67-bvwyx-gjkad-lyw33-prq23-yw24r-eb65i-oqe"

.PHONY: build
build:
	dfx build main

.PHONY: deploy-backend
deploy-backend:
	# TODO: correct principal
	dfx deploy pst --argument 'record { owner = $(FOUNDER); subaccount = null; }'
	dfx deploy NacDBIndex --argument 'vec { $(FOUNDER) }'
#	dfx deploy CanDBIndex
#	dfx deploy pst
#	dfx deploy payments
	dfx deploy main
	dfx ledger fabricate-cycles --amount 1000000000 --canister main
	dfx canister call main init '(null)'

.PHONY: deploy-frontend
deploy-frontend:
	dfx deploy frontend
