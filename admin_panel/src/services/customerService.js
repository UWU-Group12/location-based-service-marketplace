import {
  createUserWithEmailAndPassword,
  deleteUser,
  signOut as firebaseSignOut,
} from "firebase/auth";
import {
  collection,
  doc,
  getCountFromServer,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";
import { db, getProvisioningAuth } from "../firebase/firebaseConfig";

const validAccountStatuses = ["active", "suspended", "disabled"];

export async function getCustomers() {
  const customersQuery = query(
    collection(db, "users"),
    where("role", "==", "customer"),
  );
  const snapshot = await getDocs(customersQuery);

  return snapshot.docs
    .map((customerDocument) => ({
      id: customerDocument.id,
      ...customerDocument.data(),
    }))
    .sort((first, second) =>
      (first.displayName || "").localeCompare(second.displayName || ""),
    );
}

export async function updateCustomerAccountStatus(customerId, accountStatus) {
  if (!validAccountStatuses.includes(accountStatus)) {
    throw new Error("Invalid account status.");
  }

  await updateDoc(doc(db, "users", customerId), {
    accountStatus,
    updatedAt: serverTimestamp(),
  });
}

export async function getCustomerRequestCount(customerId) {
  const requestsQuery = query(
    collection(db, "serviceRequests"),
    where("customerId", "==", customerId),
  );
  const snapshot = await getCountFromServer(requestsQuery);

  return snapshot.data().count;
}

export async function updateCustomerDetails(customerId, details) {
  const displayName = String(details.displayName || "").trim();

  if (!displayName) {
    throw new Error("Customer name is required.");
  }

  const updates = {
    displayName,
    profileCompleted: Boolean(details.profileCompleted),
  };
  const phoneNumber = String(details.phoneNumber || "").trim();

  // Mirrors cleanCustomerData: a blank phone number leaves the stored value
  // untouched rather than clearing it.
  if (phoneNumber) {
    updates.phoneNumber = phoneNumber;
  }

  await updateDoc(doc(db, "users", customerId), {
    ...updates,
    updatedAt: serverTimestamp(),
  });
}

export async function createCustomerAccount(customer) {
  const displayName = String(customer.displayName || "").trim();
  const email = String(customer.email || "").trim();
  const password = customer.password;

  if (!displayName || !email || !password) {
    const error = new Error("Name, email, and password are required.");
    error.code = "customer/invalid-input";
    throw error;
  }

  const provisioningAuth = getProvisioningAuth();
  const credential = await createUserWithEmailAndPassword(
    provisioningAuth,
    email,
    password,
  );
  const customerId = credential.user.uid;

  try {
    await setDoc(
      doc(db, "users", customerId),
      cleanCustomerData({ ...customer, displayName, email }),
    );
  } catch (error) {
    // Remove the half-created sign-in account so no orphan is left behind.
    await deleteUser(provisioningAuth, credential.user).catch(() => {});
    throw error;
  } finally {
    await firebaseSignOut(provisioningAuth).catch(() => {});
  }

  return customerId;
}

function cleanCustomerData(customer) {
  const phoneNumber = String(customer.phoneNumber || "").trim();

  return {
    displayName: customer.displayName,
    email: customer.email,
    ...(phoneNumber ? { phoneNumber } : {}),
    role: "customer",
    accountStatus: validAccountStatuses.includes(customer.accountStatus)
      ? customer.accountStatus
      : "active",
    profileCompleted: Boolean(customer.profileCompleted),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}
