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
import { ref, uploadBytes } from "firebase/storage";
import { db, storage } from "../firebase/firebaseConfig";

const validAccountStatuses = ["active", "suspended", "disabled"];

export async function uploadProviderProfilePhoto(providerId, file) {
  if (!file) {
    return null;
  }

  const extension =
    (file.name && file.name.includes("."))
      ? file.name.split(".").pop() || "jpg"
      : file.type?.split("/")[1] || "jpg";
  const photoPath = `providers/${providerId}/profile.${extension}`;
  const profileImageRef = ref(storage, photoPath);

  await uploadBytes(profileImageRef, file);
  return photoPath;
}

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

export async function createProvider(providerData) {
  const displayName = (providerData.displayName || "").trim();
  const email = (providerData.email || "").trim();

  if (!displayName) {
    throw new Error("Provider name is required.");
  }

  if (!email) {
    throw new Error("Provider email is required.");
  }

  const userRef = doc(collection(db, "users"));
  const providerId = userRef.id;
  const categoryIds = Array.isArray(providerData.categoryIds)
    ? providerData.categoryIds
    : (providerData.categories || "")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);

  const photoPath = (providerData.photoPath || "").trim();

  await setDoc(userRef, {
    id: providerId,
    displayName,
    email,
    phoneNumber: (providerData.phoneNumber || "").trim(),
    role: "provider",
    accountStatus: validAccountStatuses.includes(providerData.accountStatus)
      ? providerData.accountStatus
      : "active",
    photoPath: photoPath || null,
    profileCompleted: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  await setDoc(
    doc(db, "providerProfiles", providerId),
    {
      providerId,
      displayName,
      bio: (providerData.bio || "").trim(),
      profileImagePath: photoPath || providerData.profileImagePath || null,
      categoryIds,
      experienceYears: Number(providerData.experienceYears || 0),
      workingDays: Array.isArray(providerData.workingDays)
        ? providerData.workingDays
        : ["Mon", "Tue", "Wed", "Thu", "Fri"],
      workingHours: providerData.workingHours || "Full Day",
      serviceRadiusKm: Number(providerData.serviceRadiusKm || 10),
      availabilityStatus: providerData.availabilityStatus || "unavailable",
      verificationStatus: providerData.verificationStatus || "not_submitted",
      ratingAverage: 0,
      reviewCount: 0,
      completedJobCount: 0,
      baseLocation: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );

  return {
    id: providerId,
    displayName,
    email,
    phoneNumber: (providerData.phoneNumber || "").trim(),
    role: "provider",
    accountStatus: validAccountStatuses.includes(providerData.accountStatus)
      ? providerData.accountStatus
      : "active",
    photoPath: photoPath || null,
    profileCompleted: true,
    profile: {
      providerId,
      displayName,
      bio: (providerData.bio || "").trim(),
      profileImagePath: photoPath || providerData.profileImagePath || null,
      categoryIds,
      experienceYears: Number(providerData.experienceYears || 0),
      workingDays: Array.isArray(providerData.workingDays)
        ? providerData.workingDays
        : ["Mon", "Tue", "Wed", "Thu", "Fri"],
      workingHours: providerData.workingHours || "Full Day",
      serviceRadiusKm: Number(providerData.serviceRadiusKm || 10),
      availabilityStatus: providerData.availabilityStatus || "unavailable",
      verificationStatus: providerData.verificationStatus || "not_submitted",
      ratingAverage: 0,
      reviewCount: 0,
      completedJobCount: 0,
      baseLocation: null,
    },
    categoryIds,
    categoryNames: categoryIds,
  };
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

  if (providerData.photoPath !== undefined) {
    userUpdates.photoPath = providerData.photoPath || null;
  }

  if (providerData.profile) {
    Object.assign(profileUpdates, providerData.profile);
  }

  if (providerData.profileImagePath !== undefined) {
    profileUpdates.profileImagePath = providerData.profileImagePath || null;
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
