# Session Summary: Leak-Free Data Transformation (fit-on-train / apply-to-test)

## Date & Scope
- **Date:** Fri Oct 16 2026
- **Topic:** Move min-max normalization and z-score centering from the input-processing
  step to *after* the train/test split, so the transform is fit on the training set only
  and applied (not re-fit) to the test set and to prediction data.
- **Pipelines affected:** classification (2D + 3D connectivity) and regression (2D + 3D connectivity).

## The Problem (Before)

The min-max / z-score transform was applied in the input-processing scripts, **before** any
train/test split, using statistics computed over the **whole dataset**:

- `R_files/input_dat_process_2d.R`, `R_files/input_dat_process.R` (classification, 2D / 3D)
- `R_files/reg_input_dat_process_2d.R`, `R_files/reg_input_dat_process.R` (regression, 2D / 3D)

Because the train/test split only happens later (inside the ML scripts), the test / holdout
rows were normalized using min/max/mean values that **included the test rows themselves** ->
data leakage (inflated, non-reproducible performance).

The prediction path had a second, related bug: `pred_dat_process_2d.R` and `pred_dat_process.R`
**re-fit** min/max/mean on the new prediction batch instead of applying the transform fitted at
training time — both a new-source of leakage and inconsistent with the trained model.

## The Design Principle

> Fit the per-feature transform on **training data only**; apply the same fitted parameters to
> the test data and to prediction data. Never re-fit on data the model has not "seen" as training.

Per-feature (per-column) transforms compose cleanly, so the transform is applied to the full
training feature matrix, then the same parameters are applied to the test features before the
existing feature sub-selection.

## New Data Flow

```
                 INPUT
                    |
        input_dat_process*.R / reg_input_dat_process*.R
        (raw loader only - NO transform now)
                    |
        +----------+-----------+
        |                      |
  _2D.csv (RAW)     _data_processing_config.RData  (MINMAX_NORM / ZSCORE_STAND flags)
        |                      |
        |                      | (flags read here, option "b")
        v                      v
  univariate_*.R  --->  _w_prior.csv (RAW features, when -k used)
        |                      |
        v                      v
  ml_svm* / reg_ml_svm* / cv_ml_svm*
        |
        1. build training / test split   (unchanged)
        2. load_dat_process_config()     -> read flags from the config RData
        3. transform_train_test()        -> fit on training, apply to both
        4. model on transformed training, evaluate on transformed test
        5. sav(...) the model RData WITH dat_transform_param
                    |
                    v
        pred_dat_process*.R
        - load model RData (provides dat_transform_param)
        - apply_dat_transform(newdata, dat_transform_param)   (no re-fit)
                    |
                    v
        pred_classif.R -> predictions
```

The single source of truth for the fitted transform is the **model RData
(`*_final_svm_model.Rdata` / `*_final_svr_model.Rdata`)**, which now carries the object
`dat_transform_param`.

## Shared Helper — `R_files/dat_transform.R`

New file, self-contained, sourced (not `require`d) by every ML/CV/prediction script **before**
its `setwd(RES_OUT_DIR)` call (cwd is the repo root at that point, so the relative path
`R_files/dat_transform.R` resolves).

Four functions:

| Function | Role |
|----------|------|
| `fit_dat_transform(X, minmax, zscore)` | Computes per-feature min/max/mean from `X`, applies the transform, returns `list(transformed = X, param = ...)`. min-max is applied first, then z-score centering (`scale = FALSE`, i.e. mean subtraction only) — matching the original `center_scale(..., scale = FALSE)` semantics exactly. |
| `apply_dat_transform(X, param)` | Applies a previously fitted `param` to new `X`. Columns are matched **by name** against the fitted feature set; unknown columns pass through unchanged. |
| `transform_train_test(training, test, minmax, zscore)` | Orchestrator for split-aware scripts: fits on `training`, applies the same `param` to `training` and `test`. `sampleid`/`y` columns are preserved; only feature columns are transformed. |
| `load_dat_process_config(out_dir, file_no_ext)` | Reads `<file_no_ext>_data_processing_config.RData` and returns `list(minmax, zscore)` as logicals. Falls back to `FALSE/FALSE` if the file is missing. |

