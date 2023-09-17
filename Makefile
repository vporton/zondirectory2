#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-backend deploy-frontend

FOUNDER = principal "racnx-sccpy-mgfgr-rgb67-bvwyx-gjkad-lyw33-prq23-yw24r-eb65i-oqe"

.PHONY: deploy-backend
deploy-backend:
	# TODO: correct principal
	dfx deploy zon_pst --argument 'record { owner = $(FOUNDER); subaccount = null; }'
	dfx deploy NacDBIndex --argument 'vec { $(FOUNDER) }'
#	dfx deploy CanDBIndex
#	dfx deploy zon_pst
#	dfx deploy payments
	dfx deploy backend
	dfx ledger fabricate-cycles --amount 1000000000 --canister backend
	dfx canister call backend init '(null)'

.PHONY: deploy-frontend
deploy-frontend:
	dfx deploy frontend
