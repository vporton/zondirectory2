NETWORK ?= local

DEPLOY_FLAGS ?= 

ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: build@CanDBIndex build@CanDBPartition build@NacDBIndex build@NacDBPartition build@battery build@call build@frontend build@ic_eth build@internet_identity build@items build@main build@payments build@personhood build@pst build@users

.PHONY: deploy@CanDBIndex deploy@CanDBPartition deploy@NacDBIndex deploy@NacDBPartition deploy@battery deploy@call deploy@frontend deploy@ic_eth deploy@internet_identity deploy@items deploy@main deploy@payments deploy@personhood deploy@pst deploy@users

.PHONY: generate@CanDBIndex generate@CanDBPartition generate@NacDBIndex generate@NacDBPartition generate@battery generate@call generate@frontend generate@ic_eth generate@internet_identity generate@items generate@main generate@payments generate@personhood generate@pst generate@users

build@CanDBIndex: \
  .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did

.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did: src/storage/CanDBIndex.mo

build@CanDBPartition: \
  .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did

.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: src/storage/CanDBPartition.mo

build@NacDBIndex: \
  .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did

.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: src/storage/NacDBIndex.mo

build@NacDBPartition: \
  .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did

.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did: src/storage/NacDBPartition.mo

build@battery: \
  .dfx/$(NETWORK)/canisters/battery/battery.wasm .dfx/$(NETWORK)/canisters/battery/battery.did

.dfx/$(NETWORK)/canisters/battery/battery.wasm .dfx/$(NETWORK)/canisters/battery/battery.did: src/backend/battery.mo

build@call: \
  .dfx/$(NETWORK)/canisters/call/call.wasm .dfx/$(NETWORK)/canisters/call/call.did

.dfx/$(NETWORK)/canisters/call/call.wasm .dfx/$(NETWORK)/canisters/call/call.did: src/backend/http/call.mo

build@frontend: \
  .dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz

build@ic_eth: \
  .dfx/$(NETWORK)/canisters/ic_eth/ic_eth.wasm .dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did

build@internet_identity: \
  .dfx/$(NETWORK)/canisters/internet_identity/internet_identity.wasm.gz .dfx/$(NETWORK)/canisters/internet_identity/internet_identity.did

build@items: \
  .dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did

.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/backend/items.mo

build@main: \
  .dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did

.dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did: src/backend/main.mo

build@payments: \
  .dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did

.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: src/backend/payments.mo

build@personhood: \
  .dfx/$(NETWORK)/canisters/personhood/personhood.wasm .dfx/$(NETWORK)/canisters/personhood/personhood.did

.dfx/$(NETWORK)/canisters/personhood/personhood.wasm .dfx/$(NETWORK)/canisters/personhood/personhood.did: src/backend/personhood.mo

build@pst: \
  .dfx/$(NETWORK)/canisters/pst/pst.wasm .dfx/$(NETWORK)/canisters/pst/pst.did

.dfx/$(NETWORK)/canisters/pst/pst.wasm .dfx/$(NETWORK)/canisters/pst/pst.did: src/backend/pst.mo

build@users: \
  .dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did

.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did: src/backend/users.mo

generate@CanDBIndex: build@CanDBIndex \
  src/declarations/CanDBIndex/CanDBIndex.did.js src/declarations/CanDBIndex/index.js src/declarations/CanDBIndex/CanDBIndex.did.d.ts src/declarations/CanDBIndex/index.d.ts src/declarations/CanDBIndex/CanDBIndex.did

src/declarations/CanDBIndex/CanDBIndex.did.js src/declarations/CanDBIndex/index.js src/declarations/CanDBIndex/CanDBIndex.did.d.ts src/declarations/CanDBIndex/index.d.ts src/declarations/CanDBIndex/CanDBIndex.did: .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
	dfx generate --no-compile --network $(NETWORK) CanDBIndex

generate@CanDBPartition: build@CanDBPartition \
  src/declarations/CanDBPartition/CanDBPartition.did.js src/declarations/CanDBPartition/index.js src/declarations/CanDBPartition/CanDBPartition.did.d.ts src/declarations/CanDBPartition/index.d.ts src/declarations/CanDBPartition/CanDBPartition.did

src/declarations/CanDBPartition/CanDBPartition.did.js src/declarations/CanDBPartition/index.js src/declarations/CanDBPartition/CanDBPartition.did.d.ts src/declarations/CanDBPartition/index.d.ts src/declarations/CanDBPartition/CanDBPartition.did: .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did
	dfx generate --no-compile --network $(NETWORK) CanDBPartition

generate@NacDBIndex: build@NacDBIndex \
  src/declarations/NacDBIndex/NacDBIndex.did.js src/declarations/NacDBIndex/index.js src/declarations/NacDBIndex/NacDBIndex.did.d.ts src/declarations/NacDBIndex/index.d.ts src/declarations/NacDBIndex/NacDBIndex.did

