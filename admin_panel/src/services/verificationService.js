import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  where,
  writeBatch,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

const reviewStatuses = ["pending", "verified", "rejected"];

export async function getVerificationSubmissions({
  status = "pending",
  providerId = "",
} = {}) {
  let verificationDocuments;

  if (providerId) {
    const selectedDocument = await getDoc(
      doc(db, "providerVerifications", providerId),
    );
    verificationDocuments = selectedDocument.exists() ? [selectedDocument] : [];
  } else {
    if (!reviewStatuses.includes(status)) {
      throw new Error("Invalid verification filter.");
    }

    const snapshot = await getDocs(
      query(
        collection(db, "providerVerifications"),
        where("status", "==", status),
      ),
    );
    verificationDocuments = snapshot.docs;
  }

  const submissions = await Promise.all(
    verificationDocuments.map(async (verificationDocument) => {
      const verification = verificationDocument.data();
      const resolvedProviderId =
        verification.providerId || verificationDocument.id;
      const [userDocument, profileDocument] = await Promise.all([
        getDoc(doc(db, "users", resolvedProviderId)),
        getDoc(doc(db, "providerProfiles", resolvedProviderId)),
      ]);

      return {
        id: verificationDocument.id,
        providerId: resolvedProviderId,
        ...verification,
        user: userDocument.exists() ? userDocument.data() : {},
        profile: profileDocument.exists() ? profileDocument.data() : {},
      };
    }),
  );

  return submissions.sort((first, second) => {
    const firstDate = first.submittedAt?.toMillis?.() ?? 0;
    const secondDate = second.submittedAt?.toMillis?.() ?? 0;
    return secondDate - firstDate;
  });
}

export async function reviewProviderVerification({
  providerId,
  decision,
  administratorId,
  rejectionReason = "",
}) {
  if (!["verified", "rejected"].includes(decision)) {
    throw new Error("Invalid verification decision.");
  }

  const cleanReason = rejectionReason.trim();
  if (decision === "rejected" && !cleanReason) {
    throw new Error("A rejection reason is required.");
  }

  const verificationReference = doc(
    db,
    "providerVerifications",
    providerId,
  );
  const profileReference = doc(db, "providerProfiles", providerId);
  const batch = writeBatch(db);

  batch.update(verificationReference, {
    status: decision,
    reviewedBy: administratorId,
    reviewedAt: serverTimestamp(),
    rejectionReason: decision === "rejected" ? cleanReason : null,
  });
  batch.update(profileReference, {
    verificationStatus: decision,
    updatedAt: serverTimestamp(),
  });

  await batch.commit();
}
