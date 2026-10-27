# Blood4U

Blood4U is a Flutter app intended to help blood donors and people seeking blood connect with one another and with local hospitals. The repository's existing Firebase and Google Maps configuration points to the `blood4u-8249a` Firebase project.

## What works in the app

- Email and password account creation and sign-in.
- A donor directory that lists a person only after they opt in from their profile.
- Private profile records: email addresses and phone numbers are not copied into the public donor directory.
- One-to-one conversations whose messages are visible only to the two participants.
- Open blood requests with hospital, area, and blood type; request owners can close their requests, and other signed-in users can offer help through chat.
- A user-triggered map view that shows the user's location on the device. The location is not written to Firestore.

Blood4U is a communication tool, not an emergency service or medical advice. Contact a hospital or local emergency service directly for urgent care. Keep patient names, contact details, and diagnoses out of blood request details.

## Run locally

1. Install Flutter and the Android or iOS toolchain.
2. Enable Email/Password sign-in in the Firebase project and create a Firestore database.
3. Install packages and start the app:

   ```sh
   flutter pub get
   flutter run
   ```

4. Configure Google Maps for the platform you use. Android currently has the repository's existing key in `android/app/src/main/AndroidManifest.xml`; restrict it to this app's package and signing certificate in Google Cloud. iOS needs its own restricted Maps SDK key before the map screen can render.

The existing Android application ID is retained because it is part of the current Firebase/Maps configuration. Re-register the Firebase apps before changing platform IDs.

## Firestore setup and privacy

The client data model uses these collections:

- `users/{uid}` stores that user's private profile.
- `donors_public/{uid}` stores only the name, blood type, area, and opt-in status needed for the signed-in donor directory.
- `blood_requests/{requestId}` stores open requests visible to signed-in users.
- `conversations/{conversationId}/messages/{messageId}` stores messages shared only with the conversation participants.

Review and deploy the included `firestore.rules` to the Firebase project before allowing real accounts to use the app. The app does not deploy rules or change Firebase data automatically. There is no production or synthetic donor data checked in.

## Current scope

The repo does not contain a hospital directory or hospital verification workflow. The map currently shows the consenting user's own location only; it does not show donors or hospitals. Push notifications, voice/video calls, and profile photos are not connected to the app flow yet. These capabilities need their own data sources and platform setup before they can be represented as working features.
