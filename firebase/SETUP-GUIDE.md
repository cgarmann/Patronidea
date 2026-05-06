# Firebase Setup Guide — fra null til kjørende
**For:** Share Your Idea!
**Sist oppdatert:** 2026-05-03

Denne guiden tar deg fra «aldri rørt Firebase» til en sikker konfigurasjon klar for utvikling. Følg rekkefølgen — noen valg kan ikke endres etterpå.

---

## Mental modell: Console vs. Kode

Firebase har to «steder» du jobber:

**Firebase Console (web)** — `console.firebase.google.com`
Dette er kontrollpanelet i nettleser. Her oppretter du prosjektet, slår på tjenester (Auth, Firestore, Storage), velger region, og ser data og logger.

**Lokal kode + Firebase CLI** — i prosjektmappen din
Sikkerhetsregler (`firestore.rules`), Cloud Functions, og indekser leveres som *kode*. Du redigerer filer lokalt, sjekker dem inn i git, og deployer med `firebase deploy`. Du redigerer dem *aldri* direkte i Console (selv om Console har en editor — bruk den kun for å lese).

Tommelfingerregel: alt som er versjonsbart og må reviewes går i kode. Alt som er klikk-konfigurasjon (slå på en tjeneste, skifte plan) gjøres i Console.

---

## Steg 0: Forberedelser

Du trenger:
- En Google-konto (bruk den samme du vil eie prosjektet med — kan ikke flyttes uten å migrere alt)
- Node.js installert lokalt (versjon 20 eller nyere)
- Et betalingskort — Firebase er gratis i utgangspunktet, men du må aktivere Blaze-planen (pay-as-you-go) for å bruke Cloud Functions. I praksis koster den 0 kr i utvikling.

Installer Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

---

## Steg 1: Opprett tre prosjekter

Du trenger tre separate Firebase-prosjekter. Aldri test mot prod, aldri ekte data i dev.

I Console:
1. Gå til `console.firebase.google.com`
2. Klikk **Add project**
3. Navn: `shareidea-dev` → opprett
4. Gjenta for `shareidea-staging` og `shareidea-prod`

Når du oppretter: slå *av* Google Analytics for dev og staging (mindre støy). Slå *på* for prod.

---

## Steg 2: Velg region (KRITISK — kan ikke endres senere)

For hvert prosjekt:
1. I Console, gå til **Build → Firestore Database**
2. Klikk **Create database**
3. Velg **Start in production mode** (lås alt ned fra start)
4. **Location:** velg `europe-west1 (Belgium)` eller `europe-north1 (Finland)`
5. Klikk **Enable**

Hvis du klikker feil her er den eneste fixen å slette prosjektet og starte på nytt. Velg `europe-west1` med mindre du har en grunn til noe annet.

Gjør det samme for **Build → Storage** når du kommer dit (samme region).

---

## Steg 3: Slå på Authentication

I Console, for hvert prosjekt:
1. Gå til **Build → Authentication**
2. Klikk **Get started**
3. Under **Sign-in method**, slå på:
   - **Email/Password** — også slå på «Email link (passwordless sign-in)» hvis du vil
   - **Google** — krever du fyller inn project support email
4. Under **Settings → User actions**, sett:
   - **Email enumeration protection: Enabled** (hindrer angripere å sjekke om e-post er registrert)
5. Under **Templates**, oversett verifiserings-e-post og passordreset til norsk

For prod-prosjektet i tillegg:
6. Under **Settings → Authorized domains**, fjern `localhost` etter at appen er live (kan beholdes i dev/staging)

---

## Steg 4: Init Firebase lokalt i prosjektet

Åpne terminalen i `Share idea/`-mappen:

```bash
firebase login
firebase use --add
# Velg shareidea-dev, gi det aliaset "dev"
firebase use --add
# Velg shareidea-staging, alias "staging"
firebase use --add
# Velg shareidea-prod, alias "prod"
```

Nå kan du bytte mellom prosjekter med `firebase use dev`, `firebase use staging`, etc.

Init de tjenestene du trenger:
```bash
firebase init firestore
firebase init functions
firebase init storage
firebase init emulators
```

Når den spør om å overskrive `firestore.rules`: si **nei**. Vi har allerede skrevet den.

For Functions: velg **JavaScript** (eller TypeScript hvis du foretrekker det), si **ja** til ESLint, si **nei** til å installere dependencies nå.

For Emulators: velg **Authentication, Firestore, Functions, Storage**.

Resultatet skal være en `firebase.json`-fil i prosjektroten som peker til `firebase/firestore.rules`, `firebase/functions/`, etc. Hvis Firebase la filene andre steder, flytt dem så strukturen matcher CLAUDE.md.

---

## Steg 5: Deploy reglene til dev

```bash
firebase use dev
firebase deploy --only firestore:rules
```

Du skal se «✔ Deploy complete!». Hvis du får feilmelding om syntax, fix og prøv igjen.

Verifiser i Console: **Build → Firestore Database → Rules**. Du skal se reglene fra `firestore.rules`-fila vise i editoren. Ikke endre dem her — endre alltid i fila lokalt og deploy på nytt.

---

## Steg 6: Aktiver App Check

App Check verifiserer at forespørsler kommer fra din ekte Android-app, ikke fra en bot eller scraper.

I Console for hvert prosjekt:
1. Gå til **Build → App Check**
2. Klikk **Get started**
3. Du må først registrere Android-appen din under **Project settings → Your apps** hvis den ikke er der
4. For Android-appen: velg **Play Integrity** som provider
5. Følg instruksjonene for å hente SHA-256 fingerprint fra signing-key
6. **Ikke** sett enforcement til «Enforced» ennå — la den stå på «Unenforced» til appen din faktisk sender App Check-tokens. Slå på enforcement *etter* at klienten er testet med tokens.

