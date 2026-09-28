# Week 5 Data Preparation and Feature Engineering
# Run this script from the repository root with:
# Rscript scripts/01_data_preparation.R

# Purpose: Read the two application-level datasets used in the approved EDA.
# Inputs: Paths to the raw training and test CSV files.
# Output: A list containing the unmodified train and test data frames.

read_application_data <- function(
    train_path = "data/raw/application_train.csv",
    test_path = "data/raw/application_test.csv") {
  train <- read.csv(train_path, stringsAsFactors = FALSE)
  test <- read.csv(test_path, stringsAsFactors = FALSE)

  list(train = train, test = test)
}


# Purpose: Confirm that train and test have the expected application schemas.
# Inputs: Raw training and test data frames.
# Output: Printed check results; stops if a schema check fails.

validate_application_schema <- function(train, test) {
  schema_checks <- data.frame(
    check = c(
      "TARGET exists in train",
      "TARGET does not exist in test",
      "Predictor names and order match"
    ),
    passed = c(
      "TARGET" %in% names(train),
      !"TARGET" %in% names(test),
      identical(names(train)[names(train) != "TARGET"], names(test))
    )
  )

  print(schema_checks, row.names = FALSE)

  if (!all(schema_checks$passed)) {
    stop("Application schema validation failed.")
  }

  invisible(schema_checks)
}


# Purpose: Confirm that each dataset still has one row per application key.
# Inputs: Training and test data frames.
# Output: Printed key-check results; stops if a key check fails.
validate_application_keys <- function(train, test) {
  train_has_key <- "SK_ID_CURR" %in% names(train)
  test_has_key <- "SK_ID_CURR" %in% names(test)

  key_checks <- data.frame(
    check = c(
      "SK_ID_CURR exists in train",
      "SK_ID_CURR exists in test",
      "No missing train SK_ID_CURR values",
      "No missing test SK_ID_CURR values",
      "Train SK_ID_CURR is unique",
      "Test SK_ID_CURR is unique"
    ),
    passed = c(
      train_has_key,
      test_has_key,
      train_has_key && !any(is.na(train$SK_ID_CURR)),
      test_has_key && !any(is.na(test$SK_ID_CURR)),
      train_has_key && !anyDuplicated(train$SK_ID_CURR),
      test_has_key && !anyDuplicated(test$SK_ID_CURR)
    )
  )

  print(key_checks, row.names = FALSE)

  if (!all(key_checks$passed)) {
    stop("Application key validation failed.")
  }

  invisible(key_checks)
}


# Purpose: Clean only the invalid codes documented in the EDA.
# Inputs: One application data frame.
# Output: The same rows and columns, with documented invalid codes set to NA.

clean_documented_invalid_codes <- function(data) {
  # EDA decision: DAYS_EMPLOYED = 365243 is an invalid sentinel, so convert it to missing.
  data$DAYS_EMPLOYED[data$DAYS_EMPLOYED == 365243] <- NA

  # EDA decision: -1 is outside the documented region-rating range, so convert it to missing.
  data$REGION_RATING_CLIENT_W_CITY[
    data$REGION_RATING_CLIENT_W_CITY == -1
  ] <- NA

  # EDA decision: CODE_GENDER = "XNA" is undocumented, so convert it to missing.
  data$CODE_GENDER[data$CODE_GENDER == "XNA"] <- NA

  data
}


# Purpose: Create the two interpretable time features approved by the EDA.
# Inputs: One cleaned application data frame.
# Output: The data frame with age_years and tenure_years added.

derive_time_features <- function(data) {
  # EDA decision: age and employment duration are stored as negative relative days;
  # convert them to positive years.
  data$age_years <- -data$DAYS_BIRTH / 365.25
  data$tenure_years <- -data$DAYS_EMPLOYED / 365.25

  data
}


# Purpose: Create the three proposed-loan burden ratios analyzed in the EDA.
# Inputs: One application data frame containing the original amount columns.
# Output: The data frame with three burden-ratio features added.

