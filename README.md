# Home Credit Default Risk: Extending Responsible Credit Access Through Risk Analytics

*Author: Anderson Silva*

## Project overview

Home Credit provides loans to people who may have limited access to traditional credit. For the lender, the challenge is deciding who can repay without taking on too much risk. Approving applicants who may struggle with payments can lead to losses, while rejecting applicants who could repay limits both credit access and business opportunities.

This project uses the [Home Credit Default Risk dataset](https://www.kaggle.com/competitions/home-credit-default-risk) to explore how application data can help assess repayment risk and support lending decisions.

The analysis covers data exploration, preparation, predictive modeling, and the financial implications of different approval thresholds. It also examines model explanations and differences in approval rates across applicant groups.

## Results at a glance

| Metric | Result |
|---|---|
| Selected model | XGBoost |
| Cross-validation ROC-AUC | 0.7535 |
| Holdout ROC-AUC | 0.7576 |
| Kaggle Public / Private ROC-AUC | 0.7420 / 0.7412 |
| Approval rate at threshold 0.10 | 73.8% |
| Payment difficulty among approvals | 4.32% |
| Simulated net benefit vs. threshold 0.50 | +43.5% |

The original XGBoost model performed better than the other configurations tested. The approval-threshold analysis also showed that the model's financial implications depend on how its predictions are used.

The financial improvement is based on a simulation, not actual lending profits.

## Understanding the data

The analysis uses `application_train.csv`, which contains 307,511 applications, and `application_test.csv`, which contains 48,744 applications. Only the application-level tables were used.

The outcome variable, `TARGET`, indicates observed payment difficulty. About 8.07% of the training applications have `TARGET = 1`, making the dataset highly imbalanced.

The [EDA notebook](notebooks/01_eda.qmd) examined data quality, missing values, financial ratios, external risk scores, and applicant characteristics.

A few findings influenced the modeling approach:

- External risk scores showed the largest differences in payment-difficulty rates across applicant groups.
- Applicants with missing bureau inquiry information had a higher payment-difficulty rate (10.34% versus 7.72%). Missingness could therefore contain useful information.
- Income, employment duration, and occupation were associated with different repayment outcomes.
- Loan-to-income ratios did not show a consistent increase in payment difficulty. Larger ratios did not always correspond to higher observed risk.

The EDA also identified invalid and undocumented values, including the employment sentinel `365243`.

These findings guided data preparation. Invalid values were corrected, age and employment duration were converted into years, financial ratios were created, and missingness indicators were added.

The preparation process preserved the original number of applications and verified that the training and test datasets had the same predictor columns.

Supporting documents: [Business Problem Statement](docs/BusinessStatement.md) · [Data Map](docs/data_map.md) · [EDA Plan](docs/eda_plan.md) · [Feature Research](docs/feature_report.md)

## Modeling

The modeling stage compared a majority-class baseline, ridge logistic regression with different sets of predictors, and XGBoost. Downsampling and hyperparameter tuning were also tested.

Since approximately 92% of applications had no observed payment difficulty, accuracy alone would be misleading. A model predicting no payment difficulty for everyone would achieve about 92% accuracy while failing to identify any applicants who experienced payment difficulties.


For this reason, ROC-AUC was used as the main comparison metric, with three-fold cross-validation.

**Initial model comparison**

| Model | Mean CV ROC-AUC |
|---|---|
| Majority-class baseline | 0.5000
| Ridge logistic regression with engineered features | 0.7460
| Original XGBoost | 0.7535
| XGBoost with downsampling | 0.7512


The original XGBoost performed best in the cross-validation comparison. Downsampling slightly reduced its ROC-AUC, so it was not retained.

Hyperparameter tuning was performed afterward. The tuned configuration was used for a Kaggle submission, but its subsequent cross-validation and holdout results were lower than those of the original model.


**Subsequent evaluation**

| XGBoost configuration | CV ROC-AUC | Holdout ROC-AUC |
|---|---|---|
| Original | 0.7535 | 0.7576 |
| Tuned | 0.7324 | 0.7355


The tuned configuration was used for an earlier Kaggle submission. However, its subsequent cross-validation and holdout results were lower than those of the original model.

The original XGBoost was therefore selected for the later business analysis. Its Kaggle scores were 0.74203 (Public) and 0.74116 (Private).

[Modeling notebook](notebooks/02_modeling.qmd)

## From risk scores to lending decisions

A model can rank applicants by risk, but the lender still needs to decide which applications to approve.

To examine this, different approval thresholds were evaluated using the model's predicted probabilities and estimated financial gains and losses. Applicants with predicted payment-difficulty risk below the threshold were treated as approved in the simulation.

The threshold of 0.10 was selected using out-of-fold predictions and then evaluated on the holdout data.

| Holdout result | Threshold 0.10 | Threshold 0.50 |
|---|---|---|
| Approval rate | 73.80% | 99.84% |
| Payment difficulty among approvals | 4.32% | 7.90% |
| Estimated net benefit (dataset monetary units) | 1.822 billion | 1.270 billion |

The lower threshold approves fewer applicants, but the approved group has a lower observed payment-difficulty rate.

Under the financial assumptions used, the 0.10 threshold produced an estimated net benefit 43.5% higher than the 0.50 threshold.

The simulation used a 10.62% gross-spread proxy and an assumed recovery rate of 13.5%. It does not include all lending costs, and payment difficulty is not the same as a confirmed financial loss. These results illustrate a possible decision trade-off rather than a verified improvement in Home Credit's profits.

## Explainability and model limitations

The [Model Card](notebooks/03_model_card.qmd) extends the evaluation to model explanations, fairness, and deployment risks.

SHAP analysis identified the external risk scores as the strongest predictors. However, the dataset does not explain how these scores are calculated, which makes some credit-denial explanations difficult to justify.

The model also uses sensitive applicant characteristics. Gender, for example, ranked sixth in SHAP feature importance.

In the holdout simulation, the approval rate was 79.07% for female applicants and 63.74% for male applicants. Approval differences were also found across education groups.

These differences do not establish discrimination, but they require further investigation before the model could be used in lending decisions.

Probability calibration has not been verified, and the financial analysis relies on simplified assumptions. The available application data also leave out much of the detailed credit history that could help assess repayment capacity.

Given these limitations, the model is not recommended for automated credit decisions at this stage. A supervised pilot would require additional validation, a review of sensitive predictors, and better explanations for declined applications.

## What I would revisit

The project was limited to application-level data, although the Home Credit dataset includes previous applications, bureau records, and payment history.

Adding these tables would be a reasonable next step. It could provide information about past repayment behavior that the current models do not use.

I would also revisit probability calibration and the financial assumptions behind the approval policy. These are necessary before relying on the estimated financial benefit to support a real lending decision.

## Project files

| Document | Description |
|---|---|
| [Business Problem Statement](docs/BusinessStatement.md) | Business objective, scope, and proposed success criteria |
| [Data Map](docs/data_map.md) | Application-table structure and data-quality checks |
| [EDA Plan](docs/eda_plan.md) | Questions and analytical methods |
| [Feature Research](docs/feature_report.md) | Credit-risk features and their availability in the dataset |
| [EDA Notebook](notebooks/01_eda.qmd) | Exploratory analysis and preparation decisions |
| [Modeling Notebook](notebooks/02_modeling.qmd) | Model comparisons, downsampling, tuning, and evaluation |
| [Model Card](notebooks/03_model_card.qmd) | Performance, approval thresholds, financial simulation, SHAP, and fairness |

## Data

**Data:** [Home Credit Default Risk — Kaggle](https://www.kaggle.com/competitions/home-credit-default-risk).
