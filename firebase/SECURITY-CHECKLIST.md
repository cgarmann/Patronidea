# Firebase Security & Compliance Checklist
**Status:** Sjekkliste før lansering — ingenting i denne mappen er implementert ennå.
**Sist oppdatert:** 2026-05-03

Denne listen knytter teknisk Firebase-konfigurasjon til de juridiske forpliktelsene i ToS. Hvert punkt er enten en *blocker* (må være på plass før noen bruker ser plattformen) eller en *härdering* (må være på plass før første reell idé submittes).

---

## TIER 1 — Blockers (uten disse er plattformen åpen)

### 1.1 Firestore Security Rules
**Status:** Ikke skrevet. Standard Firebase-prosjekter åpner alt med `allow read, write: if true;` i 30 dager.

Krav:
- `users/{uid}`: lesbart kun av eier og admin. Skrivbart kun av eier (men ikke `role`-feltet — det settes av Cloud Function).
- `ideas/{ideaId}` — fullt body: lesbart av innovator (eier) og av patron *kun hvis* patron har aktiv subscription OG har akseptert NDA-versjonen som er gjeldende. Aldri returnert i kataloglister.
- `ideas/{ideaId}` — teaser-felt: lesbart av enhver autentisert patron med aktiv subscription.
- `ideas/{ideaId}` — `innovatorId`: aldri lesbart for patron før pitch er akseptert.
- `pitches/{pitchId}`: lesbart kun av involvert innovator og patron.
- `subscriptions/{uid}`: lesbart av eier; kun skrivbart av Cloud Function (Stripe/Play webhooks).
- `consents/{consentId}`: append-only — eksisterende dokumenter kan ikke endres eller slettes (bevisførsel).

Test reglene med Firebase Emulator Suite før deploy. Skriv minst 30 unit-tester som dekker både happy path og forsøk på misbruk.

### 1.2 Cloud Functions må gjøre den faktiske kontrollen
**Status:** Functions-mappen finnes ikke.

Følgende må *aldri* skje på klienten:
- Generering av `hash`-feltet på en idé (klient kan lyve om hashen).
- `uniquenessScore`-beregning.
- Endring av `role`, `isActivePatron`, eller `subscriptionExpiry`.
- Validering av at pris-overføring faktisk skjedde før `status: 'sold'`.
- Markering av pitch som `accepted`.

Alle disse må være Callable Functions eller Firestore-triggere som verifiserer auth-context og applikerer business rules.

### 1.3 App Check
Aktivér App Check med Play Integrity (Android) før noen Cloud Function eller Firestore-regel kan kalles. Uten dette kan en angriper kalle Firestore-API-et direkte med stjålne tokens fra en frakoblet klient. Dette er det eneste som hindrer noen i å skrive et script som scraper hele idébasen hvis de først får tak i en gyldig auth-token.

### 1.4 Server-side payment verification
Stripe webhooks og Google Play Developer API-kall må gå via Cloud Function med signaturverifisering. Klienten kan ikke under noen omstendighet sette `isActivePatron: true` selv. Stripe-signing-secret må ligge i Secret Manager, ikke i kode.

---

## TIER 2 — Konfidensialitet (juridisk «rimelige tiltak»)

Forretningshemmelighetsloven krever «rimelige tiltak» for at en idé skal være beskyttet. Hvert punkt nedenfor er et slikt tiltak — uten dem kollapser hele den juridiske modellen vi skisserte.

### 2.1 Tilgangslogg (audit log)
Cloud Function-trigger på enhver lesing av full idé-body. Skriv til separat samling `accessLogs/{logId}`:
```
{
  ideaId, patronId, accessedAt, ipHash, userAgentHash, accessType
}
```
Denne samlingen er append-only, ingen sletting tillatt selv av admin uten manuell prosess. Beholdes i minimum 5 år for bevisførsel.

### 2.2 Ingen ide-body i kataloglister
`getIdeas()`-spørringer som lister flere ideer skal aldri returnere `body`-feltet — kun `title`, `category`, `price`, `uniquenessScore`, `createdAt`. Body hentes med separat dokumentlesing per idé, og hver slik lesing logges (2.1).

### 2.3 Innovator-anonymitet
`innovatorId` filtreres ut av alle patron-rettede queries via Cloud Function. Patron skal ikke kunne korrelere ideer på tvers av samme innovator.

