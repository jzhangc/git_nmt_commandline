# ------ general info ------
## name: dat_transform.R
## purpose: leak-free data transformation helpers.
## Fit the transform (min-max normalization and/or z-score centering) on the
## training set only, then apply the SAME fitted parameters to the test set and to
## new data at prediction time. This prevents test/prediction statistics from
## leaking into the model.

# fit_dat_transform: compute per-feature transform parameters from X and return the
# transformed X together with the fitted parameters.
# X: numeric data frame, rows = samples, cols = features
# minmax: logical, apply per-feature min-max normalization first
# zscore: logical, apply per-feature centering (mean subtraction, scale = FALSE)
#          on the (optionally min-max) normalized data
fit_dat_transform <- function(X, minmax = FALSE, zscore = FALSE) {
  X <- as.data.frame(X)
  feat_names <- names(X)
  fmin <- apply(X, 2, min)
  fmax <- apply(X, 2, max)
  Xout <- as.matrix(X)
  if (isTRUE(minmax)) {
    for (j in seq_along(feat_names)) {
      Xout[, j] <- (Xout[, j] - fmin[j]) / (fmax[j] - fmin[j])
    }
  }
  fmean <- rep(NA_real_, length(feat_names))
  if (isTRUE(zscore)) {
    fmean <- colMeans(Xout)
    for (j in seq_along(feat_names)) {
      Xout[, j] <- Xout[, j] - fmean[j]
    }
  }
  out <- data.frame(Xout, row.names = NULL, check.names = FALSE)
  names(out) <- feat_names
  param <- list(
    features = feat_names,
    fmin = fmin,
    fmax = fmax,
    fmean = fmean,
    minmax = isTRUE(minmax),
    zscore = isTRUE(zscore)
  )
  return(list(transformed = out, param = param))
}

# apply_dat_transform: apply previously fitted parameters to new data X.
# Columns are matched by NAME against the fitted feature set. Columns present in X
# but absent from the fitted set are returned unchanged (used at prediction time).
apply_dat_transform <- function(X, param) {
  X <- as.data.frame(X)
  feat_names <- names(X)
  Xout <- as.matrix(X)
  for (fn in param$features) {
    if (fn %in% feat_names) {
      col <- Xout[, fn]
      if (param$minmax) {
        Xout[, fn] <- (col - param$fmin[fn]) / (param$fmax[fn] - param$fmin[fn])
      }
      if (param$zscore) {
        Xout[, fn] <- Xout[, fn] - param$fmean[fn]
      }
    }
  }
  out <- data.frame(Xout, row.names = NULL, check.names = FALSE)
  names(out) <- feat_names
  return(out)
}

# transform_train_test: fit the transform on the training feature columns only,
# then apply the SAME fitted parameters to the test feature columns. This is the
# core leak-free split-aware transform.
# training/test: data.frames that may include the "sampleid" and "y" columns, which
#                are preserved (only feature columns are transformed).
# minmax/zscore: logical flags (read from the data processing config).
# returns list(train = transformed training df, test = transformed test df,
#              param = fitted parameters). test may be NULL (CV-only mode).
transform_train_test <- function(training, test = NULL, minmax = FALSE, zscore = FALSE) {
  feat_cols <- setdiff(names(training), c("sampleid", "y"))
  param <- NULL
  if (length(feat_cols) > 0) {
    fit <- fit_dat_transform(training[, feat_cols, drop = FALSE], minmax = minmax, zscore = zscore)
    training[, feat_cols] <- fit$transformed
    param <- fit$param
    if (!is.null(test) && length(feat_cols) > 0) {
      te_cols <- intersect(feat_cols, names(test))
      if (length(te_cols) > 0) {
        test[, te_cols] <- apply_dat_transform(test[, te_cols, drop = FALSE], param)
      }
    }
  }
  return(list(train = training, test = test, param = param))
}

# load_dat_process_config: read the data processing config RData produced by the
# input-processing step and return the minmax / zscore flags as logicals.
# Falls back to list(minmax = FALSE, zscore = FALSE) if the file is missing.
load_dat_process_config <- function(out_dir, file_no_ext) {
  path <- paste0(out_dir, "/", file_no_ext, "_data_processing_config.RData")
  minmax <- FALSE
  zscore <- FALSE
  if (file.exists(path)) {
    suppressMessages(try(load(file = path), silent = TRUE))
    if (exists("DAT_PROCESS_CONFIG")) {
      minmax <- isTRUE(DAT_PROCESS_CONFIG$MINMAX_NORM)
      zscore <- isTRUE(DAT_PROCESS_CONFIG$ZSCORE_STAND)
    }
  }
  return(list(minmax = minmax, zscore = zscore))
}