`dat_transform_param` (the `param` object) structure:
```
list(
  features = <vector of feature column names>,
  fmin     = <per-feature min>,
  fmax     = <per-feature max>,
  fmean    = <per-feature mean AFTER any min-max normalization; NA when zscore=FALSE>,
  minmax   = <logical>,
  zscore   = <logical>
)
```

## How Transformations Are Applied — by script kind

### 1. Input-processing scripts (4) — transform REMOVED
`input_dat_process.R`, `input_dat_process_2d.R`, `reg_input_dat_process.R`,
`reg_input_dat_process_2d.R`
- Deleted the `if (MINMAX_NORM) ...` / `if (ZSCORE_STAND) center_scale(...)` blocks.
- Still emit a **raw** `_2D.csv` and the `_data_processing_config.RData` (which carries the
  flags). Univariate / `_w_prior.csv` consequently runs on raw data.

### 2. Regular ML scripts (4) — fit-on-train / apply-to-test
`ml_svm.R`, `ml_svm_nofs.R`, `reg_ml_svm.R`, `reg_ml_svm_nofs.R`
- After the existing train/test split:
  ```r
  tr  <- load_dat_process_config(RES_OUT_DIR, <MAT_FILE_NO_EXT>)
  tt  <- transform_train_test(training, test, minmax = tr$minmax, zscore = tr$zscore)
  training <- tt$train; test <- tt$test
  dat_transform_param <- tt$param
  ```
- `ml_dfm` (used for PCA / hcluster / `_dl.csv`) is re-applied with the same `param` so
  downstream visualizations and exports remain consistent with the trained model.
- `dat_transform_param` is added to the final `save(...)` so predictions can reuse it.
- Classification scripts read the flag via `CONFIG_LIST$MAT_FILE_NO_EXT`; regression scripts
  use the bare `MAT_FILE_NO_EXT` variable (regression config uses bare variables, not
  `CONFIG_LIST`).

### 3. CV-only scripts (4) — global fit (behavior preserved)
`cv_ml_svm.R`, `cv_ml_svm_nofs.R`, `cv_reg_ml_svm.R`, `cv_reg_ml_svm_nofs.R`
- CV-only mode has **no** external train/test split (the whole dataset is cross-validated
  internally by the RBioFS/CV machinery). To keep CV results **identical** to before, these
  scripts re-apply the **global** transform (fit on the whole `ml_dfm`, applied to the whole
  `ml_dfm`) via `fit_dat_transform`, and persist `dat_transform_param`.
- Rationale: a global fit here reproduces the original pre-change global transform exactly, so
  existing CV numbers do not shift, while still giving the prediction path a transform param.

### 4. Prediction scripts (2) — apply, never re-fit
`pred_dat_process.R`, `pred_dat_process_2d.R`
- Removed the re-fit blocks (`apply(... min/max ...)` and `center_scale(...)`).
- Replaced with:
  ```r
  if (exists("dat_transform_param") && !is.null(dat_transform_param)) {
    feat_cols_p <- setdiff(names(raw_sample_dfm), "sampleid")
    raw_sample_dfm[, feat_cols_p] <-
      apply_dat_transform(raw_sample_dfm[, feat_cols_p, drop = FALSE], dat_transform_param)
  }
  ```
- `dat_transform_param` is available because `load(MODEL_FILE)` is already called at the top
  of both prediction scripts and the model RData now contains it.

## Verification

- **Parse check:** all 15 touched/new R files parse cleanly under `Rscript -e 'parse(...)'`
  (R 4.6.1).