src/declarations/NacDBIndex/NacDBIndex.did.js src/declarations/NacDBIndex/index.js src/declarations/NacDBIndex/NacDBIndex.did.d.ts src/declarations/NacDBIndex/index.d.ts src/declarations/NacDBIndex/NacDBIndex.did: .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did
	dfx generate --no-compile --network $(NETWORK) NacDBIndex

generate@NacDBPartition: build@NacDBPartition \
  src/declarations/NacDBPartition/NacDBPartition.did.js src/declarations/NacDBPartition/index.js src/declarations/NacDBPartition/NacDBPartition.did.d.ts src/declarations/NacDBPartition/index.d.ts src/declarations/NacDBPartition/NacDBPartition.did

src/declarations/NacDBPartition/NacDBPartition.did.js src/declarations/NacDBPartition/index.js src/declarations/NacDBPartition/NacDBPartition.did.d.ts src/declarations/NacDBPartition/index.d.ts src/declarations/NacDBPartition/NacDBPartition.did: .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did
	dfx generate --no-compile --network $(NETWORK) NacDBPartition

generate@battery: build@battery \
  src/declarations/battery/battery.did.js src/declarations/battery/index.js src/declarations/battery/battery.did.d.ts src/declarations/battery/index.d.ts src/declarations/battery/battery.did

src/declarations/battery/battery.did.js src/declarations/battery/index.js src/declarations/battery/battery.did.d.ts src/declarations/battery/index.d.ts src/declarations/battery/battery.did: .dfx/$(NETWORK)/canisters/battery/battery.did
	dfx generate --no-compile --network $(NETWORK) battery

generate@call: build@call \
  src/declarations/call/call.did.js src/declarations/call/index.js src/declarations/call/call.did.d.ts src/declarations/call/index.d.ts src/declarations/call/call.did

src/declarations/call/call.did.js src/declarations/call/index.js src/declarations/call/call.did.d.ts src/declarations/call/index.d.ts src/declarations/call/call.did: .dfx/$(NETWORK)/canisters/call/call.did
	dfx generate --no-compile --network $(NETWORK) call

generate@frontend: build@frontend \
  src/declarations/frontend/frontend.did.js src/declarations/frontend/index.js src/declarations/frontend/frontend.did.d.ts src/declarations/frontend/index.d.ts src/declarations/frontend/frontend.did

src/declarations/frontend/frontend.did.js src/declarations/frontend/index.js src/declarations/frontend/frontend.did.d.ts src/declarations/frontend/index.d.ts src/declarations/frontend/frontend.did: .dfx/$(NETWORK)/canisters/frontend/service.did
	dfx generate --no-compile --network $(NETWORK) frontend

generate@ic_eth: build@ic_eth \
  src/declarations/ic_eth/ic_eth.did.js src/declarations/ic_eth/index.js src/declarations/ic_eth/ic_eth.did.d.ts src/declarations/ic_eth/index.d.ts src/declarations/ic_eth/ic_eth.did

src/declarations/ic_eth/ic_eth.did.js src/declarations/ic_eth/index.js src/declarations/ic_eth/ic_eth.did.d.ts src/declarations/ic_eth/index.d.ts src/declarations/ic_eth/ic_eth.did: .dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did
	dfx generate --no-compile --network $(NETWORK) ic_eth

generate@items: build@items \
  src/declarations/items/items.did.js src/declarations/items/index.js src/declarations/items/items.did.d.ts src/declarations/items/index.d.ts src/declarations/items/items.did

src/declarations/items/items.did.js src/declarations/items/index.js src/declarations/items/items.did.d.ts src/declarations/items/index.d.ts src/declarations/items/items.did: .dfx/$(NETWORK)/canisters/items/items.did
	dfx generate --no-compile --network $(NETWORK) items

generate@main: build@main \
  src/declarations/main/main.did.js src/declarations/main/index.js src/declarations/main/main.did.d.ts src/declarations/main/index.d.ts src/declarations/main/main.did

src/declarations/main/main.did.js src/declarations/main/index.js src/declarations/main/main.did.d.ts src/declarations/main/index.d.ts src/declarations/main/main.did: .dfx/$(NETWORK)/canisters/main/main.did
	dfx generate --no-compile --network $(NETWORK) main

generate@payments: build@payments \
  src/declarations/payments/payments.did.js src/declarations/payments/index.js src/declarations/payments/payments.did.d.ts src/declarations/payments/index.d.ts src/declarations/payments/payments.did

