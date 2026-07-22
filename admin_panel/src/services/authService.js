import {
  getIdTokenResult,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
} from "firebase/auth";
import { auth } from "../firebase/firebaseConfig";

export function observeAuthentication(callback) {
  return onAuthStateChanged(auth, callback);
}

export async function signInAdministrator(email, password) {
  const credential = await signInWithEmailAndPassword(
    auth,
    email.trim(),
    password,
  );
  const tokenResult = await getIdTokenResult(credential.user, true);

  if (tokenResult.claims.admin !== true) {
    await firebaseSignOut(auth);
    const error = new Error("This account does not have administrator access.");
    error.code = "auth/not-an-admin";
    throw error;
  }

  return credential.user;
}

export async function verifyAdministrator(user) {
  const tokenResult = await getIdTokenResult(user, true);
  return tokenResult.claims.admin === true;
}

export function signOutAdministrator() {
  return firebaseSignOut(auth);
}

export function getLoginErrorMessage(error) {
  switch (error?.code) {
    case "auth/invalid-credential":
    case "auth/user-not-found":
    case "auth/wrong-password":
      return "The email or password is incorrect.";
    case "auth/invalid-email":
      return "Enter a valid email address.";
    case "auth/too-many-requests":
      return "Too many sign-in attempts. Please wait and try again.";
    case "auth/network-request-failed":
      return "Unable to reach Firebase. Check your internet connection.";
    case "auth/not-an-admin":
      return "This account does not have administrator access.";
    default:
      return "Sign-in failed. Please try again.";
  }
}
