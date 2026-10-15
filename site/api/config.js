// Public Firebase web config (shared 'yourappisdead' project) and optional download URL, read from env at request time.
module.exports = (req, res) => {
  const e = k => process.env[k] || undefined;
  const firebase = e("NEXT_PUBLIC_FIREBASE_API_KEY") && e("NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN") && e("NEXT_PUBLIC_FIREBASE_PROJECT_ID") && e("NEXT_PUBLIC_FIREBASE_APP_ID")
    ? { apiKey: e("NEXT_PUBLIC_FIREBASE_API_KEY"), authDomain: e("NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN"), projectId: e("NEXT_PUBLIC_FIREBASE_PROJECT_ID"),
        appId: e("NEXT_PUBLIC_FIREBASE_APP_ID"), messagingSenderId: e("NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID"), storageBucket: e("NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET") }
    : null;
  res.setHeader("cache-control", "public, max-age=300");
  res.status(200).json({ firebase: e("FIREBASE_SERVICE_ACCOUNT_JSON") ? firebase : null, downloadUrl: e("WFID_DOWNLOAD_URL") ?? null });
};