- **Unit tests (synthetic data), `dat_transform.R`:**
  - `fit`-on-train + `apply`-to-train == direct transform, for all 3 active flag combos
    (mm+zs, mm only, zs only) — max abs diff `0.0` (exact).
  - Training-fit parameters differ from global-fit parameters — confirms the leak is real and
    that the new path removes it.
  - `load_dat_process_config` correctly reads the flags from the RData and returns `FALSE/FALSE`
    for a missing file.
- **End-to-end smoke test (synthetic 12-sample, 2-class, 3-feature dataset):**
  - Input script produces raw `_2D.csv` + config RData.
  - ML-stage `transform_train_test` produces a `dat_transform_param` persisted to the model RData.
  - `apply_dat_transform` on new prediction data uses the training-fit params (no re-fit).
- **Invariants (grep across all edited files):**
  - No `center_scale(feature_dat` / `apply(feature_dat, 2, ...)` min-max/zscore block remains in
    the 4 input-processing scripts.
  - `source("R_files/dat_transform.R")` present in all 10 downstream scripts (8 ML/CV + 2 pred).
  - `dat_transform_param` is saved in all 8 model-producing scripts.

## Scope Notes / Known Limitations

- **PLS-DA / PLS-R validation scripts** (`plsda_val_svm.R`, `reg_plsr_val_svm.R`, and their
  `cv_*` twins) were **not** changed. They only center `svm_m$inputX` (already-transformed
  training data inside the SVM model) and never touch the holdout test set — no new leak there.
- **`-k` / `_w_prior.csv` univariate reduction** still runs on the whole dataset before the split.
  This is a pre-existing source of leakage (the univariate/DE step uses all samples to select
  features). It is out of scope for this change; a code comment flags it. Fully removing it
  would require the univariate step to also respect the train/test split.
- **Residual nested-CV leakage (pre-existing):** the global pre-transform fitted on the whole
  training set is still visible inside the RBioFS nested-CV / `rbioClass_svm_cv` calls. This is
  the same class of issue as CV-only mode and was intentionally left (consistent with the
  "leave CV-only as-is" decision).
- **No full integration test** on a real run was executed (heavy; needs `RBioFS`, `edgeR`,
  `limma`, `RBioArray`). A real `bash train_class.sh ...` + `bash predict_class.sh ...` end-to-
  end run on the user's sample data would confirm the RData round-trip in production; not run here.

## Files Changed

| File | Change |
|------|--------|
| `R_files/dat_transform.R` | **New** — 4 helper functions |
| `R_files/input_dat_process.R` | Remove min-max/z-score transform |
| `R_files/input_dat_process_2d.R` | Remove min-max/z-score transform |
| `R_files/reg_input_dat_process.R` | Remove min-max/z-score transform |
| `R_files/reg_input_dat_process_2d.R` | Remove min-max/z-score transform |
| `R_files/ml_svm.R` | Source helper; fit-on-train/apply-to-test; persist `dat_transform_param` |
| `R_files/ml_svm_nofs.R` | Source helper; fit-on-train/apply-to-test; persist `dat_transform_param` |
| `R_files/reg_ml_svm.R` | Source helper; fit-on-train/apply-to-test; persist `dat_transform_param` |
| `R_files/reg_ml_svm_nofs.R` | Source helper; fit-on-train/apply-to-test; persist `dat_transform_param` |
| `R_files/cv_ml_svm.R` | Source helper; global fit (preserve CV numbers); persist `dat_transform_param` |
| `R_files/cv_ml_svm_nofs.R` | Source helper; global fit (preserve CV numbers); persist `dat_transform_param` |
| `R_files/cv_reg_ml_svm.R` | Source helper; global fit (preserve CV numbers); persist `dat_transform_param` |
| `R_files/cv_reg_ml_svm_nofs.R` | Source helper; global fit (preserve CV numbers); persist `dat_transform_param` |
| `R_files/pred_dat_process.R` | Apply `dat_transform_param` from model (no re-fit) |
| `R_files/pred_dat_process_2d.R` | Apply `dat_transform_param` from model (no re-fit) |

**Total: 1 new file + 14 edited files. +205 / −47 lines (per `git diff --stat`).**
