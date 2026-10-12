import { getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getFunctions } from "firebase/functions";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const missingVariables = Object.entries(firebaseConfig)
  .filter(([, value]) => !value)
  .map(([name]) => name);

if (missingVariables.length > 0) {
  console.warn(
    `Firebase configuration is incomplete. Missing values: ${missingVariables.join(", ")}`,
  );
}

const firebaseApp = initializeApp(firebaseConfig);

export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
export const storage = getStorage(firebaseApp);
// Same region as the deployed Cloud Functions (firebase/functions/index.js).
export const functions = getFunctions(firebaseApp, "asia-south1");

const provisioningAppName = "customerProvisioning";

let provisioningAuth = null;

// Firebase stores the browser session per app name, so signing in on this
// secondary instance leaves the administrator session on `auth` untouched.
// This lets the panel provision customer sign-in accounts without a backend.
export function getProvisioningAuth() {
  if (provisioningAuth) {
    return provisioningAuth;
  }

  const existingApp = getApps().find(
    (registeredApp) => registeredApp.name === provisioningAppName,
  );
  const provisioningApp =
    existingApp ?? initializeApp(firebaseConfig, provisioningAppName);

  provisioningAuth = getAuth(provisioningApp);
  return provisioningAuth;
}
