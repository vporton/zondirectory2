#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-backend deploy-frontend

.PHONY: deploy-backend
deploy-backend:
	# TODO: correct principal
	dfx deploy zon_pst --argument 'record { owner = principal "racnx-sccpy-mgfgr-rgb67-bvwyx-gjkad-lyw33-prq23-yw24r-eb65i-oqe"; subaccount = null; }'
	dfx deploy
	dfx ledger fabricate-cycles --amount 1000000000 --canister zon_backend
	dfx canister call zon_backend init '(null)'

.PHONY: deploy-frontend
deploy-frontend:
	dfx deploy frontend
