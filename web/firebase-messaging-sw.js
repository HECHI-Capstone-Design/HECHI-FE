importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyC5Q_U96ril-fRApq7MDvbIl49fqCXa0Gk",
  authDomain: "hechibrown-4eecf.firebaseapp.com",
  projectId: "hechibrown-4eecf",
  storageBucket: "hechibrown-4eecf.firebasestorage.app",
  messagingSenderId: "146312337575",
  appId: "1:146312337575:web:b53f3d9fd644bde765e382",
  measurementId: "G-2E8WNSZ1LJ"
};
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();