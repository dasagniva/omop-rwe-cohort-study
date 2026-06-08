# Cohort definitions

Cohort logic is specified as **concept sets** over the OMOP standardised vocabularies and
materialised against the CDM. In a production OHDSI workflow these are authored in
[ATLAS](https://atlas-demo.ohdsi.org/) and exported as JSON + parameterised SQL; here the
specification is captured as editable codelists plus the resolution logic in
`R/02_define_cohorts.R`.

## How source codes map into the cohorts

Real-world data arrive in source vocabularies — **ICD-9/10** (diagnoses), **NDC** (drugs),
**HCPCS** (procedures), **LOINC** (labs). The OMOP CDM maps these source codes onto **standard
concepts** (RxNorm for drugs, SNOMED for conditions) via the `concept_relationship` and
`concept_ancestor` tables. Defining a cohort on a standard concept and its descendants therefore
captures all equivalent source codes automatically — the central advantage of analysing
standardised data.

| Cohort | Standard vocabulary | Illustrative mapped source codes |
|---|---|---|
| Target (celecoxib) | RxNorm | NDC product codes |
| Comparator (ns-NSAIDs) | RxNorm | NDC product codes |
| Outcome (GI haemorrhage) | SNOMED | ICD-9 578.x, ICD-10 K92.x |

See `codelists/exposure_codelist.csv` for the editable specification.
