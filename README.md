# CampusFix — Campus Incident Reporting App

CampusFix lets ALU students report campus issues (broken facilities, water
shortages, power outages, damaged furniture, sanitation, safety, Wi-Fi) and
track them until they are resolved. Authorised campus staff triage reports and
update their status, and every change shows up on the reporter's timeline.

Built with **Flutter**, **Provider** state management, **Firebase
Authentication**, **Cloud Firestore** and **Firebase Storage**.

---

## Features

| Area | What it does |
|------|--------------|
| **Authentication** | Register / sign in / sign out / password reset. Only `@alustudent.com` and `@alueducation.com` emails are accepted, and the app stays locked until the email is **verified**. Sessions persist across restarts. |
| **Report an incident** | Category grid, title, description, campus location + room detail, urgency, optional photo (camera or gallery), and an **anonymous** option. Full form validation with inline errors. |
| **Duplicate prevention** | When you pick a category and location that already have open reports, the form suggests them so you can tap **"Me too"** instead of filing a duplicate. |
| **Browse & filter** | "My Reports" vs "Campus Feed", free-text search, status filter chips and a category filter sheet. |
| **Details & tracking** | Status chip, urgency, vertical status timeline with staff notes, description, full-screen photo viewer, "Me too" count. |
| **Edit / withdraw** | Reporters can edit or withdraw a report until staff start reviewing it. |
| **Staff console** | Staff see a campus-wide triage queue (urgent first, then oldest), and can move reports through `Submitted → Under Review → In Progress → Resolved` (or `Rejected`). Resolving/rejecting requires a note to the reporter. Staff can remove spam/abusive reports. |
| **Updates feed** | A notification-style feed of staff actions on your reports, plus a badge on the home bell. |

## Repository layout

```
.
├── lib/                 # Flutter app source (see Architecture below)
├── test/                # Unit + widget tests (fakes in test/helpers/)
├── android/  ios/       # Platform projects (Firebase config included)
├── docs/                # Report assets: screenshots, diagrams
├── firestore.rules      # Firestore security rules (role-based access)
├── storage.rules        # Storage security rules (photo uploads)
├── firebase.json        # Firebase CLI config (rules deploy targets)
├── .firebaserc          # Default Firebase project: campusfix-nchris
└── pubspec.yaml         # Dependencies
```

Repository: <https://github.com/Gakindi1/Campus-Incident-Reporting-App>

## Architecture

```
lib/
├── main.dart                 # Firebase init
├── app.dart                  # Composition root: MultiProvider wiring
├── core/
│   ├── theme/                # Colours, ThemeData, status/category styling
│   └── utils/                # Validators, date formatting, snackbars/dialogs
├── models/                   # Incident, StatusChange, AppUser, enums (pure data)
├── services/                 # Data layer: Firebase Auth, Firestore, Storage
│   ├── auth_service.dart
│   ├── incident_repository.dart   # abstract + Firestore implementation
│   └── storage_service.dart
├── providers/                # State management (ChangeNotifier)
│   ├── auth_provider.dart         # session + profile/role
│   ├── incident_provider.dart     # live incidents, filters, commands
│   └── report_form_controller.dart# screen-scoped form state
├── screens/                  # UI only; read/act through providers
│   ├── auth/  home/  reports/  report_form/  details/
│   ├── notifications/  profile/  shell/
└── widgets/                  # Reusable components (cards, chips, timeline…)
```

**Data flow:** `Screens → Providers → Services → Firebase`. Screens never call
Firebase directly. `IncidentProvider` holds a single real-time Firestore
subscription, so a status change made by staff appears instantly on the
dashboard, the list, the details screen and the updates feed of every signed-in
device. `IncidentProvider` depends on the abstract `IncidentRepository`, which
lets the business rules be unit-tested with an in-memory fake.

## Firestore data model

```
users/{uid}
  fullName: string
  email: string
  role: "student" | "staff"      # never writable by the client
  createdAt: timestamp

incidents/{incidentId}
  title, description: string
  category: "facilities" | "water" | "electricity" | "safety" |
            "sanitation" | "internet" | "furniture" | "other"
  status:   "submitted" | "underReview" | "inProgress" | "resolved" | "rejected"
  priority: "low" | "medium" | "high"
  location, locationDetail: string
  imageUrl, imagePath: string | null     # Storage download URL + path
  reporterId: string (uid)
  reporterName: string                   # "Anonymous student" if anonymous
  isAnonymous: bool
  supporters: [uid]                      # "Me too"
  statusHistory: [{ status, changedAt, changedById, changedByName, note? }]
  createdAt, updatedAt: timestamp (server)
```

Storage: `incidents/{uid}/{incidentId}/{timestamp}.jpg`

## Firebase setup

1. Create a project at <https://console.firebase.google.com>.
2. **Authentication → Sign-in method:** enable **Email/Password**.
3. **Firestore Database:** create a database (production mode).
4. **Storage:** create the default bucket (requires the Blaze plan on new
   projects; the free tier allowance still applies).
5. Install the CLIs and generate `lib/firebase_options.dart`
   (this overwrites the placeholder in the repo):
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure        # select your project, Android + iOS
   ```
6. Deploy the security rules (or paste them into the console's Rules tabs):
   ```bash
   firebase init firestore storage   # keep the existing .rules files
   firebase deploy --only firestore:rules,storage
   ```
7. Run on an emulator or device:
   ```bash
   flutter pub get
   flutter run
   ```

### Creating a staff account

New accounts are always students; the rules forbid clients from changing
their own role. To create a staff account:

1. Register in the app with an ALU email and verify it.
2. Firebase Console → Firestore → `users/{that uid}` → change `role` to `staff`.
3. The app switches to the staff console live (no restart needed).

## Testing

```bash
flutter test      # 30 unit + widget tests
flutter analyze   # static analysis (no issues)
```

- `test/validators_test.dart`: ALU email domain, password and form rules
- `test/incident_model_test.dart`: Firestore mapping and the status workflow
- `test/incident_provider_test.dart`: filtering, search, summaries, staff
  queue, submit/edit/delete, role checks, status transitions, "Me too",
  orphaned-photo clean-up. Uses fake repository and storage implementations.
- `test/widgets_test.dart`: reusable widgets render and respond to taps
