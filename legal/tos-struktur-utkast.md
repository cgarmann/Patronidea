# ToS-struktur for Share Your Idea!
**Status:** Utkast til advokatgjennomgang — ikke rettslig bindende.
**Sist oppdatert:** 2026-05-03

Dette dokumentet skisserer hvilke klausuler som må være med i vilkårene, hvorfor de er der, og hvilke fallgruver advokaten må passe på. Selve juridiske teksten må skrives av advokat med IP- og plattformkompetanse.

---

## DEL A — Innovator-vilkår

### A1. Parter og definisjoner
Definer: «Plattformen», «Innovator», «Patron», «Idé», «Submission», «Smart Engine», «Hash», «Pitch», «Salg», «Forretningshemmelighet».

### A2. Plattformens rolle
Slå klart fast at plattformen er en *formidler* — ikke kjøper eller selger av ideer. Dette begrenser plattformens ansvar og avklarer skattemessig posisjon.

### A3. Innovatorens garantier ved submission
Innovatoren bekrefter at: (a) ideen er deres egen, (b) de har rett til å lisensiere/selge den, (c) ideen ikke krenker tredjeparts rettigheter, (d) ideen ikke er offentliggjort tidligere på en måte som ødelegger konfidensialiteten. Brudd gir plattformen rett til umiddelbar fjerning og erstatningskrav.

### A4. Rettigheter — hva innovator beholder vs. gir bort
**Kritisk klausul.** Innovator beholder full eiendomsrett til ideen frem til salg. Plattformen får kun en begrenset, ikke-eksklusiv lisens til å: lagre, hashe, vise teaser/full idé til verifiserte patroner, og fasilitere transaksjoner. Ved salg overføres avtalt rettighet til patron — definer eksakt hva som overføres (full eiendomsrett? eksklusiv lisens? geografisk begrensning?).

### A5. Patent-advarsel og egenerklæring
**Kritisk klausul.** Innovator erklærer å ha forstått at submission *kan påvirke* fremtidige patentrettigheter, og at de selv er ansvarlige for å sikre patent før submission hvis aktuelt. Plattformen påtar seg intet ansvar for tap av patentmuligheter. Henvis til separat disclosure-warning som innovator må klikke aktivt.

### A6. Konfidensialitet og forretningshemmelighet
Slå fast at: (a) plattformen behandler submissions som forretningshemmeligheter etter forretningshemmelighetsloven, (b) tilgang er begrenset til betalende patroner under NDA, (c) plattformen iverksetter «rimelige tiltak» (kryptering, tilgangslogg, paywall) for å bevare konfidensialiteten. Dette er forutsetningen for at ideen i det hele tatt kan kvalifisere som beskyttet forretningshemmelighet.

### A7. Pris, betaling og utbetaling
Definer: minimumspriser, plattformens kommisjon (foreslått: 15–25 %), utbetalingsfrekvens, valuta, MVA-håndtering. Klargjør at innovatoren er ansvarlig for egen skatterapportering.

### A8. Konflikt og misbruk fra patron
Beskriv prosessen når innovator mistenker patron-misbruk: bevisinnsamling via Smart Engine-hash, plattformens varslingsplikt, plattformens rett (men ikke plikt) til å forfølge på innovatorens vegne, og innovatorens egen rett til selvstendig rettslig forfølgelse.

### A9. Plattformens ansvarsbegrensning
Standard ansvarsbegrensning: plattformen garanterer ikke salg, garanterer ikke at andre patroner ikke vil misbruke, og maksimal erstatning begrenset til X (typisk 12 måneders subscription-omsetning eller fast tak).

### A10. Innholdsmoderering og fjerning
Plattformens rett til å fjerne ideer som: (a) bryter loven, (b) er duplikater (>85 % similarity-score), (c) bryter ToS, (d) etter pålegg fra myndigheter. Klagemulighet for innovator.

### A11. Oppsigelse og dataportabilitet
Innovator kan slette konto når som helst. Submitterte ideer som er solgt forblir hos kjøper. Aktive ideer fjernes fra vault. Hash-records beholdes for bevisformål i X år.

### A12. Personvern (GDPR)
Henvis til separat personvernerklæring. Behandlingsgrunnlag: avtale (artikkel 6.1.b) for kontoadministrasjon, samtykke for markedsføring.

### A13. Lovvalg og verneting
Norsk rett. Oslo tingrett som avtalt verneting. Vurder voldgift (NOA) for høyverditvister.

---

## DEL B — Patron-vilkår

### B1. Parter og definisjoner
Som A1, men fra patronens perspektiv.

### B2. Subscription og tilgang
Definer subscription-tiers, fornyelsesvilkår, prisendringer, og hva subscription gir tilgang til (browsing) vs. hva som krever separat kjøp (full idétilgang, pitch).

### B3. Konfidensialitet — NDA-klausul
**Kritisk klausul.** Dette er det juridiske hjertet. Patron erkjenner og samtykker i at: (a) alle ideer på plattformen er forretningshemmeligheter, (b) tilgang er gitt under streng konfidensialitetsplikt, (c) konfidensialiteten gjelder også etter avsluttet subscription, (d) plikten gjelder også overfor egne ansatte, rådgivere og partnere som må bindes av tilsvarende NDA.

