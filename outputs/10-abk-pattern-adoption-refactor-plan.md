# AI Booster Kit — Pattern Adoption refactor plan

## Problem Statement

Az AI Booster Kit jelenleg képes formációkat leírni és ajánlani, de nincs egységes, gépileg validálható szerződése arra, hogyan válik egy külső frameworkben megfigyelt működési minta saját ABK-komponenssé. Az upstream repositoryk tesztje, dokumentációja vagy népszerűsége nem bizonyítja, hogy egy hook, skill, script, role, workflow vagy context template Codexben, az ABK saját authority- és autonómiamodelljében is értéket ad.

A hiányzó határ miatt összecsúszhat a forráskutatás, az upstream reprodukció, az ABK-natív prototípus, az empirikus kiválasztás és a production adoptálás. Különösen veszélyes lenne egy upstream runtime-ot providerként bekötni, vagy upstream teszteredmény alapján `CHOSEN` állapotot adni egy még ki sem próbált ABK-komponensnek.

## Solution

Bevezetünk egy szigorú, extension nélküli Capability Component / Pattern Adoption szerződést. A szerződés az AI Booster Kit saját nevezéktanát használja, és atomikus komponensként kezeli a hookot, skillt, scriptet, role-t, workflow-t, eventet és context template-et.

Minden adoptálási jelölt három összehasonlítási ágon, ugyanazon lokális Codex-tesztkorpuszon halad át:

1. jelenlegi ABK-komponens vagy manuális baseline;
2. az upstream mechanika izolált reprodukciója;
3. saját ABK-natív prototípus.

A fix tesztmátrix hat közös és négy komponensspecifikus esetből áll. Modellfüggő futásokat háromszor ismétlünk. Az upstream megoldás nem kerül az AI Booster Kitbe, és nem marad runtime dependency. A `CHOSEN` csak empirikus kiválasztást jelent; a tényleges `ADOPTED` állapot külön jóváhagyást igényel.

## Commits

Az alábbiak jövőbeli, apró és önállóan ellenőrizhető implementációs szeletek. Ez a mérföldkő nem hajtja végre és nem commitolja őket.

1. **Rögzítsd a Pattern Adoption lifecycle-t.** Vezesd be a kutatás, reprodukció, prototípus, összehasonlítás, kiválasztás és adoptálás egymást kizáró állapotait. A meglévő működés maradjon változatlan.
2. **Add hozzá az atomikus komponens taxonómiáját.** Deklaráld a támogatott komponensfajtákat és tiltsd az ismeretlen vagy framework-névtérrel ellátott típusokat.
3. **Add hozzá az autonómia- és mellékhatás-profilt.** Minden komponens explicit módon jelezze az authority-szintet, checkpointot, auditot, stopot és recovery-t.
4. **Vezesd be a provenance- és permission-állapotot.** Ez auditadat legyen, ne empirikus minőségi pontszám vagy automatikus kutatási tiltás.
5. **Készíts szigorú manifest-validátort.** Ismeretlen kulcs, hiányzó mező, tiltott extension vagy érvénytelen állapot fail-closed hibát adjon.
6. **Rögzítsd a benchmark-esetek szerződését.** Különítsd el a hat közös és négy specifikus esetet; minden eset tartalmazzon inputot, elvárt viselkedést, evidence-követelményt és stopfeltételt.
7. **Készíts manuális/ABK baseline run recordot.** A baseline eredménye ugyanazt a result-sémát használja, mint a másik két ág.
8. **Készíts upstream reproduction run recordot.** Csak izolált Codex-futtatás eredménye kerülhet bele; külső szolgáltatást vagy más hostot igénylő mechanika `REJECTED`.
9. **Készíts ABK-prototípus run recordot.** A prototípus ne importáljon upstream runtime-ot, és csak saját ABK-nevezéktant használjon.
10. **Add hozzá az ismételt futások aggregációját.** Modellfüggő eseteknél három futás mediánja adja az esetpontot; a szórás és minden nyers eredmény megmarad.
11. **Add hozzá a tíz értékelési dimenziót és súlyokat.** A feladatsiker, helyesség/evidence, ismételhetőség, megfigyelhetőség és stop/recovery legyen kritikus.
12. **Vezesd be a státuszdöntést.** Kritikus dimenzió legfeljebb 4 esetén `REJECTED`; 8 alatti átlag `CANDIDATE`; legalább 8-as átlag `CHOSEN`.
13. **Tedd külön műveletté az adoptálást.** `CHOSEN` rekordból csak explicit emberi jóváhagyás hozhasson létre `ADOPTED` komponenst.
14. **Adj pozitív contract fixture-t.** Egy lokális, advisory jellegű context-template komponens teljes manifestje és scorecardja menjen át minden validáción.
15. **Adj negatív contract fixture-öket.** Ismeretlen kulcs, framework extension, nem deklarált mellékhatás, hiányos benchmark, hibás score és jogosulatlan `ADOPTED` állapot bukjon el.
16. **Kösd be a read-only quality gate-et.** A schema-, fixture-, benchmark-completeness- és score-validáció ne módosítsa a vizsgált forrást vagy a bizonyítékot.
17. **Pilotolj egyetlen atomikus mintát.** Először egy alacsony mellékhatású context-template vagy advisory skill fusson végig a teljes háromágú mátrixon.
18. **Függetlenül review-zd a pilotot.** A reviewer ne lássa az ág identitását, ahol az anonimizálás lehetséges; a végső státuszt a gépi eredmény és az emberi döntés együtt zárja le.
19. **Csak sikeres pilot után bővíts új komponensfajtára.** Következőként hook vagy script vizsgálható; külső írásra képes komponens külön authority- és recovery-review-t igényel.
20. **Dokumentáld a production adoptálási határt.** A pilot és a `CHOSEN` állapot nem módosíthat automatikusan aktív ABK-formációt, skillt, hookot vagy projektkonfigurációt.

