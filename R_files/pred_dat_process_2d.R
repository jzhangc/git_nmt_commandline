# ------ general info ------
## name: pred_dat_process_2d.R
## purpose: load and process 2d file for prediction

## flags from Rscript
args <- commandArgs(trailingOnly = TRUE)
# print(args)

# ------ load libraries ------
require(foreach)
require(RBioFS)

# ------sys variables --------
# --- file name variables ---
CSV_2D_FILE <- args[1]
CSV_2D_FILE_NO_EXT <- args[2]

# --- mata data input variables ---
SAMPLEID_VAR <- args[3]

# --- directory variables ---
# FIG_OUT_DIR
RES_OUT_DIR <- args[4]

# --- other config variables ---
MODEL_FILE <- args[5]
load(MODEL_FILE)
MINMAX_NORM <- DAT_PROCESS_CONFIG$MINMAX_NORM
ZSCORE_STAND <- DAT_PROCESS_CONFIG$ZSCORE_STAND

# ------ load leak-free data transformation helpers ------
# cwd is the repo root before setwd below, so the relative path resolves
source("R_files/dat_transform.R")

# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR)  # the folder that all the results will be exports to

# ------ load 2d file ------
raw_csv <- read.csv(file = CSV_2D_FILE, stringsAsFactors = FALSE, check.names = FALSE)

# ------ load annotation file (meta data) ------
if (! SAMPLEID_VAR %in% names(raw_csv)) {
  cat("none_existent")
  quit()
}
nsamples <- nrow(raw_csv)
sampleid <- raw_csv[, SAMPLEID_VAR]

# ------ process 2d file ------
raw_sample_dfm <- data.frame(sampleid = sampleid, raw_csv[, !names(raw_csv) %in% SAMPLEID_VAR, drop = FALSE], 
                             row.names = NULL, check.names = FALSE)

# no need to remove any columns even if for those who have same values
# raw_sample_dfm[, -c(1:2)] <- raw_sample_dfm[, -c(1:2)][vapply(raw_sample_dfm[, -c(1:2)], function(x) length(unique(x)) > 1, logical(1L))] # remove columns with only the same value
# apply the transform FIT ON THE TRAINING SET (dat_transform_param, loaded from the
# model) instead of re-fitting on the new batch: re-fitting would (a) leak
# new-batch statistics into the model and (b) be inconsistent with the trained
# model. apply_dat_transform matches columns by name, so only known features are
# transformed; the sampleid column is left untouched.
if (exists("dat_transform_param") && !is.null(dat_transform_param)) {
  feat_cols_p <- setdiff(names(raw_sample_dfm), "sampleid")
  if (length(feat_cols_p) > 0) {
    raw_sample_dfm[, feat_cols_p] <- apply_dat_transform(raw_sample_dfm[, feat_cols_p, drop = FALSE], dat_transform_param)
  }
}

# ------ export and clean up the mess --------
## export to results files if needed
write.csv(file = paste0(RES_OUT_DIR, "/", CSV_2D_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm, row.names = FALSE)

# ------ display messages so far ------
# cat the variables to export to shell script
cat("\tSamples to predict: ", nsamples, "\n") # line 1: input mat file dimension