src/declarations/payments/payments.did.js src/declarations/payments/index.js src/declarations/payments/payments.did.d.ts src/declarations/payments/index.d.ts src/declarations/payments/payments.did: .dfx/$(NETWORK)/canisters/payments/payments.did
	dfx generate --no-compile --network $(NETWORK) payments

generate@personhood: build@personhood \
  src/declarations/personhood/personhood.did.js src/declarations/personhood/index.js src/declarations/personhood/personhood.did.d.ts src/declarations/personhood/index.d.ts src/declarations/personhood/personhood.did

src/declarations/personhood/personhood.did.js src/declarations/personhood/index.js src/declarations/personhood/personhood.did.d.ts src/declarations/personhood/index.d.ts src/declarations/personhood/personhood.did: .dfx/$(NETWORK)/canisters/personhood/personhood.did
	dfx generate --no-compile --network $(NETWORK) personhood

generate@pst: build@pst \
  src/declarations/pst/pst.did.js src/declarations/pst/index.js src/declarations/pst/pst.did.d.ts src/declarations/pst/index.d.ts src/declarations/pst/pst.did

src/declarations/pst/pst.did.js src/declarations/pst/index.js src/declarations/pst/pst.did.d.ts src/declarations/pst/index.d.ts src/declarations/pst/pst.did: .dfx/$(NETWORK)/canisters/pst/pst.did
	dfx generate --no-compile --network $(NETWORK) pst

generate@users: build@users \
  src/declarations/users/users.did.js src/declarations/users/index.js src/declarations/users/users.did.d.ts src/declarations/users/index.d.ts src/declarations/users/users.did

src/declarations/users/users.did.js src/declarations/users/index.js src/declarations/users/users.did.d.ts src/declarations/users/index.d.ts src/declarations/users/users.did: .dfx/$(NETWORK)/canisters/users/users.did
	dfx generate --no-compile --network $(NETWORK) users

.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: src/backend/lib.mo
src/storage/NacDBPartition.mo: src/libs/configs/db-config.mo
.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did: src/storage/NacDBPartition.mo
.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: src/storage/NacDBPartition.mo
.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: .dfx/$(NETWORK)/canisters/battery/battery.wasm .dfx/$(NETWORK)/canisters/battery/battery.did
.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did: src/libs/configs/db-config.mo
.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did: src/libs/configs/db-config.mo
.dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did: src/backend/rateLimit.mo
.dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did: .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
src/storage/CanDBPartition.mo: src/backend/lib.mo
src/storage/CanDBPartition.mo: src/storage/NacDBPartition.mo
.dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did: src/storage/CanDBPartition.mo
.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz: .dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did
.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz: .dfx/$(NETWORK)/canisters/internet_identity/internet_identity.wasm.gz .dfx/$(NETWORK)/canisters/internet_identity/internet_identity.did
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/storage/CanDBPartition.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/libs/configs/db-config.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/libs/configs/misc.config.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/backend/lib.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/backend/ai.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/backend/rateLimit.mo
.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did: src/storage/NacDBPartition.mo
.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: src/storage/CanDBPartition.mo
.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: src/backend/lib.mo
.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: .dfx/$(NETWORK)/canisters/pst/pst.wasm .dfx/$(NETWORK)/canisters/pst/pst.did
.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: src/libs/helpers/fractions.helper.mo
.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did: src/libs/configs/db-config.mo
.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did: .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did
.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did: src/storage/CanDBPartition.mo
.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did: src/backend/rateLimit.mo
.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did: src/backend/lib.mo
.dfx/$(NETWORK)/canisters/battery/battery.wasm .dfx/$(NETWORK)/canisters/battery/battery.did:
	dfx canister create --network $(NETWORK) battery
	dfx build --no-deps --network $(NETWORK) battery


deploy-self@battery: build@battery
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.battery) battery

deploy@battery: deploy-self@battery

.dfx/$(NETWORK)/canisters/payments/payments.wasm .dfx/$(NETWORK)/canisters/payments/payments.did:
	dfx canister create --network $(NETWORK) payments
	dfx build --no-deps --network $(NETWORK) payments


deploy-self@payments: build@payments
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.payments) payments

deploy@payments: deploy@pst \
  deploy-self@payments

.dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.wasm .dfx/$(NETWORK)/canisters/CanDBPartition/CanDBPartition.did:
	dfx canister create --network $(NETWORK) CanDBPartition
	dfx build --no-deps --network $(NETWORK) CanDBPartition


deploy-self@CanDBPartition: build@CanDBPartition
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.CanDBPartition) CanDBPartition

deploy@CanDBPartition: deploy-self@CanDBPartition

.dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.wasm .dfx/$(NETWORK)/canisters/NacDBPartition/NacDBPartition.did:
	dfx canister create --network $(NETWORK) NacDBPartition
	dfx build --no-deps --network $(NETWORK) NacDBPartition


