# Study Protocol

**Title:** Risk of gastrointestinal haemorrhage among new users of selective COX-2 inhibitors
versus non-selective NSAIDs: a comparative new-user cohort study in the OMOP Common Data Model.

**Version:** 1.0 | **Status:** Pre-specified (finalised before analysis) | **Data model:** OMOP CDM v5.3

---

## 1. Background and rationale

Non-steroidal anti-inflammatory drugs (NSAIDs) are among the most widely used medications, and
upper gastrointestinal (GI) haemorrhage is a recognised adverse effect. Selective COX-2 inhibitors
were introduced with the hypothesis of a more favourable GI safety profile than non-selective
NSAIDs. This study estimates the comparative risk of GI haemorrhage between the two drug classes
using observational data standardised to the OMOP Common Data Model, applying the OHDSI
population-level estimation framework.

The study is conducted as a methodological demonstration on the OHDSI Eunomia synthetic dataset.
The design, however, mirrors a regulatory- and publication-grade real-world evidence (RWE) study so
that the analytic choices are transferable to licensed real-world data sources (EHR, claims, and
registries).

## 2. Objectives

**Primary objective.** To estimate the comparative risk of incident GI haemorrhage among adult
new users of celecoxib (selective COX-2 inhibitor) versus new users of non-selective NSAIDs.

**Secondary objectives.** (i) To characterise and compare the baseline covariate profiles of the
two exposure cohorts; (ii) to assess the robustness of the primary estimate to unmeasured
confounding and to modelling choices.

## 3. Target trial specification

The study is framed as an emulation of a hypothetical pragmatic randomised trial (target-trial
emulation), with the following protocol elements:

| Element | Target trial | Emulation in observational data |
|---|---|---|
| **Eligibility** | Adults initiating NSAID therapy, no prior NSAID use in 365 days, no prior GI bleed | New users identified by first qualifying drug-exposure record after a clean window |
| **Treatment strategies** | (A) Celecoxib; (B) non-selective NSAID | First observed qualifying exposure defines arm |
| **Assignment** | Randomised | Adjusted via large-scale propensity score |
| **Time zero** | Randomisation | Date of treatment initiation (index date) |
| **Outcome** | Incident GI haemorrhage | First condition-occurrence of GI haemorrhage after time zero |
| **Causal contrast** | Intention-to-treat & per-protocol | Intention-to-treat & on-treatment estimands |

## 4. Study design

**Design:** Retrospective, comparative, **new-user active-comparator cohort study**.

The new-user design restricts to incident initiators to avoid prevalent-user bias; the
active-comparator design (comparing two treatments for a shared indication, rather than
treatment vs. none) mitigates confounding by indication.

## 5. Population, exposures, outcome (PICOT)

- **P (Population):** Adults (≥ 18 years) with a qualifying NSAID initiation and a minimum
  pre-index observation period of 365 days.
- **I (Intervention):** New use of celecoxib (target cohort). Concept set defined over RxNorm
  ingredients and descendants.
- **C (Comparator):** New use of non-selective NSAIDs (comparator cohort).
- **O (Outcome):** Incident GI haemorrhage, defined over SNOMED condition concepts (with mapped
  ICD-9/10 source codes); first occurrence after index.
- **T (Time):** Time-at-risk begins the day after index. Two windows are pre-specified: an
  **on-treatment** window (exposure plus a persistence gap) and an **intention-to-treat** window
  (fixed horizon from index irrespective of discontinuation).

## 6. Estimand

The primary estimand is the **hazard ratio** for incident GI haemorrhage comparing celecoxib
initiation with non-selective NSAID initiation, in the population of new users, under the
on-treatment causal contrast, estimated in the propensity-score-matched population. The
intention-to-treat contrast is reported as a co-primary estimand.

## 7. Confounding control

A **large-scale propensity score** is estimated using regularised logistic regression on a
high-dimensional covariate set constructed from the baseline period (demographics; prior
conditions, drugs, procedures, and measurements; visit context). The PS is used in two
pre-specified strategies — **1:1 matching** and **stratification (deciles)** — with covariate
balance assessed by standardised mean differences (target: |SMD| < 0.1 on all covariates after
adjustment). Empirical equipoise is verified via preference-score overlap.

## 8. Bias and robustness assessment

- **Negative-control outcomes:** a pre-specified panel of outcomes with no plausible causal
  relationship to either exposure is analysed to estimate residual systematic error; estimates are
  empirically calibrated against the resulting null distribution.
- **Unmeasured confounding:** **E-values** are computed for the point estimate and confidence limit.
- **Specification robustness:** the primary estimate is refit under alternative PS model
  specifications and time-at-risk definitions.

## 9. Data source

OHDSI **Eunomia** synthetic dataset (Synthea-derived records and CMS SynPUF), standardised to
OMOP CDM v5.3. No real patient data are used at any stage.

## 10. Limitations

As a synthetic-data demonstration, effect estimates carry no clinical interpretation; the value of
the study is methodological — it demonstrates the design, estimation, and robustness workflow that
would be applied to licensed real-world data. Residual and unmeasured confounding, exposure and
outcome misclassification, and informative censoring are acknowledged as the standard limitations
of observational comparative-effectiveness research.

## 11. References

See the reference list in the repository `README.md`.
