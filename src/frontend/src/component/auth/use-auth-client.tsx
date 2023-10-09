import { Agent, HttpAgent, Identity } from "@dfinity/agent";
import { AuthClient, AuthClientCreateOptions, AuthClientLoginOptions } from "@dfinity/auth-client";
import { Principal } from "@dfinity/principal";
import React, { createContext, useContext, useEffect, useState } from "react";
import { getIsLocal } from "../../util/client";

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
}

const defaultOptions: UseAuthClientOptions = {
  createOptions: {
    idleOptions: {
      // Set to true if you do not want idle functionality
      disableIdle: true,
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

  const login = async () => {
    auth.authClient!.login({
      ...defaultOptions, ...auth.options.loginOptions,
      onSuccess: () => {
        updateClient(auth.authClient);
        if (getIsLocal()) {
          auth.authClient.fetchRootKey();
        }
      },
    });
  };

  const logout = async () => {
    await auth.authClient?.logout();
    await updateClient(auth.authClient);
  }

  const defaultAgent = new HttpAgent(); // TODO: options
  if (getIsLocal()) {
    defaultAgent.fetchRootKey();
  }

  return <AuthContext.Provider value={{...auth, login, logout, defaultAgent}}>{props.children}</AuthContext.Provider>;
};

export const useAuth = () => useContext(AuthContext);