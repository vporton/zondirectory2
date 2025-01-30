NETWORK ?= local

DEPLOY_FLAGS ?= 

ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: canister@CanDBIndex canister@CanDBPartition canister@NacDBIndex canister@NacDBPartition canister@battery canister@call canister@frontend canister@ic_eth canister@internet_identity canister@items canister@main canister@payments canister@personhood canister@pst canister@users

.PHONY: deploy@CanDBIndex deploy@CanDBPartition deploy@NacDBIndex deploy@NacDBPartition deploy@battery deploy@call deploy@frontend deploy@ic_eth deploy@internet_identity deploy@items deploy@main deploy@payments deploy@personhood deploy@pst deploy@users

.PHONY: generate@CanDBIndex generate@CanDBPartition generate@NacDBIndex generate@NacDBPartition generate@battery generate@call generate@frontend generate@ic_eth generate@internet_identity generate@items generate@main generate@payments generate@personhood generate@pst generate@users

canister@CanDBIndex: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did: $(ROOT_DIR)/src/storage/CanDBIndex.mo

canister@CanDBPartition: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: $(ROOT_DIR)/src/storage/CanDBPartition.mo

canister@NacDBIndex: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: $(ROOT_DIR)/src/storage/NacDBIndex.mo

canister@NacDBPartition: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did: $(ROOT_DIR)/src/storage/NacDBPartition.mo

canister@battery: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.did: $(ROOT_DIR)/src/backend/battery.mo

canister@call: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.did: $(ROOT_DIR)/src/backend/http/call.mo

canister@frontend: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz

canister@ic_eth: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did

canister@items: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/backend/items.mo

canister@main: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did: $(ROOT_DIR)/src/backend/main.mo

canister@payments: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/src/backend/payments.mo

canister@personhood: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.did: $(ROOT_DIR)/src/backend/personhood.mo

canister@pst: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.did: $(ROOT_DIR)/src/backend/pst.mo

canister@users: \
  $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did: $(ROOT_DIR)/src/backend/users.mo

