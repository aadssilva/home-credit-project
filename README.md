# home-credit-project

*Author: Anderson Silva*

## Project Overview

**Home Credit Default Risk**

Many people struggle to get loans because they have little or no credit history. This creates a challenge for lenders like Home Credit, which aims to broaden access to credit while keeping repayment risk under control.

The problem is finding a balance between approving applicants who may have difficulty repaying their loans and rejecting applicants who would otherwise be able to repay.

This project explores how Home Credit's application data can be used to assess repayment risk better and support lending decisions. The analysis covers data exploration, preparation, predictive modeling, and the financial implications of different loan approval thresholds.

## Methodology

The project follows five main steps:

1. Define the business problem and project scope.
2. Explore the application data and identify data-quality issues and relevant patterns.
3. Prepare and engineer features based on the EDA findings.
4. Develop and compare predictive models.
5. Evaluate model results, approval thresholds, and their implications for lending decisions.

The current implementation uses `application_train.csv` and `application_test.csv`, with 307,511 and 48,744 records, respectively. The `TARGET` variable is treated as an indicator of payment difficulty, not as an accounting definition of default.

### Exploratory Data Analysis

The [EDA notebook](notebooks/01_eda.qmd) examines data quality, missing values, financial ratios, external credit scores, and applicant characteristics associated with payment difficulty.

Some of the main findings were:

- About 8.07% of training applications have the payment-difficulty indicator.
- Applicants with missing bureau inquiry information have a higher observed payment-difficulty rate (10.34% versus 7.72%).
- External credit scores, income, and employment duration show differences in repayment outcomes across applicant groups.
- Several fields contain invalid or undocumented values that need to be addressed before modeling.

These findings helped define the data preparation rules and the features considered in the modeling stage.

Supporting documentation: [Data Map](docs/data_map.md) | [EDA Plan](docs/eda_plan.md) | [Feature Report](docs/feature_report.md)

### Data Preparation

The preparation workflow is implemented in [scripts/01_data_preparation.R](scripts/01_data_preparation.R).

The script uses reusable functions to apply consistent transformations to training and test data. The main decisions were based on issues identified during EDA:

| EDA finding                                                                      | Data preparation                                             |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `DAYS_EMPLOYED = 365243` is an invalid sentinel value                            | Convert it to missing                                        |
| `REGION_RATING_CLIENT_W_CITY = -1` is outside the documented range               | Convert it to missing                                        |
| `CODE_GENDER = "XNA"` is undocumented                                            | Convert it to missing                                        |
| Age and employment duration are stored as negative relative days                 | Create `age_years` and `tenure_years`                        |
| Proposed loan amounts can be compared with reported income                       | Create `annuity_income`, `credit_income`, and `goods_income` |
| Missingness in external scores and bureau inquiry fields may contain information | Add nine missingness indicators                              |
| `annuity_income` was analyzed using five groups                                  | Create `annuity_income_quintile`                             |

No rows are removed, and the original variables are preserved.

The script also checks that train and test have the same predictor columns, that `SK_ID_CURR` remains unique, and that `TARGET` is present only in the training data.

The quintile thresholds are calculated from training data and reused on test data. Other model-specific transformations, such as imputation and categorical encoding, are handled during modeling.

### Running the Preparation Script

From the repository root:

```bash
Rscript scripts/01_data_preparation.R
```

**Inputs:**

- `data/raw/application_train.csv`
- `data/raw/application_test.csv`

**Outputs:**

- `data/processed/application_train_prepared.csv`
- `data/processed/application_test_prepared.csv`

| Dataset | Raw           | Prepared      |
| ------- | ------------- | ------------- |
| Train   | 307,511 × 122 | 307,511 × 137 |
| Test    | 48,744 × 121  | 48,744 × 136  |

Raw data and generated files are excluded from GitHub.

## Modeling

The modeling work is documented in [02_modeling.qmd](notebooks/02_modeling.qmd).

I compared a majority-class baseline, ridge logistic regression with different feature sets, and XGBoost. Threefold cross-validation was used, with ROC-AUC as the main evaluation metric because of the class imbalance.

The majority-class baseline achieved an ROC-AUC of 0.50. Ridge logistic regression ranged from 0.7433 to 0.7460, while the original XGBoost achieved 0.7535. Downsampling was also tested but slightly reduced XGBoost's performance.

Hyperparameter tuning was performed afterward. However, the tuned version did not improve the results. In the subsequent evaluation, the original XGBoost model remained the preferred option.

| Model            | CV ROC-AUC | Holdout ROC-AUC |
| ---------------- | ---------: | --------------: |
| Original XGBoost |     0.7535 |          0.7576 |
| Tuned XGBoost    |     0.7324 |          0.7355 |

The original model also recorded Kaggle scores of 0.74203 (Public) and 0.74116 (Private).

## Model Card and Business Value

The [Model Card](notebooks/03_model_card.qmd) extends the modeling work by examining how predicted repayment risk could support loan approval decisions.

Rather than using the usual classification threshold of 0.50, I evaluated different thresholds based on their estimated financial outcomes.

Under the assumptions used in the analysis, a threshold of 0.10 produced:

- **73.8% approval rate**, with 4.32% observed payment difficulty among approved applicants.
- **43.5% higher simulated net benefit** compared with a threshold of 0.50.

The financial simulation uses a 10.62% gross-spread proxy and an assumed 13.5% recovery rate. These are estimated outcomes based on the available data and assumptions, not actual profits or savings for Home Credit.

The Model Card also includes SHAP explanations and fairness comparisons by gender and education. Some differences in approval and error rates require further investigation, and the use of sensitive applicant characteristics raises additional concerns.

For these reasons, I would not recommend using the current model for automated credit decisions without further validation, a review of its inputs, and additional fairness and regulatory checks.

## Project Files

| File                                                     | Description                                                              |
| -------------------------------------------------------- | ------------------------------------------------------------------------ |
| [Business Problem Statement](docs/BusinessStatement.md)  | Business objective, proposed success metrics, and project scope          |
| [EDA Notebook](notebooks/01_eda.qmd)                     | Data exploration, quality checks, and findings                           |                |
| [Modeling Notebook](notebooks/02_modeling.qmd)           | Model comparisons, tuning, and evaluation                                |                                           |
| [Model Card](notebooks/03_model_card.qmd)                   | Performance, financial analysis, explanations, fairness, and limitations |

The data can be obtained from the [Home Credit Default Risk competition](https://www.kaggle.com/competitions/home-credit-default-risk) on Kaggle.
