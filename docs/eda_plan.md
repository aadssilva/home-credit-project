# EDA Plan — Home Credit Default Risk

## Purpose

This plan translates the five approved EDA questions into a simple, dependency-aware analysis sequence. No analysis or model code is executed at this stage.

The questions all use **payment difficulty** as the outcome, represented by `TARGET`. Therefore, the primary table for this EDA is `application_train.csv`, because `application_test.csv` does not contain `TARGET`. The two application tables are disjoint samples and should not be joined for these analyses.

## General analysis conventions

- Interpret `TARGET = 1` as the observed payment-difficulty outcome and `TARGET = 0` as no observed payment difficulty.
- Use association language, not causal language. These analyses can show that a characteristic is associated with payment difficulty; they cannot show that it causes payment difficulty.
- Report sample size and missingness for every variable used before interpreting an association.
- Treat `DAYS_EMPLOYED = 365243` as an undocumented sentinel and **not** as literal employment tenure. Keep it as a separate unknown/sentinel group or exclude it from tenure calculations while reporting its frequency.
- For skewed continuous variables, use simple quantile-based groups or interpretable bands so that output remains understandable to a business audience.
- Do not use `application_test.csv` to answer these EDA questions because it has no outcome label. It may become relevant later when a final modeling/scoring workflow is approved.

---

## Recommended order

The original Question 1 is intentionally moved to the end because it asks which characteristics are **most strongly associated** with payment difficulty. That conclusion should synthesize the results of the more specific questions rather than precede them.

### 1. Original Question 2 — Is payment difficulty associated with the applicant's ability to afford the proposed loan?

**Status:** **Partially answerable.** The data can measure the burden of the **proposed** loan relative to reported income, but it cannot establish full affordability because it does not contain existing debt payments, household expenses, residual cash flow, interest rate, or loan term.

**Recommended operational wording:**  
*Is payment difficulty associated with application-level proxies for the burden of the proposed loan relative to reported income?*

**Method**

1. Inspect missingness and basic distributions for income, requested credit, annuity, and goods price.
2. Create simple proposed-loan burden ratios, subject to valid positive denominators:
   - `AMT_ANNUITY / AMT_INCOME_TOTAL` — payment burden relative to reported income.
   - `AMT_CREDIT / AMT_INCOME_TOTAL` — requested credit relative to reported income.
   - Optionally, `AMT_GOODS_PRICE / AMT_INCOME_TOTAL` as a secondary exposure-size measure.
3. Divide each ratio into simple quantile groups (for example, quintiles) and calculate the payment-difficulty rate in each group.
4. Check whether payment difficulty generally increases as the burden measure increases.
5. Keep the analysis descriptive; no causal interpretation is required.

**Tables and columns needed**

- `application_train.csv`
  - `TARGET`
  - `AMT_INCOME_TOTAL`
  - `AMT_ANNUITY`
  - `AMT_CREDIT`
  - `AMT_GOODS_PRICE` (secondary)

**Expected output**

- One summary table for each burden measure with:
  - burden band / quintile;
  - applicant count;
  - percentage of applicants;
  - payment-difficulty rate.
- One simple line or bar chart showing payment-difficulty rate by burden band.
- A short interpretation stating whether greater proposed-loan burden is associated with higher observed payment difficulty.
- A limitation note stating that this is **not a full debt-to-income or cash-flow affordability measure**.

---

### 2. Original Question 3 — How well do the external risk scores distinguish applicants who experience payment difficulty from those who do not?

**Status:** **Answerable for discrimination, with an interpretation limitation.** The three variables are described only as normalized external-source scores; their source and construction are unknown.

**Method**

1. Report missingness for `EXT_SOURCE_1`, `EXT_SOURCE_2`, and `EXT_SOURCE_3`.
2. Compare score distributions for `TARGET = 0` and `TARGET = 1` using medians and simple distribution plots.
3. Divide each score into quantiles or deciles and calculate payment-difficulty rate in each band.
4. Calculate univariate ROC-AUC for each score against `TARGET` to quantify how well the score separates the two outcome groups.
5. Report the observed score direction explicitly rather than assuming that a larger score means greater risk.

**Tables and columns needed**

- `application_train.csv`
  - `TARGET`
  - `EXT_SOURCE_1`
  - `EXT_SOURCE_2`
  - `EXT_SOURCE_3`

**Expected output**

- A comparison table with one row per external score showing:
  - non-missing observations;
  - missing percentage;
  - median score for `TARGET = 0`;
  - median score for `TARGET = 1`;
  - ROC-AUC;
  - observed direction of association.
- One chart showing payment-difficulty rate by score band/decile for each external score.
- A short conclusion identifying which external score provides the strongest standalone discrimination in this sample.

---

### 3. Original Question 4 — Is greater recent credit-seeking activity associated with higher payment difficulty?

**Status:** **Answerable.** The application table contains bureau-inquiry counts over several lookback windows.

**Method**

1. Inspect missingness and distributions for all bureau-inquiry variables.
2. Analyze each lookback window separately:
   - hour;
   - day;
   - week;
   - month;
   - quarter;
   - year.
3. Do **not** simply add the six variables together because the lookback windows can overlap and the resulting sum would not have a clear interpretation.
4. For each window, group inquiry counts into simple bands such as `0`, `1`, `2`, and `3+`, adjusted if the data are sparse.
5. Calculate applicant count and payment-difficulty rate for each band.
6. Assess whether payment difficulty shows a consistent upward pattern as inquiry count increases.

**Tables and columns needed**

