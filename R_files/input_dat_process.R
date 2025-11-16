# ------ general info ------
## name: mat_process.R
## purpose: load and process mat files

## flags from Rscript
args <- commandArgs()
# print(args)

# ------ load libraries ------
require(foreach)
require(R.matlab) # to read .mat files

# ------ sys variables ------
# --- file name variables ---
MAT_FILE <- args[6]
MAT_FILE_NO_EXT <- args[7]
ANNOT_FILE <- args[8]

# --- directory variables ---
RES_OUT_DIR <- args[11]

# --- mata data input variables ---
SAMPLEID_VAR <- args[9]
GROUP_VAR <- args[10]

# ------ load mat file ------
raw <- readMat(MAT_FILE)
raw <- raw[[1]]
raw_dim <- dim(raw)

# ------ load annotation file (meta data) ------
annot <- read.csv(file = ANNOT_FILE, stringsAsFactors = FALSE, check.names = FALSE)
if (!all(c(SAMPLEID_VAR, GROUP_VAR) %in% names(annot))) {
  cat("none_existent")
  quit()
}
if (nrow(annot) != raw_dim[3]) {
  cat("unequal_length")
  quit()
}
if (any(is.na(unique(annot[, GROUP_VAR])))) {
  cat("na_values")
  quit()
}
if (length(unique(annot[, GROUP_VAR])) == 1) {
  cat("single_value")
  quit()
}

sample_group <- factor(annot[, GROUP_VAR], levels = unique(annot[, GROUP_VAR]))
sampleid <- annot[, SAMPLEID_VAR]


# ------ process the mat file with the mata data ------
raw_sample <- foreach(i = 1:raw_dim[3], .combine = "rbind") %do% {
  tmp <- raw[, , i]
  colnames(tmp) <- as.character(seq(ncol(tmp)))
  rownames(tmp) <- as.character(seq(ncol(tmp)))
  pair <- paste(rownames(tmp)[row(tmp)[upper.tri(tmp)]], colnames(tmp)[col(tmp)[upper.tri(tmp)]], sep = "_")
  sync.value <- tmp[upper.tri(tmp)]
  names(sync.value) <- pair
  sync.value
}

# group <- foreach(i = 1:length(levels(sample_group)), .combine = "c") %do% rep(levels(sample_group)[i], times = summary(sample_group)[i])
# raw_sample_dfm <- data.frame(sampleid = sampleid, group = group, raw_sample, row.names = NULL)
raw_sample_dfm <- data.frame(sampleid = sampleid, group = sample_group, raw_sample, row.names = NULL)
colnames(raw_sample_dfm)[-c(1:2)] <- dimnames(raw_sample)[[2]]
names(raw_sample_dfm)[names(raw_sample_dfm) %in% "group"] <- "y"

# raw_sample_dfm_wo_uni <- raw_sample_dfm
# names(raw_sample_dfm_wo_uni)[names(raw_sample_dfm_wo_uni) %in% "group"] <- "y"


# ------ export and clean up the mess --------
## export to results files if needed
write.csv(file = paste0(RES_OUT_DIR, "/", MAT_FILE_NO_EXT, "_2D.csv"), raw_sample_dfm, row.names = FALSE)
# write.csv(file = paste0(RES_OUT_DIR, "/", MAT_FILE_NO_EXT, "_2D_wo_uni.csv"), raw_sample_dfm_wo_uni, row.names = FALSE)

# free memory
rm(raw_sample_dfm, raw_sample_dfm_wo_uni, raw, annot)

## set up additional variables for cat
group_summary <- foreach(i = 1:length(levels(sample_group)), .combine = "c") %do%
  paste0(levels(sample_group)[i], "(", summary(sample_group)[i], ")")

## cat the vairables to export to shell scipt
cat("\tSample groups (size): ", group_summary, "\n") # line 1: input annot file groupping info
cat("\tMat file dimensions: ", raw_dim, "\n") # line 2: input mat file dimension
