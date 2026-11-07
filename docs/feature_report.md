# Thin-file repayment-risk features and Home Credit data coverage

## Scope

This report uses external evidence from regulator guidance, a lender disclosure, and peer-reviewed research to identify features used or considered in consumer-credit underwriting, especially when conventional credit history is limited.

The data assessment is restricted to the scope in `data_map.md`: `application_train.csv` and `application_test.csv`, with `HomeCredit_columns_description.csv` used to interpret column meanings. No other Home Credit tables are treated as available. Both application tables have one row per current application and are disjoint samples. `TARGET` is an outcome in the training table, not an underwriting feature.

No statistics or feature values were computed.

## What lenders use for thin-file applicants

Traditional consumer underwriting combines application information with credit-bureau information. OCC guidance lists income, occupation, employment continuity, rent or mortgage payments, outstanding balances, delinquencies, recent bureau inquiries, and recently opened accounts as common application/credit-scoring inputs. OCC retail-lending guidance also emphasizes repayment capacity measures such as income, payment-to-income, debt-service-to-income, total debt-to-income, housing burden, and disposable income.

For applicants with sparse conventional credit history, regulators recognize the potential value of alternative data. The 2019 interagency statement specifically discusses permissioned bank-account cash-flow data, including income and expense activity, fixed and variable expenses, and residual balances over time. A CFPB Request for Information identifies additional categories used or contemplated in the market: non-loan payment histories such as telecommunications, rent, insurance, and utilities; checking-account cash flow; stability signals such as changes in residence, employment, phone, or email; education and occupation; and digital/behavioral interactions.

A current lender disclosure provides a concrete industry example. Upstart states that its personal-loan underwriting variables include credit experience, employment, educational history, bank-account transactions, cost of living, and loan-application interactions. Peer-reviewed work by Berg et al. finds that digital-footprint variables can add predictive information and complement bureau scores, including for consumers with limited traditional credit information.

## Feature-by-feature assessment

| Feature used in underwriting | Evidence | Can the scoped Home Credit data build it? | Exact columns / limitation |
|---|---|---|---|
| **Income level and source** | OCC Retail Lending; OCC Credit Card Lending | **Yes** | Both `application_train.csv` and `application_test.csv`: `AMT_INCOME_TOTAL`, `NAME_INCOME_TYPE`. |
| **Employment stability and occupation** | OCC Credit Card Lending; CFPB Alternative Data RFI; Upstart 2025 Form 10-K | **Yes, with a data-quality caveat** | Both tables: `DAYS_EMPLOYED`, `OCCUPATION_TYPE`, `ORGANIZATION_TYPE`, `NAME_INCOME_TYPE`. `data_map.md` identifies `DAYS_EMPLOYED = 365243` as a sentinel inconsistent with the dictionary meaning, so that value cannot be treated as actual tenure. |
| **Proposed-loan amount and payment burden** | OCC Retail Lending | **Yes for the proposed Home Credit loan** | Both tables: `AMT_CREDIT`, `AMT_ANNUITY`, `AMT_GOODS_PRICE`, `AMT_INCOME_TOTAL`, `NAME_CONTRACT_TYPE`. These fields are sufficient to construct proposed-loan affordability features such as payment relative to income, without computing them here. |
| **Total debt-service / total debt-to-income** | OCC Retail Lending; OCC Credit Card Lending | **No, not from the scoped tables** | `AMT_ANNUITY` describes the current requested loan, but the two application tables do not contain complete balances and required payments for the applicant's other debts. Therefore total DTI or total monthly debt service cannot be built from this scope. |
| **Housing situation and housing burden** | OCC Retail Lending; OCC Credit Card Lending | **Partial** | Both tables: `NAME_HOUSING_TYPE`, `FLAG_OWN_REALTY` describe housing status/ownership. The scoped data do **not** provide rent, mortgage payment, property tax, insurance, or other housing-cost amounts, so a true housing-burden ratio cannot be built. |
| **Traditional credit score / external risk score** | OCC Credit Card Lending; Upstart 2025 Form 10-K | **Partial** | Both tables: `EXT_SOURCE_1`, `EXT_SOURCE_2`, `EXT_SOURCE_3`. The dictionary calls these normalized scores from external data sources, but does not identify their providers, inputs, scale interpretation, or whether they are bureau scores. They can be used as opaque external-risk features, but not interpreted as FICO-equivalent scores. |
| **Credit-file depth, balances, utilization, delinquencies, and repayment history** | OCC Credit Card Lending | **No, not from the scoped tables** | The application tables do not contain account-level tradelines, open dates, balances, limits, delinquency histories, or payment histories. Those features require credit-history tables outside the `data_map.md` scope. |
| **Recent credit-seeking / bureau inquiries** | OCC Credit Card Lending | **Yes** | Both tables: `AMT_REQ_CREDIT_BUREAU_HOUR`, `AMT_REQ_CREDIT_BUREAU_DAY`, `AMT_REQ_CREDIT_BUREAU_WEEK`, `AMT_REQ_CREDIT_BUREAU_MON`, `AMT_REQ_CREDIT_BUREAU_QRT`, `AMT_REQ_CREDIT_BUREAU_YEAR`. These support inquiry-intensity/recency features without calculating them here. |
| **Bank-account cash flow and residual balances** | 2019 Interagency Alternative Data Statement; CFPB Alternative Data RFI; Upstart 2025 Form 10-K | **No** | No columns in either application table contain bank transactions, deposits, withdrawals, account balances, recurring expenses, overdrafts, or residual balances over time. `AMT_INCOME_TOTAL` is reported income, not cash-flow history. |
| **Non-loan payment history: rent, utilities, telecom, insurance** | CFPB Alternative Data RFI | **No** | The application tables contain no payment histories for rent, utilities, telecommunications, or insurance. `FLAG_MOBIL`, `FLAG_PHONE`, `FLAG_EMAIL`, and related contact fields indicate contact availability, not whether recurring bills were paid on time. |
| **Education and occupational attainment** | CFPB Alternative Data RFI; Upstart 2025 Form 10-K | **Yes** | Both tables: `NAME_EDUCATION_TYPE`, `OCCUPATION_TYPE`, `ORGANIZATION_TYPE`. These are available as application-level nontraditional variables. Their use would still require fair-lending, explainability, and model-governance review. |
| **Stability signals from changes in employment/contact/residence** | CFPB Alternative Data RFI | **Partial** | Both tables: `DAYS_EMPLOYED`, `DAYS_REGISTRATION`, `DAYS_LAST_PHONE_CHANGE`, plus `REG_REGION_NOT_LIVE_REGION`, `REG_REGION_NOT_WORK_REGION`, `LIVE_REGION_NOT_WORK_REGION`, `REG_CITY_NOT_LIVE_CITY`, `REG_CITY_NOT_WORK_CITY`, `LIVE_CITY_NOT_WORK_CITY`. These are limited proxies: there is no longitudinal history of multiple residence, employer, phone, or email changes. `DAYS_EMPLOYED` also has the sentinel issue noted above. |
| **Cost-of-living / household expense context** | 2019 Interagency Alternative Data Statement; Upstart 2025 Form 10-K | **Partial** | Both tables: `CNT_CHILDREN`, `CNT_FAM_MEMBERS`, `NAME_FAMILY_STATUS`, `REGION_POPULATION_RELATIVE`, `REGION_RATING_CLIENT`, `REGION_RATING_CLIENT_W_CITY`. These provide household and regional context but not actual living-expense amounts. `data_map.md` also flags one `REGION_RATING_CLIENT_W_CITY = -1` value in `application_test.csv`, outside the documented `(1,2,3)` range. |
| **Digital / application-interaction behavior** | CFPB Alternative Data RFI; Upstart 2025 Form 10-K; Berg et al. (2020) | **Very limited / mostly no** | Both tables have only coarse application timing: `WEEKDAY_APPR_PROCESS_START`, `HOUR_APPR_PROCESS_START`. They do not contain device, browser, website-navigation, clickstream, typing, email-domain, or similar digital-footprint data. These two timing fields should not be treated as equivalent to a full digital footprint. |

