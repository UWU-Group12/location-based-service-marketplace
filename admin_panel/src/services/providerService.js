import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

const validAccountStatuses = ["active", "suspended", "disabled"];

export async function getProviders() {
  const providersQuery = query(
    collection(db, "users"),
    where("role", "==", "provider"),
  );

  const [usersSnapshot, profilesSnapshot, categoriesSnapshot] =
    await Promise.all([
      getDocs(providersQuery),
      getDocs(collection(db, "providerProfiles")),
      getDocs(collection(db, "categories")),
    ]);

  const profilesById = new Map(
    profilesSnapshot.docs.map((profileDocument) => [
      profileDocument.id,
      profileDocument.data(),
    ]),
  );
  const categoryNamesById = new Map(
    categoriesSnapshot.docs.map((categoryDocument) => [
      categoryDocument.id,
      categoryDocument.data().name || categoryDocument.id,
    ]),
  );

  return usersSnapshot.docs
    .map((userDocument) => {
      const user = userDocument.data();
      const profile = profilesById.get(userDocument.id) || {};
      const categoryIds = Array.isArray(profile.categoryIds)
        ? profile.categoryIds
        : [];

      return {
        id: userDocument.id,
        ...user,
        profile,
        categoryIds,
        categoryNames: categoryIds.map(
          (categoryId) => categoryNamesById.get(categoryId) || categoryId,
        ),
      };
    })
    .sort((first, second) =>
      (first.displayName || first.profile.displayName || "").localeCompare(
        second.displayName || second.profile.displayName || "",
      ),
    );
}

export async function updateProviderAccountStatus(providerId, accountStatus) {
  if (!validAccountStatuses.includes(accountStatus)) {
    throw new Error("Invalid account status.");
  }

  await updateDoc(doc(db, "users", providerId), {
    accountStatus,
    updatedAt: serverTimestamp(),
  });
}

export async function updateProviderDetails(providerId, providerData) {
  const userUpdates = {};
  const profileUpdates = {};

  if (providerData.displayName !== undefined) {
    userUpdates.displayName = providerData.displayName;
  }

  if (providerData.email !== undefined) {
    userUpdates.email = providerData.email;
  }

  if (providerData.phoneNumber !== undefined) {
    userUpdates.phoneNumber = providerData.phoneNumber;
  }

  if (providerData.accountStatus !== undefined) {
    if (!validAccountStatuses.includes(providerData.accountStatus)) {
      throw new Error("Invalid account status.");
    }
    userUpdates.accountStatus = providerData.accountStatus;
  }

  if (providerData.profile) {
    Object.assign(profileUpdates, providerData.profile);
  }

  if (Object.keys(userUpdates).length > 0) {
    userUpdates.updatedAt = serverTimestamp();
    await updateDoc(doc(db, "users", providerId), userUpdates);
  }

  if (Object.keys(profileUpdates).length > 0) {
    const profileRef = doc(db, "providerProfiles", providerId);
    const profileSnapshot = await getDoc(profileRef);
    const existingProfile = profileSnapshot.exists() ? profileSnapshot.data() : {};

    await setDoc(
      profileRef,
      {
        ...existingProfile,
        ...profileUpdates,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  }
}