### B4. Bruksrestriksjoner
**Kritisk klausul.** Patron forplikter seg til å ikke: (a) bruke en idé kommersielt uten kjøp, (b) dele eller videreformidle innhold til tredjepart, (c) reverse-engineere teasere eller forsøke å rekonstruere fulltekst fra delvis informasjon, (d) omgå plattformen for å kontakte innovator direkte (anti-circumvention), (e) systematisk høste innhold (scraping). Eksplisitt forbud mot bruk av AI-trening på innholdet.

### B5. Erkjennelse av idéverdien
Patron erkjenner at ideene har reell kommersiell verdi *fordi* de er hemmelige, og at brudd på konfidensialitet medfører reell skade. Dette styrker bevisførselen ved tvist — det er vanskeligere for en patron å hevde «ideen var verdiløs» når de selv har signert at den hadde verdi.

### B6. Pitch-flowet og kontaktinformasjon
Beskriv pitch-prosessen: anonymitet før aksept, kontaktinformasjon avsløres kun ved aksept, og forbud mot å bruke kontaktinformasjonen utenfor det aksepterte pitch-formålet.

### B7. Kjøp og rettighetsoverføring
Hva kjøper patronen egentlig? Definer eksakt: full eiendomsrett til ideen, ikke-eksklusiv kommersiell lisens, eller begrenset rett. Foreslås: full eiendomsrett ved standard kjøp, slik at patronen får ren tittel.

### B8. Sanksjoner ved brudd
Liquidated damages-klausul (avtalt erstatning) for klare brudd — for eksempel X kr per delt idé, eller Y ganger ideprisen. Plattformen forbeholder seg rett til umiddelbar suspensjon, livstidsutestengelse, og søksmål.

### B9. Forbrukerrettigheter
For patroner som er forbrukere: angrerett på digitale ytelser. Vurder å la patron eksplisitt frafalle angrerett ved kjøp av enkeltidéer (lovlig hvis korrekt utformet etter angrerettloven § 22 bokstav n).

### B10. Betaling og refusjon
Stripe/Google Play-håndtering. Refusjonspolicy: ingen refusjon etter at full idé er vist (siden ytelsen er fullført). Refusjon ved teknisk feil eller verifisert duplikat.

### B11. Subscription-oppsigelse
Standard: oppsigelse gjelder ut betalt periode. Konfidensialitetspliktene i B3–B5 overlever oppsigelse.

### B12. Personvern (GDPR)
Som A12.

### B13. Lovvalg og verneting
Som A13. Merk: forbruker-patroner i andre EU-land kan ha ufravikelig rett til hjemstedets verneting — advokat må vurdere.

---

## DEL C — Tverrgående punkter advokaten må vurdere

### C1. Patent-fellen
Hovedrisiko: at submission tolkes som offentliggjøring og dermed ødelegger nyhetskravet i patentretten. Tiltak: (a) eksplisitt NDA-mekanikk, (b) lukket plattform med tilgangskontroll, (c) advarsel til innovator. Få advokat til å bekrefte at konstruksjonen holder under EPC artikkel 54.

### C2. Forretningshemmelighetsloven § 3
Sjekk at «rimelige tiltak»-kravet er oppfylt: kryptering, logging, tilgangsbegrensning, NDA, audit-rutiner.

### C3. Anti-omgåelse og bevisførsel
Vurder: krav om at patron varsler ved enhver kommersiell bruk av en kjøpt idé i X måneder etter kjøp. Skaper bevisspor.

### C4. Internasjonal håndhevelse
Hvis patroner kan være globale: hvordan håndheves brudd i USA, India, etc.? Vurder geografisk begrensning ved oppstart (kun Norge/EØS) for å redusere kompleksitet.

### C5. Plattform-status under DSA
Hvis EU-brukere: avklar om plattformen er «online platform» under DSA og hvilke plikter som følger (varslingsmekanisme, åpenhetsrapport, etc.).

### C6. MVA-struktur
Innovator → Plattform → Patron involverer tre potensielle MVA-transaksjoner. Trolig: plattformens kommisjon er MVA-pliktig tjeneste; selve idésalget kan være MVA-pliktig digital tjeneste avhengig av leveringssted.

### C7. AI-trening
Eksplisitt forbud mot at innhold brukes til trening av AI-modeller — både for patron og for plattformen selv. Stadig viktigere klausul.

---

## Anbefalt neste skritt
1. Finn IP-/plattformadvokat (Schjødt, Wiersholm, BAHR, Kluge har relevant kompetanse).
2. Be om fastpris for: (a) ToS innovator, (b) ToS patron, (c) personvernerklæring, (d) NDA-klikkmekanikk, (e) disclosure-warning.
3. Estimat: 30–80 000 kr for en grundig pakke.
4. Test ToS-en mot tre konkrete scenarioer før lansering: patron stjeler idé, innovator submitter andres idé, patron deler idé internt med 50 ansatte.
