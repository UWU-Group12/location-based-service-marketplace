# Raw Administrator Panel

A focused React and Vite administrator panel for the Raw university project.

## Included routes

- `/login`
- `/dashboard`
- `/customers`
- `/providers`
- `/provider-verifications`
- `/categories`

The app uses only the `users`, `providerProfiles`, `providerVerifications`, and `categories` Firestore collections.

## Local setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Copy `.env.example` to `.env.local`.

3. Add the Firebase web-app values from Firebase Console:

   ```text
   VITE_FIREBASE_API_KEY
   VITE_FIREBASE_AUTH_DOMAIN
   VITE_FIREBASE_PROJECT_ID
   VITE_FIREBASE_STORAGE_BUCKET
   VITE_FIREBASE_MESSAGING_SENDER_ID
   VITE_FIREBASE_APP_ID
   ```

4. Start the development server:

   ```bash
   npm run dev
   ```

These Firebase web values identify the Firebase project; never add service-account JSON, private keys, or Admin SDK credentials to this frontend.

## Administrator access

The login accepts Firebase email/password accounts only. The signed-in account must have this Firebase Authentication custom claim:

```json
{
  "admin": true
}
```

Set custom claims only from a trusted server environment, Cloud Function, or one-time administration script that is kept outside this React app. After adding a claim, sign out and sign in again so Firebase issues a refreshed ID token.

Protected React routes improve the user experience, while the rules in `../firebase/firestore.rules` and `../firebase/storage.rules` enforce the real administrator permissions.

## Checks

```bash
npm run lint
npm run build
```

Deploy Firebase rules from the `firebase` directory only after reviewing them against the target Firebase project.
