# Statistical Analysis Plan (SAP)

**Study:** Risk of GI haemorrhage — selective vs. non-selective NSAIDs (OMOP-CDM comparative cohort)
**Version:** 1.0 | **Status:** Pre-specified before analysis

---

## 1. Analysis populations

- **Full analysis set:** all subjects satisfying the new-user eligibility criteria in either arm.
- **Matched set:** subjects retained after 1:1 propensity-score matching (primary).
- **Stratified set:** all eligible subjects, stratified into PS deciles (secondary).

## 2. Covariates

Baseline covariates are constructed over the 365-day pre-index window and include:
demographic variables (age in 5-year bands, sex); prior condition occurrences; prior drug
exposures; prior procedures; prior measurements; and healthcare-utilisation/visit-context
features. Covariates are derived automatically from the OMOP CDM to support a large-scale,
data-driven propensity model rather than a hand-picked confounder list.

## 3. Propensity-score model

- **Estimator:** L1-regularised (LASSO) logistic regression; regularisation hyperparameter
  selected by cross-validation.
- **Strategies:** (i) 1:1 greedy matching on the logit of the PS within a caliper of 0.2 SD
  (primary); (ii) stratification into PS deciles (secondary).
- **Diagnostics:** standardised mean differences (SMD) before and after adjustment for all
  covariates; preference-score distribution overlap; equipoise check; PS distribution plots.
- **Balance criterion:** post-adjustment |SMD| < 0.1 for all covariates.

## 4. Outcome model

- **Model:** Cox proportional-hazards regression for time to first GI haemorrhage.
- **Primary estimand:** on-treatment hazard ratio in the matched population.
- **Co-primary estimand:** intention-to-treat hazard ratio.
- **Time-at-risk:** begins index + 1 day. On-treatment: until discontinuation (+ persistence gap),
  outcome, end of observation, or end of study, whichever first. Intention-to-treat: fixed horizon
  from index.
- **Proportional-hazards assumption:** assessed via scaled Schoenfeld residuals.

## 5. Sensitivity and bias analyses

1. **Negative-control calibration.** A panel of pre-specified negative-control outcomes is analysed
   identically to the primary outcome. The empirical distribution of their effect estimates defines
   a systematic-error (empirical null) distribution against which the primary estimate and its
   confidence interval are calibrated.
2. **E-value.** Computed for the point estimate and the confidence limit nearest the null, to
   quantify the strength of unmeasured confounding required to explain away the association.
3. **Specification robustness.** Re-estimation under (a) an alternative PS model (different
   regularisation), (b) PS stratification instead of matching, and (c) the alternative time-at-risk
   window.

## 6. Missing data

Covariate construction in the OMOP CDM treats the absence of a record as the absence of the
corresponding event in the baseline window (an explicit modelling assumption documented here rather
than an imputation). Outcome and exposure dates are required fields by design of the cohort
definitions.

## 7. Reporting

The study reports: cohort attrition (CONSORT-style); a baseline characteristics table (Table 1)
before and after adjustment with SMDs; PS and preference-score overlap plots; the primary and
co-primary hazard ratios with 95% confidence intervals (uncalibrated and calibrated); the
negative-control calibration plot; and E-values. All numeric outputs are written to `output/`.

## 8. Software

R (≥ 4.2) with the OHDSI methods packages (cohort construction, large-scale PS estimation,
comparative cohort effect estimation, and empirical calibration). Exact package versions are
captured in `extras/session_info.txt` for reproducibility.
