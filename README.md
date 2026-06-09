# A Comparative New-User Cohort Study in the OMOP Common Data Model

**Risk of gastrointestinal bleeding in new users of selective vs. non-selective NSAIDs — a propensity-score-adjusted observational study on OMOP-CDM data.**

[![Data model](https://img.shields.io/badge/data%20model-OMOP%20CDM%20v5.3-2b6cb0)](https://ohdsi.github.io/CommonDataModel/)
[![Language](https://img.shields.io/badge/language-R-1f6feb)](https://www.r-project.org/)
[![Framework](https://img.shields.io/badge/framework-OHDSI-3d6b4a)](https://ohdsi.org/)
[![Status](https://img.shields.io/badge/status-reproducible-b5471f)]()

---

## Overview

This repository implements an end-to-end **real-world evidence (RWE)** study on observational
healthcare data standardised to the **OMOP Common Data Model (CDM)**. It follows the OHDSI
analytical framework and demonstrates the full scientific workflow expected of an RWE study lead:
study design, cohort definition against standardised clinical vocabularies, propensity-score
adjustment for confounding, comparative effect estimation, and pre-specified sensitivity analyses.

The analysis runs out-of-the-box on **[Eunomia](https://github.com/OHDSI/Eunomia)**, the OHDSI
public teaching dataset (synthetic patient records derived from Synthea, plus the CMS Synthetic
Public Use Files), so the entire study is fully reproducible with no data-access barrier and no
database server — Eunomia runs in-process in R.

> **Research question.** Among adult patients initiating NSAID therapy, is the use of a
> *selective COX-2 inhibitor* (celecoxib) associated with a different rate of *gastrointestinal
> haemorrhage* compared with *non-selective NSAIDs*, after adjustment for measured confounding?

This question is the canonical OHDSI comparative-cohort example; it is used here because it
exercises every component of a regulatory-grade RWE study while remaining fully reproducible on
open data.

---

## Why this study is structured the way it is

The design is a **new-user (incident-user) active-comparator cohort study**, the workhorse design
of pharmacoepidemiology, chosen to mitigate prevalent-user and confounding-by-indication biases.
Causal contrasts are estimated under a clearly stated **estimand** and **target-trial-emulation**
framing (see [`doc/study-protocol.md`](doc/study-protocol.md)). Confounding is addressed through a
**large-scale propensity-score** model with both matching and stratification variants, and
robustness is assessed through pre-specified **sensitivity** and **negative-control** analyses.

The full scientific rationale, PICOT specification, estimand, and analysis plan are documented
**before** any results are produced, mirroring how RWE studies are conducted for regulatory and
publication purposes:

| Document | Purpose |
|---|---|
| [`doc/study-protocol.md`](doc/study-protocol.md) | Full study protocol — objectives, design, target-trial emulation, populations, estimand |
| [`doc/statistical-analysis-plan.md`](doc/statistical-analysis-plan.md) | Pre-specified SAP — estimators, PS model, sensitivity & negative-control strategy, diagnostics |

---

## Repository structure

```
omop-rwe-cohort-study/
├── README.md                         # This file
├── DESCRIPTION                       # Study package metadata & dependencies
├── doc/
│   ├── study-protocol.md             # Full RWE study protocol (PICOT, estimand, design)
│   └── statistical-analysis-plan.md  # Pre-specified statistical analysis plan
├── cohorts/
│   ├── codelists/
│   │   └── exposure_codelist.csv     # Concept-level codelists (RxNorm / SNOMED / ICD-mapped)
│   └── README.md                     # How cohort definitions map to OMOP concept sets
├── R/
│   ├── 01_setup_connection.R         # Connect to the OMOP CDM (Eunomia) & reference CDM
│   ├── 02_define_cohorts.R           # Build target, comparator & outcome cohorts
│   ├── 03_cohort_characterization.R  # Baseline characterisation & covariate balance (Table 1)
│   ├── 04_comparative_analysis.R     # PS estimation, matching/stratification, outcome model
│   ├── 05_sensitivity_analysis.R     # Negative controls, alternative PS specs, E-values
│   └── utils.R                       # Shared helpers, logging, paths
├── analysis/
│   └── run_study.R                   # Master script — runs the full pipeline end to end
├── output/                           # Generated tables, figures, diagnostics (git-ignored)
└── extras/
    └── session_info.txt              # Captured R session for reproducibility
```

---

## The analytical pipeline

The study executes as a single reproducible pipeline (`analysis/run_study.R`), staged so each step
produces inspectable, documented output:

1. **Connect & reference the CDM** — establish a connection to the OMOP-CDM instance and build a
   CDM reference object (`R/01_setup_connection.R`).
2. **Define cohorts** — construct the target (celecoxib new users), comparator (non-selective NSAID
   new users), and outcome (GI haemorrhage) cohorts from concept sets over standardised vocabularies
   — RxNorm for drugs, SNOMED for conditions, with ICD/NDC/HCPCS source codes mapped into OMOP
   standard concepts (`R/02_define_cohorts.R`).
3. **Characterise** — produce a baseline "Table 1", assess cohort comparability, and report
   attrition (`R/03_cohort_characterization.R`).
4. **Estimate the effect** — fit a large-scale propensity-score model, perform PS matching and
   stratification, check covariate balance and equipoise (preference-score overlap), then fit a
   Cox outcome model for the on-treatment and intention-to-treat estimands
   (`R/04_comparative_analysis.R`).
5. **Stress-test** — run a panel of negative-control outcomes to calibrate the effect estimate,
   refit under alternative PS specifications, and compute E-values for unmeasured confounding
   (`R/05_sensitivity_analysis.R`).

---

## Methods demonstrated

- **Study design:** new-user active-comparator cohort design; target-trial emulation; explicit estimand specification.
- **Confounding control:** large-scale propensity scores; 1:1 and variable-ratio matching; PS stratification; covariate-balance diagnostics (standardised mean differences).
- **Outcome modelling:** Cox proportional-hazards for time-to-event; on-treatment vs. intention-to-treat.
- **Robustness:** negative-control calibration; empirical null distribution; E-values; alternative model specifications.
- **Standardised data:** OMOP-CDM v5.3; RxNorm, SNOMED, ICD-9/10, NDC, HCPCS, LOINC vocabularies.

---

## How to run

**Prerequisites:** R (≥ 4.2). The OHDSI packages and Eunomia install from CRAN/GitHub.

```r
# From the repository root, in R:
source("analysis/run_study.R")
```

On first run this downloads the Eunomia sample CDM automatically (set `EUNOMIA_DATA_FOLDER` in
your `.Renviron` first — see `R/01_setup_connection.R` for the one-line setup). All outputs are
written to `output/`. A captured session for exact reproducibility is written to
`extras/session_info.txt`.

> **Note on completeness.** This is a working scaffold with the full study skeleton in place. Steps
> marked `# TODO` in the scripts (concept-set IDs, final covariate settings) are completed against
> the Eunomia vocabulary as the study is built out. The protocol and SAP are complete and define
> every analytic choice.

---

## Key references

- Hripcsak G, et al. *Observational Health Data Sciences and Informatics (OHDSI): Opportunities for Observational Researchers.* Stud Health Technol Inform. 2015.
- *The Book of OHDSI.* OHDSI, 2021. https://ohdsi.github.io/TheBookOfOhdsi/
- Hernán MA, Robins JM. *Using Big Data to Emulate a Target Trial When a Randomized Trial Is Not Available.* Am J Epidemiol. 2016.
- Schuemie MJ, et al. *Improving reproducibility by using high-throughput observational studies with empirical calibration.* Phil Trans R Soc A. 2018.

---

## Author

**Agniva Das**, Ph.D. (Statistics)
Quantitative researcher — observational health data, causal inference, and applied biostatistics.
[Google Scholar] · [ORCID: 0000-0002-5536-371X] · [LinkedIn]

*This repository is an independent methodological demonstration on public synthetic data. It does
not use or expose any real patient data.*
