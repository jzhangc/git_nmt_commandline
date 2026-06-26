# ------ general info ------
## name: reg_input_dat_process_2d.R
## purpose: load and process 2d data file for regression

## flags from Rscript
args <- commandArgs()
# print(args)

# ------ load libraries ------
require(foreach)
require(RBioFS)

# ------ sys variables ------
# --- file name variables ---
CSV_2D_FILE <- args[6]

# --- directory variables ---
# FIG_OUT_DIR
RES_OUT_DIR <- args[10]

# ------ config list ------
DAT_PROCESS_CONFIG <- list(
  CSV_2D_FILE_NO_EXT = args[7],
  SAMPLEID_VAR = args[8],
  Y_VAR = args[9],
  MINMAX_NORM = eval(parse(text = args[11])),
  ZSCORE_STAND = eval(parse(text = args[12]))
)

# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR) # the folder that all the results will be exports to

# ------ load 2d file ------
raw_csv <- read.csv(file = CSV_2D_FILE, stringsAsFactors = FALSE, check.names = FALSE)
raw_dim <- dim(raw_csv)

if (!all(c(DAT_PROCESS_CONFIG$SAMPLEID_VAR, DAT_PROCESS_CONFIG$Y_VAR) %in% names(raw_csv))) {
  cat("none_existent")
  quit()
}
if (length(which(!complete.cases(raw_csv))) > 0) {
  cat("na_values")
  quit()
}
if (length(unique(raw_csv[, DAT_PROCESS_CONFIG$Y_VAR])) == 1) {
  cat("single_value")
  quit()
}

y <- raw_csv[, DAT_PROCESS_CONFIG$Y_VAR]
sampleid <- raw_csv[, DAT_PROCESS_CONFIG$SAMPLEID_VAR]

# ------ process the mat file with the mata data ------
raw_sample_dfm <- data.frame(sampleid = sampleid, y = y, raw_csv[, !names(raw_csv) %in% c(DAT_PROCESS_CONFIG$SAMPLEID_VAR, DAT_PROCESS_CONFIG$Y_VAR)], row.names = NULL)
names(raw_sample_dfm)[-c(1:2)] <- names(raw_csv[, !names(raw_csv) %in% c(DAT_PROCESS_CONFIG$SAMPLEID_VAR, DAT_PROCESS_CONFIG$Y_VAR)])
feature_dat <- raw_sample_dfm[, -c(1:2)]
id_dat <- raw_sample_dfm[, c(1:2)]

# -- remove columns with only the same value --
drop_cols <- names(feature_dat)[which(!vapply(feature_dat, function(x) length(unique(x)) > 1, logical(1L)))]
feature_dat <- feature_dat[, !names(feature_dat) %in% drop_cols, drop = FALSE]
# raw_sample_dfm[, -c(1:2)] <- raw_sample_dfm[, -c(1:2)][vapply(raw_sample_dfm[, -c(1:2)], function(x) length(unique(x)) > 1, logical(1L))] # remove columns with only the same value

# -- data transformation --
if (DAT_PROCESS_CONFIG$MINMAX_NORM) {
  feature_dat <- apply(feature_dat, 2, FUN = function(x)(x-min(x))/(max(x)-min(x)))
}

if (DAT_PROCESS_CONFIG$ZSCORE_STAND) {
  feature_dat <- center_scale(feature_dat, scale = FALSE)$centerX
}

# -- data output --
raw_sample_dfm_output <- cbind(id_dat, feature_dat)

# ------ export and clean up the mess --------
## export to results files if needed
write.csv(file = paste0(DAT_PROCESS_CONFIG$CSV_2D_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm_output, row.names = FALSE)
save(DAT_PROCESS_CONFIG, file = paste0(DAT_PROCESS_CONFIG$CSV_2D_FILE_NO_EXT, "_data_processing_config.RData"))

## cat the vairables to export to shell scipt
cat("\tInput file dimensions (w annot vars): ", raw_dim, "\n") # line 1: input dat file dimension
