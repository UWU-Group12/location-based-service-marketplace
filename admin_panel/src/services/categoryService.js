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

export async function getCategories() {
  const snapshot = await getDocs(
    query(collection(db, "categories"), orderBy("sortOrder", "asc")),
  );

  return snapshot.docs.map((categoryDocument) => ({
    id: categoryDocument.id,
    ...categoryDocument.data(),
  }));
}

export async function createCategory(category) {
  const categoryId = createCategorySlug(category.name);
  const categoryReference = doc(db, "categories", categoryId);
  const existingCategory = await getDoc(categoryReference);

  if (existingCategory.exists()) {
    const error = new Error("A category with this name already exists.");
    error.code = "category/already-exists";
    throw error;
  }

  await setDoc(categoryReference, cleanCategoryData(category));
  return categoryId;
}

export async function updateCategory(categoryId, category) {
  await updateDoc(
    doc(db, "categories", categoryId),
    cleanCategoryData(category),
  );
}

export async function setCategoryActive(categoryId, active) {
  await updateDoc(doc(db, "categories", categoryId), { active });
}

function cleanCategoryData(category) {
  return {
    name: category.name.trim(),
    description: category.description.trim(),
    iconPath: category.iconPath.trim(),
    active: Boolean(category.active),
    sortOrder: Number(category.sortOrder),
  };
}

function createCategorySlug(name) {
  const slug = name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  if (!slug) {
    throw new Error("Enter a category name containing letters or numbers.");
  }

  return slug;
}