derive_proposed_loan_burden_features <- function(data) {
  valid_income <- !is.na(data$AMT_INCOME_TOTAL) & data$AMT_INCOME_TOTAL > 0

  # EDA decision: retain proposed-loan burden relative to reported income as candidate features.
  data$annuity_income <- ifelse(
    valid_income,
    data$AMT_ANNUITY / data$AMT_INCOME_TOTAL,
    NA_real_
  )
  data$credit_income <- ifelse(
    valid_income,
    data$AMT_CREDIT / data$AMT_INCOME_TOTAL,
    NA_real_
  )
  data$goods_income <- ifelse(
    valid_income,
    data$AMT_GOODS_PRICE / data$AMT_INCOME_TOTAL,
    NA_real_
  )

  # EDA decision: invalid or undefined ratios should remain missing, not be imputed.
  data$annuity_income[!is.finite(data$annuity_income)] <- NA
  data$credit_income[!is.finite(data$credit_income)] <- NA
  data$goods_income[!is.finite(data$goods_income)] <- NA

  data
}


# Purpose: Preserve the informative missingness identified in the EDA.
# Inputs: One application data frame.
# Output: The data frame with nine approved binary missingness indicators added.

add_missingness_indicators <- function(data) {
  # EDA decision: missingness in external scores and bureau inquiry fields may
  # carry information, so preserve it with indicators.
  data$EXT_SOURCE_1_missing <- as.integer(is.na(data$EXT_SOURCE_1))
  data$EXT_SOURCE_2_missing <- as.integer(is.na(data$EXT_SOURCE_2))
  data$EXT_SOURCE_3_missing <- as.integer(is.na(data$EXT_SOURCE_3))
  data$AMT_REQ_CREDIT_BUREAU_HOUR_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_HOUR)
  )
  data$AMT_REQ_CREDIT_BUREAU_DAY_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_DAY)
  )
  data$AMT_REQ_CREDIT_BUREAU_WEEK_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_WEEK)
  )
  data$AMT_REQ_CREDIT_BUREAU_MON_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_MON)
  )
  data$AMT_REQ_CREDIT_BUREAU_QRT_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_QRT)
  )
  data$AMT_REQ_CREDIT_BUREAU_YEAR_missing <- as.integer(
    is.na(data$AMT_REQ_CREDIT_BUREAU_YEAR)
  )

  data
}


# Purpose: Learn training-based annuity-to-income quintile thresholds
# that preserve the five-group analysis used in the EDA.
# Inputs: Prepared training data containing annuity_income.
# Output: A simple list containing training-derived breaks, labels, and feature name.

fit_binning_spec <- function(train) {
  valid_annuity_income <- train$annuity_income[
    !is.na(train$annuity_income) & is.finite(train$annuity_income)
  ]

# EDA decision: annuity_income was analyzed in five groups.
# Learn fixed quintile thresholds from training data so the same
# group definition can be reused on test data.
  
  internal_thresholds <- quantile(
    valid_annuity_income,
    probs = c(0.20, 0.40, 0.60, 0.80),
    names = FALSE,
    type = 1
  )

  list(
    feature_name = "annuity_income_quintile",
    breaks = c(-Inf, internal_thresholds, Inf),
    labels = c("Q1", "Q2", "Q3", "Q4", "Q5")
  )
}


# Purpose: Apply the stored training quintile thresholds to one dataset.
# Inputs: One prepared data frame and the object returned by fit_binning_spec().
# Output: The data frame with the single approved binned feature added.

apply_binning_spec <- function(data, binning_spec) {
  # EDA decision: use the same annuity-income quintile definition in train and test.
  data[[binning_spec$feature_name]] <- cut(
    data$annuity_income,
    breaks = binning_spec$breaks,
    labels = binning_spec$labels,
    include.lowest = TRUE
  )

  data
}


# Purpose: Confirm that preparation preserved rows, keys, and train/test structure.
# Inputs: Prepared train/test data and the original raw row counts.
# Output: Printed validation results; stops if any structural check fails.

