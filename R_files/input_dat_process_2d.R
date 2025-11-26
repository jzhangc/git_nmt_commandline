# ------ general info ------
## name: mat_process.R
## purpose: load and process mat files

## flags from Rscript
args <- commandArgs()
# print(args)

# ------ load libraries ------
require(foreach)
require(RBioFS)
require(R.matlab) # to read .mat files

# ------ sys variables --------
# --- file name variables ---
CSV_2D_FILE <- args[6]
CSV_2D_FILE_NO_EXT <- args[7]

# --- directory variables ---
# FIG_OUT_DIR
RES_OUT_DIR <- args[10]

# -- mata data input variables --
SAMPLEID_VAR <- args[8]
GROUP_VAR <- args[9]
MINMAX_NORM <- args[11]
ZSCORE_STAND <- args[12]
CONTRAST <- args[13]

# ------ load file ------
# --- load data ---
raw_csv <- read.csv(file = CSV_2D_FILE, stringsAsFactors = FALSE, check.names = FALSE)
raw_dim <- dim(raw_csv)

if (!all(c(SAMPLEID_VAR, GROUP_VAR) %in% names(raw_csv))) {
  cat("none_existent")
  quit()
}
if (length(which(!complete.cases(raw_csv))) > 0) {
  cat("na_values")
  quit()
}
if (length(unique(raw_csv[, GROUP_VAR])) == 1) {
  cat("single_value")
  quit()
}
sample_group <- factor(raw_csv[, GROUP_VAR], levels = unique(raw_csv[, GROUP_VAR]))
sample_group_names <- unique(as.character(sample_group))
sampleid <- raw_csv[, SAMPLEID_VAR]

# --- load and process contrast ---
contra_string <- unlist(strsplit(CONTRAST, split = ","))
contra_string <- gsub(" ", "", contra_string, fixed = TRUE) # remove all the white space
pasted_contrast <- paste0(contra_string, collapse = "-")
contrast_group_names <- unique(unlist(strsplit(pasted_contrast, split = "-", fixed = TRUE)))
if (!all(contrast_group_names  %in% sample_group_names)) {
  cat("contrast_none_existent")
}

# ------ process the file with the mata data ------
# group <- sample_group
raw_sample_dfm <- data.frame(sampleid = sampleid, y = sample_group, raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, GROUP_VAR)], row.names = NULL)
names(raw_sample_dfm)[-c(1:2)] <- names(raw_csv[, !names(raw_csv) %in% c(SAMPLEID_VAR, GROUP_VAR)])
feature_dat <- raw_sample_dfm[, -c(1:2)]
id_dat <- raw_sample_dfm[, c(1:2)]
# -- free memory --
rm(raw_csv)

# -- remove columns with only the same value --
drop_cols <- names(feature_dat)[which(!vapply(feature_dat, function(x) length(unique(x)) > 1, logical(1L)))]
feature_dat <- feature_dat[, !names(feature_dat) %in% drop_cols, drop = FALSE]
# raw_sample_dfm[, -c(1:2)] <- raw_sample_dfm[, -c(1:2)][vapply(raw_sample_dfm[, -c(1:2)], function(x) length(unique(x)) > 1, logical(1L))] # remove columns with only the same value

# -- data transformation --
if (MINMAX_NORM) {
  feature_dat <- apply(feature_dat, 2, FUN = function(x)(x-min(x))/(max(x)-min(x)))
}
if (ZSCORE_STAND) {
  feature_dat <- center_scale(feature_dat, scale = FALSE)$centerX
}

# -------- data output --------
# --- output data ---
raw_sample_dfm_output <- cbind(id_dat, feature_dat)

# --- output data sorting ---
rem_group_names <- sample_group_names[!sample_group_names %in% contrast_group_names]
if (length(rem_group_names) > 0)  {
  order_group_names <- c(contrast_group_names, rem_group_names)
} else {
  order_group_names <- contrast_group_names
}
new_group_order <- order(factor(sample_group, levels = order_group_names, ordered = TRUE))
raw_sample_dfm_output <- raw_sample_dfm_output[new_group_order, ]  # sorting

# ------ export and clean up the mess ------
## export to results files if needed
write.csv(file = paste0(RES_OUT_DIR, "/", CSV_2D_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm_output, row.names = FALSE)

# free memory
rm(raw_sample_dfm)

## set up additional variables for cat
group_summary <- foreach(i = 1:length(levels(sample_group)), .combine = "c") %do%
  paste0(levels(sample_group)[i], "(", summary(sample_group)[i], ")")

## cat the vairables to export to shell scipt
cat("\tSample groups (size): ", group_summary, "\n") # line 1: input raw_csv file groupping info
cat("\tInput file dimensions (w annot vars): ", raw_dim, "\n") # line 2: input dat file dimension