- `application_train.csv`
  - `TARGET`
  - `AMT_REQ_CREDIT_BUREAU_HOUR`
  - `AMT_REQ_CREDIT_BUREAU_DAY`
  - `AMT_REQ_CREDIT_BUREAU_WEEK`
  - `AMT_REQ_CREDIT_BUREAU_MON`
  - `AMT_REQ_CREDIT_BUREAU_QRT`
  - `AMT_REQ_CREDIT_BUREAU_YEAR`

**Expected output**

- A compact table by lookback window and inquiry-count band containing:
  - applicant count;
  - percentage of applicants;
  - payment-difficulty rate.
- One small-multiple or grouped chart showing how payment-difficulty rate changes with inquiry count for the most informative windows.
- A short conclusion describing whether recent credit-seeking is associated with greater payment difficulty and which lookback window shows the clearest pattern.

---

### 4. Original Question 5 — Which indicators of income and employment stability are associated with repayment outcomes?

**Status:** **Partially answerable.** Income level/source and current employment context are available, but true income stability and longitudinal employment history are not.

**Recommended operational wording:**  
*Which available indicators of income level/source and current employment context or tenure are associated with payment difficulty?*

**Method**

1. Analyze reported income amount:
   - inspect distribution and missingness;
   - use quantiles or interpretable bands;
   - compare payment-difficulty rates across bands.
2. Analyze income source using `NAME_INCOME_TYPE` and compare payment-difficulty rates across categories.
3. Analyze current-employment tenure using valid `DAYS_EMPLOYED` values:
   - convert valid negative day counts to positive tenure duration for interpretation;
   - do not interpret `365243` as tenure;
   - place the sentinel in a separate category or report it separately.
4. Compare payment-difficulty rates by `OCCUPATION_TYPE` and `ORGANIZATION_TYPE`.
5. For high-cardinality categorical variables, combine very small categories into an `Other` group or suppress unstable comparisons using a pre-specified minimum group size.

**Tables and columns needed**

- `application_train.csv`
  - `TARGET`
  - `AMT_INCOME_TOTAL`
  - `NAME_INCOME_TYPE`
  - `DAYS_EMPLOYED`
  - `OCCUPATION_TYPE`
  - `ORGANIZATION_TYPE`

**Expected output**

- Income-band table with applicant count and payment-difficulty rate.
- Income-source table with applicant count and payment-difficulty rate.
- Employment-tenure-band table with applicant count and payment-difficulty rate.
- Compact tables for occupation and organization type, with small categories consolidated if needed.
- One or two simple charts highlighting the clearest patterns.
- A limitation statement that these fields describe an **application-time snapshot**, not longitudinal income or employment stability.

---

### 5. Original Question 1 — Which applicant characteristics are most strongly associated with payment difficulty?

**Status:** **Answerable as a descriptive synthesis.** This question is broad, so it should summarize the preceding analyses rather than duplicate them.

**Method**

1. Use the feature families already analyzed in Questions 2–5:
   - proposed-loan burden;
   - external risk scores;
   - recent credit-seeking;
   - income and employment indicators.
2. Add a small number of basic application characteristics only if needed for a broader applicant-profile view, for example:
   - `DAYS_BIRTH`;
   - `NAME_EDUCATION_TYPE`;
   - `NAME_HOUSING_TYPE`;
   - `CNT_CHILDREN` / `CNT_FAM_MEMBERS`;
   - `FLAG_OWN_CAR` / `FLAG_OWN_REALTY`.
3. Convert numeric variables to a small number of interpretable bands and use existing categories for categorical variables.
4. For each characteristic, calculate a simple **payment-difficulty rate spread**: the difference, in percentage points, between the highest- and lowest-risk sufficiently sized groups.
5. Rank the characteristics by this descriptive spread, while also considering whether the pattern is monotonic and based on adequate sample sizes.
6. Use this as a prioritization device for later modeling, not as proof of causal importance or independent predictive contribution.

**Tables and columns needed**

- `application_train.csv`
  - `TARGET`
  - all columns used in Questions 2–5;
  - optional basic applicant-profile columns listed above.

**Expected output**

- A ranked summary table containing:
  - characteristic;
  - comparison/bands used;
  - lowest observed payment-difficulty rate;
  - highest observed payment-difficulty rate;
  - absolute spread in percentage points;
  - direction/pattern;
  - important missingness or interpretation note.
- One bar chart showing the strongest descriptive associations.
- A concise synthesis identifying which characteristics should receive the most attention in the later modeling phase.

---

## Feasibility and wording flags

| Original question | Classification | Flag |
|---|---|---|
| 1. Which applicant characteristics are most strongly associated with payment difficulty? | Question | Answerable, but broad; best used as the final synthesis. |
| 2. Is payment difficulty associated with the applicant's ability to afford the proposed loan? | Question | **Partially answerable.** Proposed-loan burden can be measured, but full affordability cannot. |
| 3. How well do the external risk scores distinguish applicants who experience payment difficulty from those who do not? | Question | Answerable; score provenance is unknown, but discrimination can be measured. |
| 4. Is greater recent credit-seeking activity associated with higher payment difficulty? | Question | Answerable using bureau-inquiry counts. |
| 5. Which indicators of income and employment stability are associated with repayment outcomes? | Question | **Partially answerable.** Current income/employment indicators exist, but longitudinal stability does not. |

**Description rather than question:** None. All five items are genuine analytical questions.

**Completely unanswerable questions:** None, provided Questions 2 and 5 are interpreted using the narrower proxy-based wording above.

## Final dependency chain

`Q2 affordability proxies` → `Q3 external scores` → `Q4 credit seeking` → `Q5 income/employment` → `Q1 cross-question synthesis`

This order ensures that the broad ranking in Question 1 is based on results that have already been produced and interpreted.
