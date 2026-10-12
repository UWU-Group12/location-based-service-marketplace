import {
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

export async function getLocations() {
  const snapshot = await getDocs(
    query(collection(db, "locations"), orderBy("name", "asc")),
  );

  return snapshot.docs.map((locationDocument) => ({
    id: locationDocument.id,
    ...locationDocument.data(),
  }));
}

export async function createLocation(locationId, location) {
  const locationReference = doc(db, "locations", locationId);
  const existingLocation = await getDoc(locationReference);

  if (existingLocation.exists()) {
    const error = new Error("A location with this ID already exists.");
    error.code = "location/already-exists";
    throw error;
  }

  await setDoc(locationReference, cleanLocationData(location));
}

export async function updateLocation(locationId, location) {
  await updateDoc(
    doc(db, "locations", locationId),
    cleanLocationData(location),
  );
}

export async function setLocationActive(locationId, active) {
  await updateDoc(doc(db, "locations", locationId), { active });
}

function cleanLocationData(location) {
  return {
    name: location.name.trim(),
    district: location.district.trim(),
    province: location.province.trim(),
    active: Boolean(location.active),
  };
}