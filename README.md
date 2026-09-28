# home-credit-project
*Author: Anderson Silva*

## Project Overview
**Home Credit Default Risk**

Many people struggle to get loans due to insufficient or non-existent credit histories. And, unfortunately, this population is often taken advantage of by untrustworthy lenders.

Home Credit strives to broaden financial inclusion for the unbanked population by providing a safe, positive borrowing experience. To ensure this underserved population has a positive loan experience, Home Credit uses a variety of alternative data (including telco and transactional information )to predict its clients' repayment ability.

While Home Credit is currently using various statistical and machine learning methods to make these predictions, the goal here is to help them unlock the full potential of their data. Doing so will ensure that clients capable of repayment are not rejected and that loans are issued with a principal, maturity, and repayment calendar that empowers their clients to succeed.

## Methodology:

The project follows a analytics workflow:

1. Define the business problem and project scope.
2. Explore the application data and document data-quality issues and relevant patterns.
3. Prepare features based on findings from the exploratory data analysis.
4. Develop and evaluate predictive models.
5. Interpret model results in terms of repayment risk and business value.

The current implementation focuses on `application_train.csv` and `application_test.csv`.

### Data preparation:

The preparation workflow is implemented in:

[scripts/01_data_preparation.R](scripts/01_data_preparation.R)

The script is organized as reusable functions and applies the same deterministic transformations to both training and test data.

The main preparation decisions are:

| EDA finding | Data preparation |
| --- | --- |
| `DAYS_EMPLOYED = 365243` is an invalid sentinel value | Convert it to missing |
| `REGION_RATING_CLIENT_W_CITY = -1` is outside the documented range | Convert it to missing |
| `CODE_GENDER = "XNA"` is undocumented | Convert it to missing |
| Age and employment duration are stored as negative relative days | Create `age_years` and `tenure_years` |
| Proposed-loan amounts can be compared with reported income | Create `annuity_income`, `credit_income`, and `goods_income` |
| Missingness in external scores and bureau inquiry fields may contain information | Add nine missingness indicators |
| `annuity_income` was analyzed using five groups | Create `annuity_income_quintile` |

No rows are removed during preparation, and the original variables are preserved.

### Modeling Boundaries

This preparation layer keeps model-dependent decisions separate from deterministic data cleaning and feature engineering.

Numeric imputation, scaling, normalization, categorical encoding, rare-category grouping, train/validation splitting, and other model-specific preprocessing are left to the modeling stage. This avoids introducing assumptions before the modeling approach is defined.

The current version also uses only the application-level tables. Supplementary Home Credit tables can be incorporated later if the project scope is expanded to include historical credit behavior.

### Train/Test Consistency

All deterministic transformations use the same reusable functions for train and test data.

No mean or median imputation is performed at this stage. The only learned preprocessing parameter is the set of `annuity_income` quintile thresholds. These thresholds are calculated from the training data only and reused unchanged on the test data.

This keeps the feature definition consistent across both datasets and avoids learning preprocessing parameters from test data.

The final validation confirms that:

- train and test have identical predictor columns and column order;
- `TARGET` remains only in the training dataset;
- `SK_ID_CURR` remains unique in both datasets;
- the original number of rows is preserved;
- all engineered features are present in both datasets.

## Running the Preparation Script

From the repository root:

```bash
Rscript scripts/01_data_preparation.R
```

### Inputs

- `data/raw/application_train.csv`
- `data/raw/application_test.csv`

### Outputs

- `data/processed/application_train_prepared.csv`
- `data/processed/application_test_prepared.csv`

Final dimensions:

| Dataset | Raw | Prepared |
| --- | --- | --- |
| Train | 307,511 × 122 | 307,511 × 137 |
| Test | 48,744 × 121 | 48,744 × 136 |

Generated files under `data/processed/` are excluded from Git because they can be reproduced by running the preparation script.

### Statistical Analysis:

Model development and evaluation will be added in the next stage of the project.