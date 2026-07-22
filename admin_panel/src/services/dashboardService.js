import {
  collection,
  getCountFromServer,
  getDoc,
  getDocs,
  doc,
  query,
  where,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

export async function getDashboardData() {
  const customersQuery = query(
    collection(db, "users"),
    where("role", "==", "customer"),
  );
  const providersQuery = query(
    collection(db, "users"),
    where("role", "==", "provider"),
  );
  const pendingQuery = query(
    collection(db, "providerVerifications"),
    where("status", "==", "pending"),
  );
  const activeCategoriesQuery = query(
    collection(db, "categories"),
    where("active", "==", true),
  );

  const [
    customersCount,
    providersCount,
    pendingCount,
    activeCategoriesCount,
    pendingSnapshot,
  ] = await Promise.all([
    getCountFromServer(customersQuery),
    getCountFromServer(providersQuery),
    getCountFromServer(pendingQuery),
    getCountFromServer(activeCategoriesQuery),
    getDocs(pendingQuery),
  ]);

  const recentDocuments = pendingSnapshot.docs
    .sort((first, second) => {
      const firstDate = first.data().submittedAt?.toMillis?.() ?? 0;
      const secondDate = second.data().submittedAt?.toMillis?.() ?? 0;
      return secondDate - firstDate;
    })
    .slice(0, 5);

  const recentPendingVerifications = await Promise.all(
    recentDocuments.map(async (verificationDocument) => {
      const verification = verificationDocument.data();
      const providerId = verification.providerId || verificationDocument.id;
      const userDocument = await getDoc(doc(db, "users", providerId));

      return {
        id: verificationDocument.id,
        providerId,
        providerName:
          userDocument.data()?.displayName || "Unnamed provider",
        submittedAt: verification.submittedAt,
        documentType: verification.documentType,
        status: verification.status,
      };
    }),
  );

  return {
    totals: {
      customers: customersCount.data().count,
      providers: providersCount.data().count,
      pendingVerifications: pendingCount.data().count,
      activeCategories: activeCategoriesCount.data().count,
    },
    recentPendingVerifications,
  };
}