## Bottom line

Within the restricted two-table scope, the strongest directly buildable feature groups are:

- reported income and income type;
- employment tenure/type and occupation;
- proposed-loan amount and annuity relative to applicant income;
- housing status/ownership;
- external normalized risk scores;
- recent credit-bureau inquiry counts;
- education/occupation and limited stability/household context.

The largest gaps for a **thin-file** underwriting problem are the same areas regulators highlight as useful complements to conventional credit history: detailed credit-account performance, total outstanding debt, permissioned bank-account cash flow, recurring non-loan payment history, and richer behavioral/digital data. Those cannot be reconstructed from `application_train.csv` and `application_test.csv` alone.

## Sources

1. Office of the Comptroller of the Currency (OCC), **Retail Lending, Comptroller's Handbook** (2021).  
   https://www.occ.treas.gov/publications-and-resources/publications/comptrollers-handbook/files/retail-lending/index-retail-lending.html

2. Office of the Comptroller of the Currency (OCC), **Credit Card Lending, Comptroller's Handbook**.  
   https://www.occ.treas.gov/publications-and-resources/publications/comptrollers-handbook/files/credit-card-lending/pub-ch-credit-card.pdf

3. Board of Governors of the Federal Reserve System, CFPB, FDIC, NCUA, and OCC, **Interagency Statement on the Use of Alternative Data in Credit Underwriting** (2019).  
   https://www.fdic.gov/news/speeches/2019/spdec0319.html

4. Consumer Financial Protection Bureau, **Request for Information Regarding Use of Alternative Data and Modeling Techniques in the Credit Process**, Docket CFPB-2017-0005 (2017). This is a formal regulatory RFI, not a blog post.  
   https://files.consumerfinance.gov/f/documents/20170214_cfpb_Alt-Data-RFI.pdf

5. Upstart Holdings, Inc., **2025 Form 10-K**, section “Variables and Training Data.”  
   https://www.sec.gov/Archives/edgar/data/1647639/000164763926000027/upst-20251231.htm

6. Berg, T., Burg, V., Gombović, A., & Puri, M. (2020), **“On the Rise of FinTechs: Credit Scoring Using Digital Footprints,”** *The Review of Financial Studies*, 33(7), 2845–2897.  
   https://academic.oup.com/rfs/article/33/7/2845/5568311