### 2.4 Storage-regler (hvis innovatører laster opp vedlegg)
Samme paywall som Firestore-regler. Signed URLs med kort TTL (15 min). Aldri public read.

### 2.5 Watermarking av innholdsvisning (vurder)
For ideer over en viss verdi: server-rendret bilde med usynlig watermark som inkluderer patronId + tidsstempel. Hvis idé-body lekker, kan kilden identifiseres. Krever bildegenerering på server.

### 2.6 Forbud mot eksport
Klienten skal ikke ha innebygget «kopier til utklipp», «del»-knapp eller «last ned» på idé-body. Skjermbilder kan ikke hindres teknisk på Android, men UI-friksjon mot åpenbar eksfiltrering er en del av «rimelige tiltak»-bevisførselen.

---

## TIER 3 — Bevisførsel og integritet

### 3.1 Idé-hash er immutable og signert
Når idé submittes: Cloud Function beregner SHA-256 av normalisert tekst, lagrer i `hash`-feltet, og publiserer en kopi til en append-only `hashLedger`-samling med tidsstempel og innovatorId. Selv hvis hovedposten endres, finnes en uforanderlig referanse.

### 3.2 Samtykkeposter
Disclosure-advarselen (jf. `legal/submission-disclosure-warning.md`) lagres med:
- versjon av advarselen
- SHA-256 av eksakt vist tekst
- tidsstempel
- ip-hash + ua-hash

Dette er bevisførsel for at innovator var informert. Like viktig som selve advarselen.

### 3.3 Pitch-aksept-signatur
Når innovator aksepterer en pitch, signeres aksepten med tidsstempel og bevares uforanderlig. Kontaktinformasjon avsløres først *etter* at signaturen er lagret.

### 3.4 Tidsynkronisering
Bruk Firestore server timestamp (`FieldValue.serverTimestamp()`), aldri klient-tid. Klient-tidsstempler er trivielle å forfalske og verdiløse i bevisførsel.

---

## TIER 4 — GDPR og personvern

### 4.1 Region
Sett Firestore og Functions til `europe-west1` (Belgia) eller `europe-north1` (Finland). Default er `us-central` — det betyr data lagres i USA og krever Standard Contractual Clauses + transfer impact assessment. Mye enklere å holde alt i EØS.

### 4.2 Data Processing Addendum
Signer Google Cloud DPA. Dokumenter Google som databehandler i personvernerklæringen. List opp sub-prosessorer (Stripe, Google Play, Firebase Auth-providere).

### 4.3 GDPR artikkel 15 (innsyn) og 20 (portabilitet)
Cloud Function `exportUserData` som returnerer alle dokumenter knyttet til en bruker som JSON. Må kjøres innen 30 dager etter forespørsel.

### 4.4 GDPR artikkel 17 (sletting)
Cloud Function `deleteUserData` som anonymiserer brukerens poster. *Unntak* dokumentert i ToS:
- Hash-records beholdes for bevisførsel (legitim interesse).
- Solgte ideer forblir hos kjøper (avtaleoppfyllelse).
- Tilgangslogger beholdes 5 år (rettslige krav).

### 4.5 PII-inventar
Lag en oversikt over hvert Firestore-felt: er det PII? hvilket behandlingsgrunnlag? hvor lenge oppbevares det? Krav under GDPR artikkel 30 (behandlingsprotokoll).

### 4.6 Cookie- og analytics-samtykke
Hvis Firebase Analytics aktiveres: separat samtykke kreves i Norge/EU. Default skal være *av* — ikke *på*.

---

## TIER 5 — Authentication

### 5.1 E-postverifisering påkrevd før submission
Innovator kan ikke submitte ideer før e-post er verifisert. Patron kan ikke betale før e-post er verifisert. Reduserer fake-konto-spam dramatisk.

### 5.2 Passordkrav
Minimum 12 tegn, sjekk mot HaveIBeenPwned-API før godkjenning (Firebase støtter dette via Identity Platform).

### 5.3 MFA tilbys
Frivillig SMS- eller TOTP-MFA. Anbefal for konti med historikk på over X kr i transaksjoner.

### 5.4 Google Sign-In med minimale scopes
Kun `email` og `profile`. Aldri `openid drive` eller andre brede scopes. Innovatører kan misforstå og tro at plattformen får tilgang til Drive-data.