## Decision Document

- A külső framework kutatási mintaforrás, nem provider, plugin vagy runtime dependency.
- Az adoptálás atomikus komponensenként történik.
- A canonical fogalmak az AI Booster Kit saját nevezéktanába kerülnek; framework-specifikus extension blokk nincs.
- A közös empirikus host a Codex, lokális és izolált végrehajtással.
- A három összehasonlítási ág külön pontszámot és evidence-et kap.
- Egy nem reprodukálható mechanika automatikusan `REJECTED`.
- Több eltérő használati profilú komponens is lehet `CHOSEN` ugyanarra a tág képességre.
- A licenc nem minőségi pontszám; a provenance és permission állapot ettől még megmarad.
- A tényleges platformbeépítés külön emberi jóváhagyás.

## Testing Decisions

Jó teszt külső viselkedést, eredményt, evidence-et, hibát, stopot és recovery-t vizsgál; nem statikus promptszöveget vagy belső implementációs részletet pontoz.

Minden adoptálási jelölt tíz esetet kap: három normál, két boundary, két hibás/hiányos input, egy stop, egy recovery/rollback és egy kompozíciós/handoff eset. A közös és specifikus esetek aránya 6:4. Modellfüggő eredmény háromszor fut. A nyers eredmény, medián, szórás, dimenziópont és súlyozott átlag megmarad.

Az automatikus assertions mellett két független reviewer ugyanazt a rögzített rubricot használja. A reviewer elé kerülő output anonimizált, amikor ez nem szünteti meg a vizsgált viselkedés lényegét. A végső adoptálás emberi döntés.

## Out of Scope

- Upstream framework telepítése vagy bekötése az AI Booster Kitbe.
- Upstream runtime, command namespace vagy persona megőrzése.
- Production ABK-komponens implementálása ebben a nulladik mérföldkőben.
- Külső szolgáltatás, credential, fizetős API vagy más host használata.
- Automatikus `CHOSEN → ADOPTED` átmenet.
- Commit, push, pull request vagy GitHub issue létrehozása külön engedély nélkül.

## Further Notes

A terv szándékosan a contracttal, evidence-modellel és negatív utakkal kezd. Az első production-közeli pilot csak akkor indulhat, amikor a validátor és a teljes összehasonlító record már fail-closed módon működik.
