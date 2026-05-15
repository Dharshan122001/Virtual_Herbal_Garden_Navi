// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAuth } from 'firebase/auth';
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyC9HL5pZZT5BJsVUBIImxD0nJBtxT1P2DQ",
  authDomain: "virtual-herbal-garden-44579.firebaseapp.com",
  projectId: "virtual-herbal-garden-44579",
  storageBucket: "virtual-herbal-garden-44579.firebasestorage.app",
  messagingSenderId: "491680937929",
  appId: "1:491680937929:web:f5000b9bdae3297f63da18"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);