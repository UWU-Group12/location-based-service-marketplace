import { useEffect, useState } from "react";
import AuthContext from "./AuthContextObject";
import {
  observeAuthentication,
  signInAdministrator,
  signOutAdministrator,
  verifyAdministrator,
} from "../services/authService";

export function AuthProvider({ children }) {
  const [currentAdmin, setCurrentAdmin] = useState(null);
  const [isAuthLoading, setIsAuthLoading] = useState(true);
  const [accessError, setAccessError] = useState("");

  useEffect(() => {
    let isActive = true;

    const unsubscribe = observeAuthentication(async (user) => {
      if (!user) {
        if (isActive) {
          setCurrentAdmin(null);
          setIsAuthLoading(false);
        }
        return;
      }

      try {
        const isAdministrator = await verifyAdministrator(user);

        if (!isAdministrator) {
          await signOutAdministrator();
          if (isActive) {
            setAccessError("This account does not have administrator access.");
            setCurrentAdmin(null);
          }
          return;
        }

        if (isActive) {
          setAccessError("");
          setCurrentAdmin(user);
        }
      } catch (error) {
        console.error("Administrator permission check failed:", error);
        await signOutAdministrator();
        if (isActive) {
          setAccessError(
            "Administrator access could not be verified. Please sign in again.",
          );
          setCurrentAdmin(null);
        }
      } finally {
        if (isActive) {
          setIsAuthLoading(false);
        }
      }
    });

    return () => {
      isActive = false;
      unsubscribe();
    };
  }, []);

  async function login(email, password) {
    setAccessError("");
    const user = await signInAdministrator(email, password);
    setCurrentAdmin(user);
    return user;
  }

  async function logout() {
    await signOutAdministrator();
    setCurrentAdmin(null);
  }

  const value = {
    accessError,
    clearAccessError: () => setAccessError(""),
    currentAdmin,
    isAuthLoading,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
