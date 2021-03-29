###### general info --------
## name: pred_dat_process_2d.R
## purpose: load and process 2d file for prediction
## version: 0.3.0

## flags from Rscript
args <- commandArgs(trailingOnly = TRUE)
# print(args)


###### load libraries --------
require(foreach)
require(R.matlab) # to read .mat files

###### sys variables --------
# --- file name variables ---
CSV_2D_FILE <- args[1]
CSV_2D_FILE_NO_EXT <- args[2]

# --- mata data input variables ---
SAMPLEID_VAR <- args[3]

# --- directory variables ---
# FIG_OUT_DIR
RES_OUT_DIR <- args[4]

###### R script --------
# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR)  # the folder that all the results will be exports to

# ------ load mat file ------
# setwd("/Users/jingzhang/Documents/git_repo/git_meg_ml_app/data/")
# MAT_FILE <- "/Users/jingzhang/Documents/git_repo/git_meg_ml_app/data/freq_3_alpha.ptsd_mtbi_aec_v2.mat"
raw_csv <- read.csv(file = CSV_2D_FILE, stringsAsFactors = FALSE, check.names = FALSE)


# ------ load annotation file (meta data) ------
if (! SAMPLEID_VAR %in% names(raw_csv)) {
  cat("none_existent")
  quit()
}
nsamples <- nrow(raw_csv)
sampleid <- raw_csv[, SAMPLEID_VAR]

# ------ process the mat file ------
raw_sample_dfm <- data.frame(sampleid = sampleid, raw_csv[, !names(raw_csv) %in% SAMPLEID_VAR], 
                             row.names = NULL, check.names = FALSE)

# ------ export and clean up the mess --------
## export to results files if needed
write.csv(file = paste0(RES_OUT_DIR, "/", CSV_2D_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm, row.names = FALSE)

# ------ display messages so far ------
# cat the variables to export to shell script
cat("\tSamples to predict: ", nsamples, "\n") # line 2: input mat file dimension