# ROC-AUC treats TARGET = 1 as the event; accuracy is available for the baseline.
payment_roc_auc <- yardstick::metric_tweak(
  "roc_auc",
  yardstick::roc_auc,
  event_level = "first"
)

classification_metrics <- yardstick::metric_set(
  payment_roc_auc,
  yardstick::accuracy
)


# Features added by the preparation pipeline are held out of the first benchmark.
engineered_features <- c(
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


# Build a model workflow with the shared preprocessing steps.
build_model_workflow <- function(
  data,
  predictors,
  model_spec,
  downsample = FALSE
) {
  model_recipe <- recipes::recipe(
    stats::reformulate(predictors, response = "TARGET"),
    data = data
  ) |>
    recipes::step_unknown(
      recipes::all_nominal_predictors(),
      new_level = "Missing"
    ) |>
    recipes::step_novel(
      recipes::all_nominal_predictors(),
      new_level = "Novel"
    ) |>
    recipes::step_impute_median(recipes::all_numeric_predictors()) |>
    recipes::step_dummy(
      recipes::all_nominal_predictors(),
      sparse = "yes"
    ) |>
    recipes::step_zv(recipes::all_predictors())

  if (downsample) {
    # Balance only the rows used to fit each resampled model.
    model_recipe <- model_recipe |>
      themis::step_downsample(
        TARGET,
        under_ratio = 1,
        skip = TRUE,
        seed = 6812
      )
  }

  workflows::workflow() |>
    workflows::add_recipe(
      model_recipe,
      blueprint = hardhat::default_recipe_blueprint(
        composition = "dgCMatrix"
      )
    ) |>
    workflows::add_model(model_spec)
}