### 5.5 Token-utløp
Firebase Auth idTokens utløper etter 1 time som standard — bra. Refresh-tokens revokeres ved passordendring.

---

## TIER 6 — Misbrukshåndtering

### 6.1 Rate limiting
Cloud Functions med Cloud Armor eller in-function rate limiting:
- Submission: maks 5 ideer per innovator per døgn (juster basert på brukermønster).
- Idé-lesing: maks 200 fulle ide-body-lesinger per patron per døgn.
- Pitch-opprettelse: maks 20 per patron per døgn.

### 6.2 Anomalideteksjon
Cloud Function som kjører nattlig og flagger:
- Brukere med uvanlig høyt tilgangsmønster.
- Ideer med uvanlig høy uniqueness-score-clustering (mulig manipulering).
- Geografiske avvik (samme konto fra mange land samme uke).

### 6.3 Billing alerts
Sett opp budsjettvarsler i Google Cloud Console. Et angrep mot Cloud Functions kan generere fem-sifrede regninger på timer. Hard cap, ikke bare varsel.

### 6.4 reCAPTCHA Enterprise på registrering og innlogging
Reduserer bot-registreringer. Inkludert i App Check-flyten.

---

## TIER 7 — Operasjonelt

### 7.1 Tre Firebase-prosjekter
`shareidea-dev`, `shareidea-staging`, `shareidea-prod`. Aldri test mot prod. Aldri ekte data i dev. Separate Stripe-konti per miljø.

### 7.2 Backups
Scheduled Firestore export til Cloud Storage daglig. Lagres i separat region. Test restore-prosedyren minst kvartalsvis — en backup som ikke er testet er ikke en backup.

### 7.3 Secrets Manager
Stripe secret key, Google Play service account key, eventuelle API-nøkler — alle i Secret Manager, refereres fra Cloud Functions med IAM-binding. Aldri i `functions/.env` som committes.

### 7.4 IAM least privilege
Hver Cloud Function får egen service account med kun de IAM-rollene den trenger. Ikke standard Compute Engine default-account, som har Editor-rolle på hele prosjektet.

### 7.5 Deploy via CI
Firestore-regler og Functions deployes kun via GitHub Actions med code review-krav. Aldri `firebase deploy` direkte fra utviklerlaptop til prod.

### 7.6 Monitoring
Cloud Logging-alerts på: failed auth-attempts >100/min, function error rate >5 %, latency p99 >2s, regelbrudd-forsøk.

---

## TIER 8 — Compliance-formaliteter

### 8.1 Personvernerklæring publisert og lenket fra appen
Synlig før registrering. Nevner alle behandlinger i TIER 4.

### 8.2 Sub-prosessor-liste
Google Cloud, Stripe, Google Play, eventuelle e-post-leverandører (SendGrid?) — alle listet.

### 8.3 Standard Contractual Clauses
Hvis noen sub-prosessor opererer utenfor EØS: SCC + transfer impact assessment.

### 8.4 Brudd-varsling-rutine
Skriftlig prosedyre for varsling til Datatilsynet innen 72 timer ved personvernbrudd. Test med en table-top-øvelse.

### 8.5 DPIA (Data Protection Impact Assessment)
Plattformen behandler kommersielt sensitive data og involverer profilering — DPIA er trolig påkrevd. Mal finnes hos Datatilsynet.

---

## Anbefalt rekkefølge

1. Sett opp tre Firebase-prosjekter i europe-west1 (TIER 7.1, 4.1).
2. Skriv `firestore.rules` med Emulator-tester (TIER 1.1).
3. Skriv minimum Cloud Functions: hash-generering, Smart Engine, betalings-webhooks (TIER 1.2, 1.4, 3.1).
4. Aktiver App Check (TIER 1.3).
5. Aktiver e-postverifisering (TIER 5.1).
6. Bygg audit-logging (TIER 2.1).
7. Bygg samtykke-lagring (TIER 3.2).
8. Sett opp billing alerts og rate limiting (TIER 6.1, 6.3).
9. Skriv personvernerklæring og publiser (TIER 8.1).
10. Backups + secrets management (TIER 7.2, 7.3).

Punkt 1–4 er minimum før alfa-test med interne brukere. Punkt 1–7 er minimum før noen ekstern bruker rører plattformen. Alt under TIER 8 må være ferdig før første ekte idé submittes.
