importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyACeIOXxORzeAmKSWPD6UoYDJ24gIDat6M",
  authDomain: "app-gestion-immo-benin.firebaseapp.com",
  projectId: "app-gestion-immo-benin",
  storageBucket: "app-gestion-immo-benin.firebasestorage.app",
  messagingSenderId: "351694266943",
  appId: "1:351694266943:web:aa1123b36eb5a5d1238e8a"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Message arrière-plan :", payload);

  self.registration.showNotification(
    payload.notification?.title ?? "LoyaSmart",
    {
      body: payload.notification?.body ?? "",
      icon: "/icons/Icon-192.png",
    }
  );
});