import { Agent, HttpAgent, Identity } from "@dfinity/agent";
import { AuthClient, AuthClientCreateOptions, AuthClientLoginOptions } from "@dfinity/auth-client";
import { Principal } from "@dfinity/principal";
import React, { createContext, useContext, useEffect, useState } from "react";
import { getIsLocal } from "../../util/client";
import { NFID } from "@nfid/embed";
// import sha256 from 'crypto-js/sha256';
// import * as base64 from 'base64-js';

export const AuthContext = createContext<{
  isAuthenticated: boolean,
  authClient?: AuthClient,
  agent?: Agent,
  defaultAgent?: AuthClient,
  identity?: Identity,
  principal?: Principal,
  options?: UseAuthClientOptions,
  login?: (callback?: () => Promise<void>) => void,
  logout?: () => Promise<void>,
}>({isAuthenticated: false});

type UseAuthClientOptions = {
  createOptions?: AuthClientCreateOptions;
  loginOptions?: AuthClientLoginOptions;
};

const defaultOptions: UseAuthClientOptions = {
  createOptions: {
    idleOptions: {
      // Set to true if you do not want idle functionality
      disableIdle: true, // TODO
    },
  },
  loginOptions: {
    identityProvider:
      process.env.DFX_NETWORK === "ic"
        ? `https://nfid.one`
        : `http://localhost:8000/?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`,
  },
};

/**
 * @type {React.FC}
 */
export function AuthProvider(props: { children: any, options?: UseAuthClientOptions }) {
  const [auth, setAuth] = useState<any>({options: props.options});
  // const [isAuthenticated, setIsAuthenticated] = useState(false);
  // const [authClient, setAuthClient] = useState<AuthClient | undefined>();
  // const [identity, setIdentity] = useState<Identity | undefined>(undefined);
  // const [principal, setPrincipal] = useState<Principal | undefined>(undefined);
  // const [options, setOptions] = useState<UseAuthClientOptions>(props.options ?? defaultOptions);

  useEffect(() => {
    // Initialize AuthClient
    AuthClient.create(props.options!.createOptions).then(async (client) => { // FIXME: `!`?
      updateClient(client);
    });
  }, []);

  async function updateClient(client) {
    const isAuthenticated = await client.isAuthenticated();
    const identity = client.getIdentity();
    const principal = identity.getPrincipal();
    const agent = new HttpAgent({identity});
    if (getIsLocal()) {
      agent.fetchRootKey();
    }

    setAuth({authClient: client, agent, isAuthenticated, identity, principal, options: props.options});
  }

  function updateClientNfid(identity) {
    console.log("IDENTITY", identity.getPrincipal); // TODO: Remove.
    console.log("IDENTITY2", identity.getPublicKey()); // TODO: returns ""
    const pubkey = identity.getDelegation().delegations[0].delegation.pubkey; // TODO: correct?
    console.log("IDENTITY3", pubkey); // TODO: Remove.
    const isAuthenticated = true; // FIXME
    // const principal = Principal.fromUint8Array(pubkey); // FIXME: wrong
    const principal = Principal.selfAuthenticating(pubkey); // FIXME: wrong
    // const hash = sha256(pubkey);
    // const prefixedHash = new Uint8Array([0x02, ...hash]);
    // const principal = Principal.fromUint8Array(prefixedHash); //base64.encode(prefixedHash);
    const agent = new HttpAgent({identity});
    if (getIsLocal()) {
      agent.fetchRootKey();
    }

    setAuth({agent, isAuthenticated, identity, principal, options: props.options});
  }

  const login = async () => {
    if (getIsLocal()) {
      auth.authClient!.login({
        ...defaultOptions, ...auth.options.loginOptions,
        onSuccess: () => {
          updateClient(auth.authClient);
          if (getIsLocal()) {
            auth.authClient.fetchRootKey();
          }
        },
      });
    } else {
      const nfid = await NFID.init({
        // origin: `https://${process.env.CANISTER_ID_frontend!}.icp0.io`, // FIXME: another canister
        application: {
          name: "Zon",
          // logo: "https://dev.nfid.one/static/media/id.300eb72f3335b50f5653a7d6ad5467b3.svg" // TODO
        },
      });
      const delegationIdentity: Identity = await nfid.getDelegation({
        // optional targets ICRC-28 implementation, but required to support universal NFID Wallet auth
        targets: [], // FIXME: needed?
        // optional derivationOrigin in case you're running on a custom domain
        derivationOrigin: `https://${process.env.CANISTER_ID_frontend!}.icp0.io`,
        // optional maxTimeToLive defaults to 8 hours in nanoseconds;
        maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000) // TODO
      });
      updateClientNfid(delegationIdentity);
      if (getIsLocal()) {
        auth.authClient.fetchRootKey();
      }
    }
  };

  const logout = async () => {
    await auth.authClient?.logout();
    if (getIsLocal()) {
      await updateClient(auth.authClient);
    } else {
      console.log("IDENITY0", auth);
      // updateClientNfid(auth.authClient); // FIXME
      setAuth({...auth, isAuthenticated: false}); // FIXME: Check correctness.
    }
  }

  const defaultAgent = new HttpAgent(); // TODO: options
  if (getIsLocal()) {
    defaultAgent.fetchRootKey();
  }

  return <AuthContext.Provider value={{...auth, login, logout, defaultAgent}}>{props.children}</AuthContext.Provider>;
};

export const useAuth = () => useContext(AuthContext);