import { Identity } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { Principal } from "@dfinity/principal";
import React, { createContext, useContext, useEffect, useState } from "react";

const AuthContext = createContext<{
  isAuthenticated: boolean,
  authClient?: AuthClient,
  identity?: Identity,
  principal?: Principal,
  login?: () => void,
  logout?: () => Promise<void>,
}>({isAuthenticated: false});

const defaultOptions = {
  /**
   *  @type {import("@dfinity/auth-client").AuthClientCreateOptions}
   */
  createOptions: {
    idleOptions: {
      // Set to true if you do not want idle functionality
      disableIdle: true,
    },
  },
  /**
   * @type {import("@dfinity/auth-client").AuthClientLoginOptions}
   */
  loginOptions: {
    identityProvider: // FIXME: NFID
      process.env.DFX_NETWORK === "ic"
        ? undefined
        : `http://localhost:8000/?canisterId=${process.env.CANISTER_ID_INTERNET_IDENTITY}`,
  },
};

/**
 *
 * @param options - Options for the AuthClient
 * @param {AuthClientCreateOptions} options.createOptions - Options for the AuthClient.create() method
 * @param {AuthClientLoginOptions} options.loginOptions - Options for the AuthClient.login() method
 * @returns
 */
export const useAuthClient = (options = defaultOptions) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authClient, setAuthClient] = useState<AuthClient | undefined>();
  const [identity, setIdentity] = useState<Identity | undefined>(undefined);
  const [principal, setPrincipal] = useState<Principal | undefined>(undefined);

  useEffect(() => {
    // Initialize AuthClient
    AuthClient.create(options.createOptions).then(async (client) => {
      updateClient(client);
    });
  }, []);

  // const loginImpl = () => {
  //   authClient!.login({
  //     ...options.loginOptions,
  //     onSuccess: () => {
  //       updateClient(authClient);
  //     },
  //   });
  // };

  async function updateClient(client) {
    const isAuthenticated = await client.isAuthenticated();
    setIsAuthenticated(isAuthenticated);

    const identity = client.getIdentity();
    setIdentity(identity);

    const principal = identity.getPrincipal();
    setPrincipal(principal);

    setAuthClient(client);
    console.log("AuthClient set: ", client)
  }

  // async function logoutImpl() {
  //   await authClient?.logout();
  //   await updateClient(authClient);
  // }

  return {
    isAuthenticated,
    // login,
    // logout,
    authClient,
    identity,
    principal,
  };
};

/**
 * @type {React.FC}
 */
export function AuthProvider(props: { children: any }) {
  const auth = useAuthClient();
  return <AuthContext.Provider value={auth}>{props.children}</AuthContext.Provider>;
};

export const useAuth = () => useContext(AuthContext);