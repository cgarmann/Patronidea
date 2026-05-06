# Share Your Idea! — Project Bible

## What this is
A high-end, secure idea marketplace for Android built with Flutter + Firebase.
- **Innovators** submit ideas; protected by the Smart Engine (de-duplication via Cloud Functions).
- **Patrons** pay to browse, purchase ideas, or request partnership pitches.

## Tech Stack
| Layer | Choice |
|---|---|
| UI | Flutter (Dart) |
| Backend | Firebase (Firestore, Auth, Cloud Functions, Storage) |
| Auth | Firebase Auth — Email/Password + Google Sign-In |
| Payments | Google Play Billing (subscriptions) + Stripe (idea purchases) |
| Smart Engine | Firebase Cloud Functions (Node.js 20) |

## Visual Identity
- Dark Mode: Futuristic/Exclusive — primary background `#0A0A0F`
- Light Mode: Clean/Trustworthy — primary background `#F8F9FC`
- Accent Cyan: `#00E5FF` | Accent Purple: `#6200EA`
- Aesthetic reference: Stripe / Linear

## Project Structure
```
Share idea/
├── CLAUDE.md                  ← you are here
├── .gitignore
├── firebase/
│   ├── firestore.rules        ← security rules
│   ├── firestore.indexes.json
│   └── functions/             ← Smart Engine (Node.js)
│       ├── package.json
│       └── index.js
└── share_idea_app/            ← Flutter project root
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── theme/         ← AppTheme, AppColors
        │   ├── constants/
        │   └── router/        ← GoRouter
        ├── models/            ← UserModel, IdeaModel, PitchModel
        ├── services/          ← AuthService, IdeaService, SmartEngineService
        ├── providers/         ← Riverpod providers
        └── screens/
            ├── gateway/
            ├── auth/
            ├── innovator/
            ├── patron/
            ├── pitch/
            └── shared/
```

## Firestore Schema
```
users/{uid}
  displayName: string
  email: string
  role: 'innovator' | 'patron' | 'both'
  isActivePatron: bool
  subscriptionExpiry: timestamp | null
  createdAt: timestamp

ideas/{ideaId}
  title: string          (max 15 words)
  body: string           (max 150 words)
  category: string
  status: 'processing' | 'active' | 'sold'
  hash: string           (SHA-256 fingerprint for de-dup)
  uniquenessScore: number (0–100)
  innovatorId: string    (uid — hidden from Patrons until pitch accepted)
  price: number          (USD cents)
  createdAt: timestamp
  updatedAt: timestamp

pitches/{pitchId}
  ideaId: string
  patronId: string
  innovatorId: string
  status: 'pending' | 'accepted' | 'rejected' | 'completed'
  patronMessage: string
  innovatorPitch: string (max 150 words — written after acceptance)
  contactEmail: string   (revealed only after pitch accepted)
  createdAt: timestamp

subscriptions/{uid}
  status: 'active' | 'expired' | 'cancelled'
  planId: string
  startDate: timestamp
  endDate: timestamp
```

## Development Commands
```bash
# Run app
cd share_idea_app && flutter run

# Deploy Firebase rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions

# Build Android APK
cd share_idea_app && flutter build apk --release
```

## Key Decisions
- **No view counts** on Innovator dashboard — keeps it exclusive
- **Anonymity by default** — innovatorId never exposed until pitch flow completes
- **>85% similarity = rejected** in Smart Engine
- Idea purchase removes it from the public vault (SOLD status)
- All financial transactions validated server-side via Cloud Functions
