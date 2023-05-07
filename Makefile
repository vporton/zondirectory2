#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-candb deploy-zon_pst deploy-zon_backend deploy-zon_frontend

.PHONY: deploy-candb
deploy-candb:
	cd CanDB/examples/multiCanister/simpleMultiCanister && /home/porton/.cache/dfinity/versions/0.11.2/dfx deploy index --network http://localhost:46429

.PHONY: deploy-zon_pst
deploy-zon_pst:
	dfx deploy zon_pst --argument '( record { name = "Zon Directory PST Token"; symbol = "ZDPST"; decimals = 6; fee = 100_000; max_supply = 1_000_000_000; initial_balances = vec { record { record { owner = principal "ruuoz-anyad-jumcs-huq7s-3eh7h-ja6j2-cmp2n-elv23-tghui-mve6f-xqe"; subaccount = null; }; 1_000_000_000 } }; min_burn_amount = 100_000; minting_account = null; advanced_settings = null; })'

.PHONY: deploy-zon_backend
deploy-zon_backend:
	dfx deploy zon_backend

.PHONY: deploy-zon_frontend
deploy-zon_frontend:
	dfx deploy zon_frontend
