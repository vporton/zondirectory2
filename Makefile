#!/usr/bin/make -f

.PHONY: deploy
deploy:
	dfx deploy
	dfx canister call zon_backend init '(null)'