---

## Steg 7: Sett opp billing alerts (gjør dette FØR du går videre)

Cloud Functions kan generere store regninger hvis noen angriper deg. Hard cap er ikke valgfritt.

1. Gå til `console.cloud.google.com` (Google Cloud Console — separat fra Firebase Console)
2. Velg `shareidea-prod` i prosjekt-velgeren øverst
3. **Billing → Budgets & alerts**
4. Klikk **Create budget**
5. Sett:
   - Beløp: f.eks. 500 kr/måned for dev, 2000 kr/måned for prod
   - Alerts: 50 %, 90 %, 100 % av budsjett
   - Send til e-posten din
6. **Viktig:** dette er bare *varsler*. For hard cap må du sette opp en Cloud Function som kalles av Pub/Sub når budsjettet overskrides og deaktiverer billing. Google har en mal for dette under «Cap (disable) billing to stop usage». Implementer den i prod.

Gjenta budsjett-setup for dev og staging (lavere tak).

---

## Steg 8: Slå på Cloud Logging audit logs

For bevisførsel og incident response trenger du detaljerte logger.

I Cloud Console (`console.cloud.google.com`), for prod-prosjektet:
1. **IAM & Admin → Audit Logs**
2. Slå på **Data Read, Data Write, Admin Read** for:
   - Cloud Firestore API
   - Cloud Functions API
   - Identity Toolkit API (Auth)
3. Sett oppbevaringstid på Cloud Logging til 5 år (under **Logging → Logs Storage**) for prod. Dette koster litt, men er nødvendig for «rimelige tiltak»-bevisførselen.

---

## Steg 9: Test reglene lokalt med Emulator

Før du deployer noe til prod:
```bash
firebase emulators:start
```

Dette starter en lokal Firestore + Auth + Functions på maskinen din. Åpne `http://localhost:4000` for emulator-UI. Du kan opprette test-brukere, prøve å lese/skrive dokumenter, og se om reglene blokkerer som forventet.

Skriv unit tester for reglene i `firebase/test/firestore-rules.test.js` med `@firebase/rules-unit-testing`. Minimum-test: prøv å lese en idé som ikke er din, prøv å sette `isActivePatron: true` på din egen brukerpost — begge skal feile.

---

## Steg 10: Cloud Functions skeleton

Sett opp grunnstrukturen i `firebase/functions/index.js`. Ikke implementer alt ennå, men ha disse stubene klare:

- `onUserCreate` — Auth-trigger som oppretter `users/{uid}`-doc
- `submitIdea` — callable som hasher idé, lagrer i `ideas/`, og skriver til `hashLedger/`
- `getIdeaCatalog` — callable som returnerer sanitert liste til patroner og logger til `accessLogs/`
- `getIdeaDetail` — callable som returnerer full body til verifisert patron og logger
- `stripeWebhook` — HTTPS endpoint med signaturverifisering, oppdaterer subscriptions
- `playBillingWebhook` — samme for Google Play

Alle utgående tjenestekall (Stripe API-kall, e-post) bruker secrets fra Secret Manager:
```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
```

Kontroller også at Functions deployes i samme europeiske område som resten av prosjektet:
- `firebase/functions/index.js` skal ha `setGlobalOptions({ region: 'europe-west1', ... })`
- `firebase.json` skal bruke `runtime: "nodejs20"`
- `firebase/functions/package.json` skal ha `engines.node: "20"`

---

## Steg 11: Når du er klar for prod

Sjekkliste før du peker prod-prosjektet mot ekte brukere:
- App Check satt til «Enforced»
- Billing hard cap aktivert (ikke bare varsel)
- Audit logs på 5 år oppbevaring
- Backup scheduled (gcloud firestore export — sett opp med Cloud Scheduler)
- Personvernerklæring publisert og lenket fra appen
- DPA signert med Google
- Rules unit tests passerer i CI
- Emulator-test av hele kjøpsflyten gjennomført

---

## Hvor du finner ting i Console (juksefil)

| Ting du leter etter | Hvor i Console |
|---|---|
| Se data i Firestore | Build → Firestore Database → Data |
| Endre regler (les, ikke rediger) | Build → Firestore Database → Rules |
| Se Cloud Function-logger | Build → Functions → Logs |
| Se hvem som har logget inn | Build → Authentication → Users |
| Skifte sign-in-providers | Build → Authentication → Sign-in method |
| Slå på App Check | Build → App Check |
| Indekser for queries | Build → Firestore Database → Indexes |
| Storage-buckets | Build → Storage |
| Servicekonti og IAM | Cloud Console (ikke Firebase) → IAM & Admin |
| Billing | Cloud Console → Billing |
| Audit logs detaljert | Cloud Console → Logging → Logs Explorer |
| Secrets | Cloud Console → Security → Secret Manager |

Hovedforvirringen folk har: «Firebase Console» og «Google Cloud Console» er to forskjellige nettsider for samme underliggende prosjekt. Firebase Console er en pen forkledning over en del av Google Cloud. Når du trenger ting som ikke finnes i Firebase Console (IAM, Secret Manager, billing budgets) — gå til Cloud Console.

---

## Hva du IKKE skal røre i Console

- Ikke rediger `firestore.rules` direkte i Console-editoren — endring forsvinner ved neste `firebase deploy`
- Ikke opprett brukere manuelt i Authentication-fanen — bruk app-flyten
- Ikke endre indekser manuelt — definer dem i `firestore.indexes.json` og deploy
- Ikke gi noen IAM-rolle direkte til en e-postadresse uten å dokumentere hvorfor — det er hvordan tilgang lekker over tid