deploy-self@NacDBPartition: build@NacDBPartition
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.NacDBPartition) NacDBPartition

deploy@NacDBPartition: deploy@NacDBIndex \
  deploy-self@NacDBPartition

.dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.wasm .dfx/$(NETWORK)/canisters/CanDBIndex/CanDBIndex.did:
	dfx canister create --network $(NETWORK) CanDBIndex
	dfx build --no-deps --network $(NETWORK) CanDBIndex


deploy-self@CanDBIndex: build@CanDBIndex
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.CanDBIndex) CanDBIndex

deploy@CanDBIndex: deploy@battery \
  deploy-self@CanDBIndex

.PHONY: .dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz
.dfx/$(NETWORK)/canisters/frontend/assetstorage.wasm.gz:
	dfx canister create --network $(NETWORK) frontend
	dfx build --no-deps --network $(NETWORK) frontend


deploy-self@frontend: build@frontend
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.frontend) frontend


canister@frontend: \
  generate@main generate@internet_identity
deploy@frontend: deploy@main deploy@internet_identity \
  deploy-self@frontend

.dfx/$(NETWORK)/canisters/items/items.wasm .dfx/$(NETWORK)/canisters/items/items.did:
	dfx canister create --network $(NETWORK) items
	dfx build --no-deps --network $(NETWORK) items


deploy-self@items: build@items
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.items) items

deploy@items: deploy@CanDBIndex deploy@NacDBIndex deploy@call \
  deploy-self@items

.dfx/$(NETWORK)/canisters/pst/pst.wasm .dfx/$(NETWORK)/canisters/pst/pst.did:
	dfx canister create --network $(NETWORK) pst
	dfx build --no-deps --network $(NETWORK) pst


deploy-self@pst: build@pst
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.pst) pst

deploy@pst: deploy-self@pst

.dfx/$(NETWORK)/canisters/ic_eth/ic_eth.wasm .dfx/$(NETWORK)/canisters/ic_eth/ic_eth.did:
	dfx canister create --network $(NETWORK) ic_eth
	dfx build --no-deps --network $(NETWORK) ic_eth


deploy-self@ic_eth: build@ic_eth
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.ic_eth) ic_eth

deploy@ic_eth: deploy-self@ic_eth

.dfx/$(NETWORK)/canisters/main/main.wasm .dfx/$(NETWORK)/canisters/main/main.did:
	dfx canister create --network $(NETWORK) main
	dfx build --no-deps --network $(NETWORK) main


deploy-self@main: build@main
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.main) main

deploy@main: deploy@items deploy@users deploy@CanDBIndex deploy@NacDBIndex deploy@personhood \
  deploy-self@main

.dfx/$(NETWORK)/canisters/call/call.wasm .dfx/$(NETWORK)/canisters/call/call.did:
	dfx canister create --network $(NETWORK) call
	dfx build --no-deps --network $(NETWORK) call


deploy-self@call: build@call
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.call) call

deploy@call: deploy-self@call

.dfx/$(NETWORK)/canisters/users/users.wasm .dfx/$(NETWORK)/canisters/users/users.did:
	dfx canister create --network $(NETWORK) users
	dfx build --no-deps --network $(NETWORK) users


deploy-self@users: build@users
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.users) users

deploy@users: deploy@CanDBIndex deploy@NacDBIndex \
  deploy-self@users

.dfx/$(NETWORK)/canisters/internet_identity/internet_identity.wasm.gz .dfx/$(NETWORK)/canisters/internet_identity/internet_identity.did:
	dfx canister create --network $(NETWORK) internet_identity
	dfx build --no-deps --network $(NETWORK) internet_identity


deploy-self@internet_identity: build@internet_identity
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.internet_identity) internet_identity

deploy@internet_identity: deploy-self@internet_identity

.dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.wasm .dfx/$(NETWORK)/canisters/NacDBIndex/NacDBIndex.did:
	dfx canister create --network $(NETWORK) NacDBIndex
	dfx build --no-deps --network $(NETWORK) NacDBIndex


deploy-self@NacDBIndex: build@NacDBIndex
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.NacDBIndex) NacDBIndex

deploy@NacDBIndex: deploy@battery \
  deploy-self@NacDBIndex

.dfx/$(NETWORK)/canisters/personhood/personhood.wasm .dfx/$(NETWORK)/canisters/personhood/personhood.did:
	dfx canister create --network $(NETWORK) personhood
	dfx build --no-deps --network $(NETWORK) personhood


deploy-self@personhood: build@personhood
	dfx deploy --no-compile --network $(NETWORK) $(DEPLOY_FLAGS) $(DEPLOY_FLAGS.personhood) personhood

deploy@personhood: deploy@ic_eth deploy@CanDBIndex \
  deploy-self@personhood

