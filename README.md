## Quick notes

During the work on this project I also created [NacDB](https://github.com/vporton/NacDB) database.
During this work I developed a strategy how to accomplish reliable operations over unreliable actors
in actor model of ICP. It is a serious computer science research, I should publish this in peer review.

Streams ordering items by voting results will be implemented using
[NacDBReorder library](https://github.com/vporton/NacDBReorder) (in development).
It uses an advanced combination of data structures to add, reorder, and delete items.

For the frontend to work, you need `dfx generate` using https://github.com/vporton/sdk (contains a bug fix),

## Running the project locally

If you want to test our project locally:

Copy `config.mo.example` to `config.mo` and edit it accordingly to your settings.

Set `REACT_APP_IS_LOCAL=1` in `.env`.

Use the following commands:

```bash
# Select Node version
nvm install v18.19.1
nvm use v18.19.1

# Starts the replica, running in the background
dfx start --background

# Build the first time: (6 min)
make deploy-backend && make deploy-frontend && make init

# ... Build again:
make deploy-backend && make deploy-frontend
```

Once the job completes, your application will be available at `http://localhost:4943?canisterId={asset_canister_id}`.

Note that the timings on my laptop are bigger than to be expected, because a bug forced me to run my laptop in powersave mode.

If you are making frontend changes, you can start a development server with

```bash
npm start
```

Which will start a server at `http://localhost:8080`, proxying API requests to the replica at port 4943.

### Note on frontend environment variables

If you are hosting frontend code somewhere without using DFX, you may need to make one of the following adjustments to ensure your project does not fetch the root key in production:

- set`DFX_NETWORK` to `ic` if you are using Webpack
- use your own preferred method to replace `process.env.DFX_NETWORK` in the autogenerated declarations
  - Setting `canisters -> {asset_canister_id} -> declarations -> env_override to a string` in `dfx.json` will replace `process.env.DFX_NETWORK` with the string in the autogenerated declarations
- Write your own `createActor` constructor
