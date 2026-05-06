# Submission Disclosure Warning
**Status:** Utkast til UX + juridisk gjennomgang.
**Sist oppdatert:** 2026-05-03

Dette er den siste skjermen en innovator ser før de submitter en idé. Formålet er trefoldig: (1) gi reelt informert samtykke, (2) etablere bevis for at innovatoren forsto risikoen, (3) beskytte plattformen mot påstander om villedning eller tap av patentrett.

---

## Designmønster

Modal-dialog som blokkerer submit-knappen. Innovatoren må:
1. Lese gjennom advarselen (scroll-til-bunn for å aktivere checkboxer).
2. Aktivt huke av tre separate checkboxer (ikke én samlet — hver gjelder ett distinkt forhold).
3. Klikke «Jeg forstår — submitt ideen».

Tidsstempel og hash for samtykket lagres i Firestore på `users/{uid}/consents/{consentId}` med versjon av advarselen — slik at plattformen senere kan bevise nøyaktig hvilken tekst innovatoren godtok.

---

## Skjermtekst (norsk versjon)

### Tittel
**Før du deler ideen din — viktig informasjon**

### Brødtekst

Du er i ferd med å sende inn en idé til Share Your Idea!. Vi tar beskyttelsen av ideen din på alvor: Smart Engine genererer et kryptografisk fingeravtrykk og tidsstempel som dokumenterer at *du* hadde ideen først, og kun verifiserte patroner under konfidensialitetsplikt får se den. Likevel finnes det tre ting du må forstå før du submitter.

**1. Ideer er ikke beskyttet av opphavsrett.**
Norsk og internasjonal lov beskytter *uttrykket* — den konkrete teksten du skriver — men ikke selve ideen bak. Hvis noen ser ideen din og bygger noe på den uten å bruke teksten din direkte, er det opphavsrettslig sett tillatt. Beskyttelsen din kommer fra (a) konfidensialitetsavtalen patroner signerer, (b) tidsstemplet bevis fra Smart Engine, og (c) eventuell forretningshemmelighet- eller patentbeskyttelse.

**2. Submission kan påvirke fremtidige patentrettigheter.**
Hvis ideen din potensielt er patenterbar — det vil si en teknisk oppfinnelse med nyhet og oppfinnelseshøyde — bør du vurdere å levere patentsøknad *før* du submitter her. Selv om plattformen er lukket og patroner er underlagt taushetsplikt, kan submission i noen tilfeller komplisere senere patentbehandling. Plattformen tilbyr ikke patentrådgivning og påtar seg intet ansvar for tap av patentmuligheter. Er du i tvil, snakk med en patentrådgiver først.

**3. Du er selv ansvarlig for at ideen er din.**
Ved å submitte bekrefter du at ideen er din egen, at den ikke er stjålet eller kopiert fra andre, og at du har rett til å selge eller lisensiere den. Hvis det viser seg at ideen krenker andres rettigheter, kan du bli personlig ansvarlig — ikke plattformen.

### Checkboxer (alle må aktiveres)

☐ Jeg har lest og forstått at ideen min ikke er beskyttet av opphavsrett alene, men gjennom konfidensialitet, forretningshemmelighet og bevisførsel.

☐ Jeg forstår at submission kan påvirke patentrettigheter, og at jeg selv er ansvarlig for å vurdere patentbeskyttelse før jeg deler ideen her.

☐ Jeg bekrefter at ideen er min egen, at jeg har rett til å selge eller lisensiere den, og at den ikke krenker tredjeparts rettigheter.

### Knapper

[Avbryt — gå tilbake]    [Jeg forstår — submitt ideen]

---

## Tekniske krav til implementasjonen

**Versjonering.** Hver materielle endring i teksten skal ha ny versjons-ID. Lagre versjon sammen med samtykket.

**Ikke pre-haket.** Checkboxene må starte avhuket. Forhåndshakede bokser har lavere bevisverdi i Norge og er forbudt under EU-forbrukerrett.

**Ingen «Jeg leser senere».** Submit-knappen er deaktivert til alle tre checkboxer er aktive.

**Audit-logg.** Lagre i Firestore:
```
users/{uid}/consents/{consentId}
  type: 'submission_disclosure'
  version: 'v1.0'
  acceptedAt: timestamp
  ip: string (anonymisert)
  userAgent: string
  textHash: string  // SHA-256 av eksakt tekst som ble vist
```

**Tilbakekalling.** Tilgjengelig fra brukerprofil, men gjelder kun fremtidige submissions — ikke retroaktivt for allerede submittede ideer.

---

## Juridisk rasjonale (per element)

| Element | Hvorfor det er der |
|---|---|
| Forklaring av opphavsrett-begrensning | Hindrer påstander om villedning. Innovator kan ikke senere si «jeg trodde plattformen ga full beskyttelse». |
| Patent-advarsel | Beskytter plattformen mot erstatningskrav for tap av patentmuligheter — det største juridiske risikoområdet. |
| Egenerklæring om eierskap | Flytter ansvaret til innovator hvis ideen er stjålet, og gir plattformen regress hvis den blir saksøkt av tredjepart. |
| Tre separate checkboxer | Norsk og EU-rett ser strengere på samlede samtykker. Distinkte hak gir sterkere bevis for informert samtykke. |
| Hash av eksakt tekst | Bevismessig: kan i ettertid bevise nøyaktig hva innovatoren samtykket til, selv om teksten senere endres. |

---

## Ting advokaten bør gjennomgå
- Er formuleringen rundt patent presis nok? Bør «kan påvirke» erstattes med konkrete scenarier?
- Skal det være en separat advarsel for forretningshemmeligheter (NDA mellom innovator og egen arbeidsgiver)?
- Bør det være en lenke til en kort forklaringsvideo for å styrke «informert samtykke»-argumentet?
- Hvilken angrefrist gjelder for selve submission — kan innovator trekke ideen før første patron ser den?
