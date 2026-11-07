# Home Credit data map

## Scope

Only these files were used:

- `application_train.csv`
- `application_test.csv`
- `HomeCredit_columns_description.csv` as the data dictionary

No other Home Credit tables or prior analysis files were used.

## Summary

| Table | Grain | Row count | Primary key | Unique? | Foreign keys in current scope | Share of `application_train` applicants represented |
|---|---|---:|---|---|---|---:|
| `application_train.csv` | One current loan application in the training sample | 307,511 | `SK_ID_CURR` | Yes — 307,511 distinct values, no nulls | None. `SK_ID_CURR` is the primary key, not a foreign key. | 100.0% (307,511 / 307,511) |
| `application_test.csv` | One current loan application in the test sample | 48,744 | `SK_ID_CURR` | Yes — 48,744 distinct values, no nulls | None. `SK_ID_CURR` is the primary key, not a foreign key. | 0.0% (0 / 307,511) |

`application_train` and `application_test` are disjoint partitions: there are **0 shared `SK_ID_CURR` values**. Therefore, there is no train-to-test foreign-key relationship or parent-child cardinality between these two tables.

## Dictionary contradictions

### `application_train.csv`

| Column | Finding | Why it contradicts the dictionary |
|---|---|---|
| `DAYS_EMPLOYED` | 55,374 rows contain `365243` | The dictionary defines the field as how many days **before the application** the person started current employment. A positive value of `365243` is inconsistent with that relative-time meaning and behaves as a sentinel value. |

No other direct contradictions were found against explicit dictionary encodings/ranges checked in this table, including binary flags, region ratings `(1,2,3)`, application hour, and other relative-day fields.

### `application_test.csv`

| Column | Finding | Why it contradicts the dictionary |
|---|---|---|
| `DAYS_EMPLOYED` | 9,274 rows contain `365243` | Same contradiction as in the training table: the dictionary describes a number of days before the application, so this positive sentinel is inconsistent with the stated meaning. |
| `REGION_RATING_CLIENT_W_CITY` | 1 row contains `-1` | The dictionary explicitly states that the allowed region ratings are `(1,2,3)`. |

No other direct contradictions were found against the same explicit dictionary checks.

## Key interpretation

Within this restricted two-table scope:

- `SK_ID_CURR` is the primary key of both application tables.
- There are no foreign keys between `application_train` and `application_test`.
- Their relationship is best described as **two disjoint samples of the same application-level entity**, not as a relational join.
