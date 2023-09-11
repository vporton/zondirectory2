#!/usr/bin/make -f

.PHONY: deploy
deploy:
	dfx deploy
	dfx ledger fabricate-cycles --amount 1000000000 --canister zon_backend
#	dfx canister call zon_backend init --with-cycles 10000000000 '(null)'
	dfx canister call zon_backend init '(null)'
