import { getDownloadURL, ref } from "firebase/storage";
import { storage } from "../firebase/firebaseConfig";

export async function getAuthorizedFileUrl(filePath) {
  if (!filePath) {
    throw new Error("The document path is missing.");
  }

  if (/^https?:\/\//i.test(filePath)) {
    return filePath;
  }

  return getDownloadURL(ref(storage, filePath));
}
