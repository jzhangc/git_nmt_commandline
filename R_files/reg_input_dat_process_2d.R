# ------ general info ------
## name: reg_input_dat_process_2d.R
## purpose: load and process 2d data file for regression

## flags from Rscript
args <- commandArgs()
# print(args)

# ------ load libraries ------
require(foreach)

# ------ sys variables ------
# --- file name variables ---
CSV_2D_FILE <- args[6]
CSV_2D_FILE_NO_EXT <- args[7]
# ANNOT_FILE <- args[8]


# --- directory variables ---
# FIG_OUT_DIR
RES_OUT_DIR <- args[10]

# --- mata data input variables ---
SAMPLEID_VAR <- args[8]
Y_VAR <- args[9]

# ------ load 2d file ------
raw_csv <- read.csv(file = CSV_2D_FILE, stringsAsFactors = FALSE, check.names = FALSE)
if (!all(c(SAMPLEID_VAR, Y_VAR) %in% names(raw_csv))) {
  cat("none_existent")
  quit()
}
if (length(which(!complete.cases(raw_csv))) > 0) {
  cat("na_values")
  quit()
}
y <- raw_csv[, Y_VAR]
sampleid <- raw_csv[, SAMPLEID_VAR]

# ------ process the mat file with the mata data ------
raw_sample_dfm <- data.frame(sampleid = sampleid, y = y, raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, Y_VAR)], row.names = NULL)
names(raw_sample_dfm)[-c(1:2)] <- names(raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, Y_VAR)])

raw_sample_dfm[, -c(1:2)] <- raw_sample_dfm[, -c(1:2)][vapply(raw_sample_dfm[, -c(1:2)], function(x) length(unique(x)) > 1, logical(1L))] # remove columns with only the same value
raw_sample_dfm[, -c(1:2)] <- apply(raw_sample_dfm[, -c(1:2)], 2, FUN = function(x)(x-min(x))/(max(x)-min(x)))
raw_sample_dfm[, -c(1:2)] <- center_scale(raw_sample_dfm[, -c(1:2)], scale = FALSE)$centerX

# below: no need as regression data doesn't have a "group" variable
# raw_sample_dfm_wo_uni <- data.frame(y = y, raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, GROUP_VAR)], row.names = NULL)
# names(raw_sample_dfm_wo_uni)[-1] <- names(raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, GROUP_VAR)])

####### export and clean up the mess --------
## export to results files if needed
write.csv(file = paste0(RES_OUT_DIR, "/", CSV_2D_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm, row.names = FALSE)
# write.csv(file = paste0(RES_OUT_DIR, "/", CSV_2D_FILE_NO_EXT, "_2D_wo_uni.csv"), raw_sample_dfm_wo_uni, row.names = FALSE)
