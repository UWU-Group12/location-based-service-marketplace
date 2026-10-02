import {
  collection,
  doc,
  getDocs,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

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