validate_prepared_data <- function(
    train, test, raw_train_row_count, raw_test_row_count) {
  expected_features <- c(
    "age_years",
    "tenure_years",
    "annuity_income",
    "credit_income",
    "goods_income",
    "EXT_SOURCE_1_missing",
    "EXT_SOURCE_2_missing",
    "EXT_SOURCE_3_missing",
    "AMT_REQ_CREDIT_BUREAU_HOUR_missing",
    "AMT_REQ_CREDIT_BUREAU_DAY_missing",
    "AMT_REQ_CREDIT_BUREAU_WEEK_missing",
    "AMT_REQ_CREDIT_BUREAU_MON_missing",
    "AMT_REQ_CREDIT_BUREAU_QRT_missing",
    "AMT_REQ_CREDIT_BUREAU_YEAR_missing",
    "annuity_income_quintile"
  )

  train_predictors <- names(train)[names(train) != "TARGET"]

  validation_results <- data.frame(
    check = c(
      "Train and test predictor names and order match",
      "TARGET exists only in train",
      "SK_ID_CURR remains in train and test",
      "Train SK_ID_CURR remains unique",
      "Test SK_ID_CURR remains unique",
      "Train row count is unchanged",
      "Test row count is unchanged",
      "All approved engineered features exist in train",
      "All approved engineered features exist in test"
    ),
    passed = c(
      identical(train_predictors, names(test)),
      "TARGET" %in% names(train) && !"TARGET" %in% names(test),
      "SK_ID_CURR" %in% names(train) && "SK_ID_CURR" %in% names(test),
      !anyDuplicated(train$SK_ID_CURR),
      !anyDuplicated(test$SK_ID_CURR),
      nrow(train) == raw_train_row_count,
      nrow(test) == raw_test_row_count,
      all(expected_features %in% names(train)),
      all(expected_features %in% names(test))
    )
  )

  print(validation_results, row.names = FALSE)

  if (!all(validation_results$passed)) {
    stop("Prepared-data validation failed.")
  }

  invisible(validation_results)
}


# Read and validate the two raw application datasets.
application_data <- read_application_data()
raw_train <- application_data$train
raw_test <- application_data$test

cat("Raw application schema validation:\n")
validate_application_schema(raw_train, raw_test)

cat("\nRaw application key validation:\n")
validate_application_keys(raw_train, raw_test)

raw_train_row_count <- nrow(raw_train)
raw_test_row_count <- nrow(raw_test)

# Apply the same approved deterministic transformations to train and test.
prepared_train <- clean_documented_invalid_codes(raw_train)
prepared_test <- clean_documented_invalid_codes(raw_test)

prepared_train <- derive_time_features(prepared_train)
prepared_test <- derive_time_features(prepared_test)

prepared_train <- derive_proposed_loan_burden_features(prepared_train)
prepared_test <- derive_proposed_loan_burden_features(prepared_test)

prepared_train <- add_missingness_indicators(prepared_train)
prepared_test <- add_missingness_indicators(prepared_test)

# Fit the one approved bin specification on train and reuse it unchanged on test.
binning_spec <- fit_binning_spec(prepared_train)
prepared_train <- apply_binning_spec(prepared_train, binning_spec)
prepared_test <- apply_binning_spec(prepared_test, binning_spec)

cat("\nPrepared-data validation:\n")
validate_prepared_data(
  prepared_train,
  prepared_test,
  raw_train_row_count,
  raw_test_row_count
)

# Write the locally useful outputs. The processed CSV files are ignored by Git.
write.csv(
  prepared_train,
  "data/processed/application_train_prepared.csv",
  row.names = FALSE,
  na = "NA"
)
write.csv(
  prepared_test,
  "data/processed/application_test_prepared.csv",
  row.names = FALSE,
  na = "NA"
)

cat("\nTraining-derived annuity_income quintile thresholds:\n")
print(binning_spec$breaks[is.finite(binning_spec$breaks)])

cat("\nDataset dimensions (rows x columns):\n")
cat("Raw train:     ", nrow(raw_train), "x", ncol(raw_train), "\n")
cat("Raw test:      ", nrow(raw_test), "x", ncol(raw_test), "\n")
cat("Prepared train:", nrow(prepared_train), "x", ncol(prepared_train), "\n")
cat("Prepared test: ", nrow(prepared_test), "x", ncol(prepared_test), "\n")
