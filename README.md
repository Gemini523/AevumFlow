# Epigenetinių laikrodžių EWAS analizės įrankis

Tai R Shiny pagrindu sukurta interaktyvi web aplikacija, leidžianti analizuoti **EWAS** (epigenome-wide association studies) duomenų sąveiką su **epigenetiniais amžiaus laikrodžiais**. Vartotojai gali pasirinkti laikrodžius, filtruoti bruožus, vykdyti analizę ir vizualizuoti rezultatus keliomis formomis — įskaitant karščio žemėlapius, dendrogramas ir taškų diagramas.

## Turinys
 
- [Pagrindinės funkcijos](#pagrindinės-funkcijos)
- [Reikalavimai](#reikalavimai)
- [Įdiegimas ir paleidimas](#įdiegimas-ir-paleidimas)
- [Duomenų struktūra](#duomenų-struktūra)
- [Laikrodžiai](#laikrodžiai)

## Pagrindinės funkcijos
 
- **EWAS analizė:** skaičiuoja epigenetinių laikrodžių CpG persidengimą su EWAS rezultatais ir įvertina amžiaus poslinkį (score) kiekvienam bruožui;
- **Jaccard indeksas:** vizualizuoja EWAS studijų ir laikrodžių CpG rinkinių persidengimą burbulinėje diagramoje;
- **Šilumos žemėlapiai:** rodo amžiaus poslinkius pagal bruožą ir laikrodį — globaliai arba pagal kategorijas (senėjimas, svoris, širdies ligos ir kt.);
- **Dendrogramos:** klasterizuoja laikrodžius ir EWAS studijas pagal Pearson koreliaciją;
- **Grupuota taškų diagrama:** vizualizuoja kiekvieno bruožo amžiaus poslinkį pagal pasirinktus laikrodžius, sugrupuotą pagal EWAS kategorijas;
- **Pasirinktiniai duomenys:** leidžia įkelti savo EWAS duomenis (CSV/XLSX) ir savus laikrodžius su CpG koeficientais;
- **Atsisiuntimai:** rezultatus galima atsisiųsti CSV formatu, o visas vizualizacijas — PDF formatu.

## Reikalavimai
 
- **R 4.x+**
- **R paketai** (įdiegiami per `install.packages()`):
  - `shiny`
  - `DT`
  - `pheatmap`
  - `openxlsx`
  - `ape`

## Įdiegimas ir paleidimas
 
### 1. Klonuoti arba atsisiųsti projektą
 
```bash
git clone https://github.com/Gemini523/AevumFlow.git
cd AevumFlow
```
### 2. Įdiegti priklausomybes
 
R konsolėje:
 
```r
install.packages(c("shiny", "DT", "pheatmap", "openxlsx", "ape"))
```
### 3. Paruošti duomenis
 
Projekto struktūra turi atitikti šį išdėstymą:
 
```
projektas/
├── app/
│   ├── server.R
│   ├── ui.R
│   └── calculations.R
├── data/
│   ├── ewas_atlas.rds
│   ├── ewas_catalog.rds
│   ├── ewas_custom.rds
│   ├── ewas_all.rds
│   ├── ewas_atlas_full.rds
│   ├── ewas_catalog_full.rds
│   ├── ewas_custom_full.rds
│   ├── ewas_all_full.rds
│   └── jaccard_whitelist.rds
└── input/
    ├── horvath.rds
    ├── hannum.rds
    └── ... (kiti laikrodžiai)
```

### 4. Paleisti aplikaciją
 
```bash
Rscript R/server.R
# naršyklėje atverkite: http://127.0.0.1:XXXX/
```

## Duomenų struktūra
 
### EWAS duomenys
 
EWAS failai (CSV arba XLSX) turi turėti šiuos stulpelius:
 
| Stulpelis     | Aprašymas                        |
|---------------|----------------------------------|
| `cpg`         | CpG identifikatorius (pvz., cg00001234) |
| `trait`       | EWAS bruožas (pvz., „smoking")   |
| `pmid`        | PubMed ID                        |
| `beta`        | Regresijos koeficientas          |
| `sample_size` | Imties dydis                     |
 
### Pasirinktiniai laikrodžiai
 
Laikrodžio failas (CSV arba XLSX) turi turėti šiuos stulpelius:
 
| Stulpelis | Aprašymas                     |
|-----------|-------------------------------|
| `cpg`     | CpG identifikatorius          |
| `coef`    | Laikrodžio koeficientas       |
 
## Laikrodžiai
 
Aplikacija turi įdiegtus šiuos laikrodžius:
 
**Standartiniai:**
AdaptAge, CauseAge, DamAge, Hannum, Horvath, Intrinclock, ICage, PhenoAge, RetroElementV1, RetroElementV2, Skinandblood, EpiToc, EpiToc2, MiAge
 
**PC variantai (principal component):**
PCDnamTL, PCGrimAge, PCHannum, PCHorvath, PCPhenoage, PCskinAndBlood
 
Papildomus laikrodžius galima įkelti tiesiogiai per aplikacijos sąsają.
