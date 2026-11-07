**Business Problem**

Home Credit serves applicants with limited or no conventional credit history. Its underwriting process must manage two decision errors. Approving applicants who are likely to experience payment difficulty can weaken portfolio quality. Rejecting applicants who are likely to repay limits lending opportunities and customer access. The Kaggle dataset combines application, credit bureau, prior loan, card, and payment history data. The business problem is to use this history to improve risk differentiation and support an approval policy that balances portfolio quality with responsible access to credit.

**Analytics Approach**

The project will use supervised classification to estimate each applicant's probability of payment difficulty. ***TARGET*** will be treated as the dataset's observed proxy for payment difficulty, not as an accounting definition of default. Candidate models will be compared against a transparent benchmark model on held-out data. ***ROC-AUC*** will measure ranking quality, while approval-threshold scenarios will show how each option changes simulated approvals and observed payment difficulty. The recommended approach must also provide clear reason codes explaining the main factors behind a score and group-level performance results for review.

**Benefit of a Solution**

The expected benefit is a better balance between portfolio risk and access to credit. On historical data, the proposed targets are either to reduce the observed payment-difficulty rate among simulated approvals by at least 5% relative while holding the approval rate constant, or to increase the simulated approval rate by at least 2 percentage points while keeping the payment-difficulty rate at or below the benchmark. This should allow Home Credit to approve more applicants likely to repay while maintaining portfolio quality.

**Success Metrics**

Success will be assessed on the holdout sample against a benchmark model. The two risk and approval targets define estimated business value; ***ROC-AUC*** is a secondary model-quality measure:

- meet at least one of the two business targets above;

- achieve a higher holdout ***ROC-AUC*** than the benchmark;

- report approval and error rates for every applicant group supported by the data, with any material difference reviewed before a pilot is recommended.

These results estimate potential decision improvement. Realized financial value requires an approved pilot using internal approval-rate, exposure, loss, revenue, and collection-cost data.

**Scope**

Deliverables include a validated probability model, an applicant-level scored and ranked output, approval-threshold scenarios, documentation of data quality and model limitations, reason codes, group-level results, and an executive pilot recommendation. The work is limited to authorized Kaggle data and to 10 weeks. Production use requires privacy, fairness, model risk, latency, and regulatory review.

**Details**

The analytics team will complete the analysis within ten weeks of approval. Credit Risk and underwriting will own the lending-policy decision, with Compliance and Model Risk serving as reviewers. A pilot or deployment requires separate approval.
