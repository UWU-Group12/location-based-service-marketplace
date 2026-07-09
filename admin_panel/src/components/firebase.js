import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

// ඔයාගේ screen එකේ තිබුණු ඇත්තම configuration විස්තර ටික
const firebaseConfig = {
  apiKey: "AIzaSyDW7IWGr_dzBK-0GtZq3KyXODIP3aRV2zw",
  authDomain: "location-based-service-8d896.firebaseapp.com",
  projectId: "location-based-service-8d896",
  storageBucket: "location-based-service-8d896.firebasestorage.app",
  messagingSenderId: "414337662335",
  appId: "1:414337662335:web:c7abdc1bad4efdd2c5ee4a",
  measurementId: "G-SL2Q89HQZE"
};

// Firebase initialize කරලා export කරනවා
const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);