generate@CanDBIndex: \
  $(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did.js $(ROOT_DIR)/src/declarations/CanDBIndex/index.js $(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did.d.ts $(ROOT_DIR)/src/declarations/CanDBIndex/index.d.ts $(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did

$(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did.js $(ROOT_DIR)/src/declarations/CanDBIndex/index.js $(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did.d.ts $(ROOT_DIR)/src/declarations/CanDBIndex/index.d.ts $(ROOT_DIR)/src/declarations/CanDBIndex/CanDBIndex.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
	dfx generate --no-compile --network $(NETWORK) CanDBIndex

generate@CanDBPartition: \
  $(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did.js $(ROOT_DIR)/src/declarations/CanDBPartition/index.js $(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did.d.ts $(ROOT_DIR)/src/declarations/CanDBPartition/index.d.ts $(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did

$(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did.js $(ROOT_DIR)/src/declarations/CanDBPartition/index.js $(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did.d.ts $(ROOT_DIR)/src/declarations/CanDBPartition/index.d.ts $(ROOT_DIR)/src/declarations/CanDBPartition/CanDBPartition.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did
	dfx generate --no-compile --network $(NETWORK) CanDBPartition

generate@NacDBIndex: \
  $(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did.js $(ROOT_DIR)/src/declarations/NacDBIndex/index.js $(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did.d.ts $(ROOT_DIR)/src/declarations/NacDBIndex/index.d.ts $(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did

$(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did.js $(ROOT_DIR)/src/declarations/NacDBIndex/index.js $(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did.d.ts $(ROOT_DIR)/src/declarations/NacDBIndex/index.d.ts $(ROOT_DIR)/src/declarations/NacDBIndex/NacDBIndex.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did
	dfx generate --no-compile --network $(NETWORK) NacDBIndex

generate@NacDBPartition: \
  $(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did.js $(ROOT_DIR)/src/declarations/NacDBPartition/index.js $(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did.d.ts $(ROOT_DIR)/src/declarations/NacDBPartition/index.d.ts $(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did

$(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did.js $(ROOT_DIR)/src/declarations/NacDBPartition/index.js $(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did.d.ts $(ROOT_DIR)/src/declarations/NacDBPartition/index.d.ts $(ROOT_DIR)/src/declarations/NacDBPartition/NacDBPartition.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did
	dfx generate --no-compile --network $(NETWORK) NacDBPartition

generate@battery: \
  $(ROOT_DIR)/src/declarations/battery/battery.did.js $(ROOT_DIR)/src/declarations/battery/index.js $(ROOT_DIR)/src/declarations/battery/battery.did.d.ts $(ROOT_DIR)/src/declarations/battery/index.d.ts $(ROOT_DIR)/src/declarations/battery/battery.did

$(ROOT_DIR)/src/declarations/battery/battery.did.js $(ROOT_DIR)/src/declarations/battery/index.js $(ROOT_DIR)/src/declarations/battery/battery.did.d.ts $(ROOT_DIR)/src/declarations/battery/index.d.ts $(ROOT_DIR)/src/declarations/battery/battery.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.did
	dfx generate --no-compile --network $(NETWORK) battery

generate@call: \
  $(ROOT_DIR)/src/declarations/call/call.did.js $(ROOT_DIR)/src/declarations/call/index.js $(ROOT_DIR)/src/declarations/call/call.did.d.ts $(ROOT_DIR)/src/declarations/call/index.d.ts $(ROOT_DIR)/src/declarations/call/call.did

$(ROOT_DIR)/src/declarations/call/call.did.js $(ROOT_DIR)/src/declarations/call/index.js $(ROOT_DIR)/src/declarations/call/call.did.d.ts $(ROOT_DIR)/src/declarations/call/index.d.ts $(ROOT_DIR)/src/declarations/call/call.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.did
	dfx generate --no-compile --network $(NETWORK) call

generate@frontend: \
  $(ROOT_DIR)/src/declarations/frontend/frontend.did.js $(ROOT_DIR)/src/declarations/frontend/index.js $(ROOT_DIR)/src/declarations/frontend/frontend.did.d.ts $(ROOT_DIR)/src/declarations/frontend/index.d.ts $(ROOT_DIR)/src/declarations/frontend/frontend.did

$(ROOT_DIR)/src/declarations/frontend/frontend.did.js $(ROOT_DIR)/src/declarations/frontend/index.js $(ROOT_DIR)/src/declarations/frontend/frontend.did.d.ts $(ROOT_DIR)/src/declarations/frontend/index.d.ts $(ROOT_DIR)/src/declarations/frontend/frontend.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/frontend/frontend.did
	dfx generate --no-compile --network $(NETWORK) frontend

generate@ic_eth: \
  $(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did.js $(ROOT_DIR)/src/declarations/ic_eth/index.js $(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did.d.ts $(ROOT_DIR)/src/declarations/ic_eth/index.d.ts $(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did

$(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did.js $(ROOT_DIR)/src/declarations/ic_eth/index.js $(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did.d.ts $(ROOT_DIR)/src/declarations/ic_eth/index.d.ts $(ROOT_DIR)/src/declarations/ic_eth/ic_eth.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did
	dfx generate --no-compile --network $(NETWORK) ic_eth

generate@internet_identity: \
  $(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did.js $(ROOT_DIR)/src/declarations/internet_identity/index.js $(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did.d.ts $(ROOT_DIR)/src/declarations/internet_identity/index.d.ts $(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did

$(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did.js $(ROOT_DIR)/src/declarations/internet_identity/index.js $(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did.d.ts $(ROOT_DIR)/src/declarations/internet_identity/index.d.ts $(ROOT_DIR)/src/declarations/internet_identity/internet_identity.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/internet_identity/internet_identity.did
	dfx generate --no-compile --network $(NETWORK) internet_identity

generate@items: \
  $(ROOT_DIR)/src/declarations/items/items.did.js $(ROOT_DIR)/src/declarations/items/index.js $(ROOT_DIR)/src/declarations/items/items.did.d.ts $(ROOT_DIR)/src/declarations/items/index.d.ts $(ROOT_DIR)/src/declarations/items/items.did

$(ROOT_DIR)/src/declarations/items/items.did.js $(ROOT_DIR)/src/declarations/items/index.js $(ROOT_DIR)/src/declarations/items/items.did.d.ts $(ROOT_DIR)/src/declarations/items/index.d.ts $(ROOT_DIR)/src/declarations/items/items.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did
	dfx generate --no-compile --network $(NETWORK) items

generate@main: \
  $(ROOT_DIR)/src/declarations/main/main.did.js $(ROOT_DIR)/src/declarations/main/index.js $(ROOT_DIR)/src/declarations/main/main.did.d.ts $(ROOT_DIR)/src/declarations/main/index.d.ts $(ROOT_DIR)/src/declarations/main/main.did

$(ROOT_DIR)/src/declarations/main/main.did.js $(ROOT_DIR)/src/declarations/main/index.js $(ROOT_DIR)/src/declarations/main/main.did.d.ts $(ROOT_DIR)/src/declarations/main/index.d.ts $(ROOT_DIR)/src/declarations/main/main.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did
	dfx generate --no-compile --network $(NETWORK) main

generate@payments: \
  $(ROOT_DIR)/src/declarations/payments/payments.did.js $(ROOT_DIR)/src/declarations/payments/index.js $(ROOT_DIR)/src/declarations/payments/payments.did.d.ts $(ROOT_DIR)/src/declarations/payments/index.d.ts $(ROOT_DIR)/src/declarations/payments/payments.did

$(ROOT_DIR)/src/declarations/payments/payments.did.js $(ROOT_DIR)/src/declarations/payments/index.js $(ROOT_DIR)/src/declarations/payments/payments.did.d.ts $(ROOT_DIR)/src/declarations/payments/index.d.ts $(ROOT_DIR)/src/declarations/payments/payments.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did
	dfx generate --no-compile --network $(NETWORK) payments

generate@personhood: \
  $(ROOT_DIR)/src/declarations/personhood/personhood.did.js $(ROOT_DIR)/src/declarations/personhood/index.js $(ROOT_DIR)/src/declarations/personhood/personhood.did.d.ts $(ROOT_DIR)/src/declarations/personhood/index.d.ts $(ROOT_DIR)/src/declarations/personhood/personhood.did

$(ROOT_DIR)/src/declarations/personhood/personhood.did.js $(ROOT_DIR)/src/declarations/personhood/index.js $(ROOT_DIR)/src/declarations/personhood/personhood.did.d.ts $(ROOT_DIR)/src/declarations/personhood/index.d.ts $(ROOT_DIR)/src/declarations/personhood/personhood.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.did
	dfx generate --no-compile --network $(NETWORK) personhood

generate@pst: \
  $(ROOT_DIR)/src/declarations/pst/pst.did.js $(ROOT_DIR)/src/declarations/pst/index.js $(ROOT_DIR)/src/declarations/pst/pst.did.d.ts $(ROOT_DIR)/src/declarations/pst/index.d.ts $(ROOT_DIR)/src/declarations/pst/pst.did

$(ROOT_DIR)/src/declarations/pst/pst.did.js $(ROOT_DIR)/src/declarations/pst/index.js $(ROOT_DIR)/src/declarations/pst/pst.did.d.ts $(ROOT_DIR)/src/declarations/pst/index.d.ts $(ROOT_DIR)/src/declarations/pst/pst.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.did
	dfx generate --no-compile --network $(NETWORK) pst

generate@users: \
  $(ROOT_DIR)/src/declarations/users/users.did.js $(ROOT_DIR)/src/declarations/users/index.js $(ROOT_DIR)/src/declarations/users/users.did.d.ts $(ROOT_DIR)/src/declarations/users/index.d.ts $(ROOT_DIR)/src/declarations/users/users.did

$(ROOT_DIR)/src/declarations/users/users.did.js $(ROOT_DIR)/src/declarations/users/index.js $(ROOT_DIR)/src/declarations/users/users.did.d.ts $(ROOT_DIR)/src/declarations/users/index.d.ts $(ROOT_DIR)/src/declarations/users/users.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did
	dfx generate --no-compile --network $(NETWORK) users

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: $(ROOT_DIR)/src/backend/lib.mo
$(ROOT_DIR)/src/storage/NacDBPartition.mo: $(ROOT_DIR)/src/libs/configs/db-config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: $(ROOT_DIR)/src/storage/NacDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: $(ROOT_DIR)/src/storage/NacDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: $(ROOT_DIR)/src/libs/configs/db-config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did: $(ROOT_DIR)/src/libs/configs/db-config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did: $(ROOT_DIR)/src/backend/rateLimit.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
$(ROOT_DIR)/src/storage/CanDBPartition.mo: $(ROOT_DIR)/src/backend/lib.mo
$(ROOT_DIR)/src/storage/CanDBPartition.mo: $(ROOT_DIR)/src/storage/NacDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did: $(ROOT_DIR)/src/storage/CanDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/storage/CanDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/libs/configs/db-config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/libs/configs/misc.config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/backend/lib.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/backend/ai.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/backend/rateLimit.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did: $(ROOT_DIR)/src/storage/NacDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/src/storage/CanDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/src/backend/lib.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/src/libs/helpers/fractions.helper.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did: $(ROOT_DIR)/src/libs/configs/db-config.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did: $(ROOT_DIR)/src/storage/CanDBPartition.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did: $(ROOT_DIR)/src/backend/rateLimit.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did: $(ROOT_DIR)/src/backend/lib.mo
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/personhood/personhood.did:
	dfx canister create --network $(NETWORK) personhood
	dfx build --no-deps --network $(NETWORK) personhood


deploy-self@personhood: canister@personhood
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.personhood) personhood

deploy@personhood: deploy@ic_eth deploy@CanDBIndex \
  deploy-self@personhood

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did:
	dfx canister create --network $(NETWORK) ic_eth
	dfx build --no-deps --network $(NETWORK) ic_eth


deploy-self@ic_eth: canister@ic_eth
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.ic_eth) ic_eth

deploy@ic_eth: deploy-self@ic_eth


deploy-self@internet_identity: canister@internet_identitydeploy@internet_identity: deploy-self@internet_identity

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/users/users.did:
	dfx canister create --network $(NETWORK) users
	dfx build --no-deps --network $(NETWORK) users


deploy-self@users: canister@users
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.users) users

deploy@users: deploy@CanDBIndex deploy@NacDBIndex \
  deploy-self@users

.PHONY: $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz
$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz:
	dfx canister create --network $(NETWORK) frontend
	dfx build --no-deps --network $(NETWORK) frontend


deploy-self@frontend: canister@frontend
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.frontend) frontend


canister@frontend: \
  generate@main
deploy@frontend: deploy@main \
  deploy-self@frontend

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/pst/pst.did:
	dfx canister create --network $(NETWORK) pst
	dfx build --no-deps --network $(NETWORK) pst


deploy-self@pst: canister@pst
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.pst) pst

deploy@pst: deploy-self@pst

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did:
	dfx canister create --network $(NETWORK) CanDBIndex
	dfx build --no-deps --network $(NETWORK) CanDBIndex


deploy-self@CanDBIndex: canister@CanDBIndex
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.CanDBIndex) CanDBIndex

deploy@CanDBIndex: deploy@battery \
  deploy-self@CanDBIndex

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/payments/payments.did:
	dfx canister create --network $(NETWORK) payments
	dfx build --no-deps --network $(NETWORK) payments


deploy-self@payments: canister@payments
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.payments) payments

deploy@payments: deploy@pst \
  deploy-self@payments

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/items/items.did:
	dfx canister create --network $(NETWORK) items
	dfx build --no-deps --network $(NETWORK) items


deploy-self@items: canister@items
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.items) items

deploy@items: deploy@CanDBIndex deploy@NacDBIndex deploy@call \
  deploy-self@items

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did:
	dfx canister create --network $(NETWORK) NacDBIndex
	dfx build --no-deps --network $(NETWORK) NacDBIndex


deploy-self@NacDBIndex: canister@NacDBIndex
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.NacDBIndex) NacDBIndex

deploy@NacDBIndex: deploy@battery \
  deploy-self@NacDBIndex

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did:
	dfx canister create --network $(NETWORK) NacDBPartition
	dfx build --no-deps --network $(NETWORK) NacDBPartition


deploy-self@NacDBPartition: canister@NacDBPartition
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.NacDBPartition) NacDBPartition

deploy@NacDBPartition: deploy@NacDBIndex \
  deploy-self@NacDBPartition

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did:
	dfx canister create --network $(NETWORK) CanDBPartition
	dfx build --no-deps --network $(NETWORK) CanDBPartition


deploy-self@CanDBPartition: canister@CanDBPartition
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.CanDBPartition) CanDBPartition

deploy@CanDBPartition: deploy-self@CanDBPartition

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/battery/battery.did:
	dfx canister create --network $(NETWORK) battery
	dfx build --no-deps --network $(NETWORK) battery


deploy-self@battery: canister@battery
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.battery) battery

deploy@battery: deploy-self@battery

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/main/main.did:
	dfx canister create --network $(NETWORK) main
	dfx build --no-deps --network $(NETWORK) main


deploy-self@main: canister@main
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.main) main

deploy@main: deploy@items deploy@users deploy@CanDBIndex deploy@NacDBIndex deploy@personhood deploy@internet_identity \
  deploy-self@main

$(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.wasm $(ROOT_DIR)/.dfx/$(NETWORK)/canisters/call/call.did:
	dfx canister create --network $(NETWORK) call
	dfx build --no-deps --network $(NETWORK) call


deploy-self@call: canister@call
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.call) call

deploy@call: deploy-self@call

