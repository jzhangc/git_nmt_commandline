###### general info ------
## name: ml_svm.R
## purpose: svm modelling featuring rRF-FS

## flags from Rscript
# NOTE: the order of the flags depends on the Rscript command
args <- commandArgs()
# print(args)

######  load libraries ------
require(RBioFS)
require(RBioArray)
require(foreach)
require(parallel)
require(limma)
require(splines)

# ------ sys variables ------
# -- warning flags --
CORE_OUT_OF_RANGE <- FALSE
SVM_ROC_THRESHOLD_OUT_OF_RANGE <- FALSE

# -- file name variables --
DAT_FILE <- args[6] # ML file
MAT_FILE_NO_EXT <- args[7] # from the raw mat file, for naming export data

# -- directory variables --
RES_OUT_DIR <- args[8]

# -- processing varaibles --
# NOTE: convert string to expression using eval(parse(text = "string"))
# -- from flags --
PSETTING <- eval(parse(text = args[9]))
CORES <- as.numeric(args[10])
if (PSETTING && CORES > parallel::detectCores()) {
  CORE_OUT_OF_RANGE <- TRUE
  CORES <- parallel::detectCores() - 1
}

# -- (from config file) --
CPU_CLUSTER <- args[11]
TRAINING_PERCENTAGE <- as.numeric(args[12])
if (TRAINING_PERCENTAGE <= options()$ts.eps || TRAINING_PERCENTAGE == 1) TRAINING_PERCENTAGE <- 0.8

SVM_CV_CENTRE_SCALE <- eval(parse(text = args[13]))
SVM_CV_KERNEL <- args[14]
SVM_CV_CROSS_K <- as.numeric(args[15])
SVM_CV_TUNE_METHOD <- args[16]
SVM_CV_TUNE_CROSS_K <- as.numeric(args[17])
SVM_CV_TUNE_BOOT_N <- as.numeric(args[18])
SVM_CV_FS_RF_IFS_NTREE <- as.numeric(args[19])
SVM_CV_FS_RF_SFS_NTREE <- as.numeric(args[20])
SVM_CV_BEST_MODEL_METHOD <- args[21]
SVM_CV_FS_COUNT_CUTOFF <- as.numeric(args[22])

SVM_CROSS_K <- as.numeric(args[23])
SVM_TUNE_CROSS_K <- as.numeric(args[24])
SVM_TUNE_BOOT_N <- as.numeric(args[25])

SVM_PERM_METHOD <- args[26] # OPTIONS ARE "BY_Y" AND "BY_FEATURE_PER_Y"
SVM_PERM_N <- as.numeric(args[27])
SVM_PERM_PLOT_SYMBOL_SIZE <- as.numeric(args[28])
SVM_PERM_PLOT_LEGEND_SIZE <- as.numeric(args[29])
SVM_PERM_PLOT_X_LABEL_SIZE <- as.numeric(args[30])
SVM_PERM_PLOT_X_TICK_LABEL_SIZE <- as.numeric(args[31])
SVM_PERM_PLOT_Y_LABEL_SIZE <- as.numeric(args[32])
SVM_PERM_PLOT_Y_TICK_LABEL_SIZE <- as.numeric(args[33])
SVM_PERM_PLOT_WIDTH <- as.numeric(args[34])
SVM_PERM_PLOT_HEIGHT <- as.numeric(args[35])

SVM_ROC_THRESHOLD <- as.numeric(args[36])
SVM_ROC_SMOOTH <- eval(parse(text = args[37]))
SVM_ROC_SYMBOL_SIZE <- as.numeric(args[38])
SVM_ROC_LEGEND_SIZE <- as.numeric(args[39])
SVM_ROC_X_LABEL_SIZE <- as.numeric(args[40])
SVM_ROC_X_TICK_LABEL_SIZE <- as.numeric(args[41])
SVM_ROC_Y_LABEL_SIZE <- as.numeric(args[42])
SVM_ROC_Y_TICK_LABEL_SIZE <- as.numeric(args[43])
SVM_ROC_WIDTH <- as.numeric(args[44])
SVM_ROC_HEIGHT <- as.numeric(args[45])

RFFS_HTMAP_TEXTSIZE_COL <- as.numeric(args[46])
RFFS_HTMAP_TEXTANGLE_COL <- as.numeric(args[47])
HTMAP_LAB_ROW <- eval(parse(text = args[48]))
RFFS_HTMAP_TEXTSIZE_ROW <- as.numeric(args[49])
RFFS_HTMAP_KEYSIZE <- as.numeric(args[50])
RFFS_HTMAP_KEY_XLAB <- args[51]
RFFS_HTMAP_KEY_YLAB <- args[52]
RFFS_HTMAP_MARGIN <- eval(parse(text = args[53]))
RFFS_HTMAP_WIDTH <- as.numeric(args[54])
RFFS_HTMAP_HEIGHT <- as.numeric(args[55])

# below: for if to do the univariate redution
CVUNI <- eval(parse(text = args[56]))
LOG2_TRANS <- eval(parse(text = args[57]))
UNI_FDR <- eval(parse(text = args[58]))
UNI_ALPHA <- as.numeric(args[59])

# random state
RANDOM_STATE <- as.numeric(args[60])

# ------ set random state if available ------
if (RANDOM_STATE) {
  set.seed(RANDOM_STATE)
}

# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR) # the folder that all the results will be exports to

# ------ load and processed ML data files ------
ml_dfm <- read.csv(file = DAT_FILE, stringsAsFactors = FALSE, check.names = FALSE)
input_n_total_features <- ncol(ml_dfm[, !names(ml_dfm) %in% c("sampleid", "y"), drop = FALSE])

# ------ SVM modelling ------
final_svr_data <- ml_dfm[, !names(ml_dfm) %in% "sampleid"]

# modelling
svm_m <- rbioClass_svm(
  x = final_svr_data[, -1], y = final_svr_data$y,
  center.scale = SVM_CV_CENTRE_SCALE, kernel = SVM_CV_KERNEL,
  svm.cross.k = SVM_CROSS_K,
  tune.method = SVM_CV_TUNE_METHOD,
  tune.cross.k = SVM_TUNE_CROSS_K, tune.boot.n = SVM_TUNE_BOOT_N,
  verbose = FALSE
)

# CV modelling
svm_m_cv <- rbioClass_svm_cv(
  x = final_svr_data[, -1], y = final_svr_data$y,
  center.scale = SVM_CV_CENTRE_SCALE, kernel = SVM_CV_KERNEL, cross.k = SVM_CROSS_K, cross.best.model.method = SVM_CV_BEST_MODEL_METHOD,
  tune.method = SVM_CV_TUNE_METHOD, tune.cross.k = SVM_TUNE_CROSS_K, tune.boot.n = SVM_TUNE_BOOT_N,
  parallelComputing = PSETTING, n_cores = CORES,
  clusterType = CPU_CLUSTER,
  verbose = TRUE
)

# ------ permuation test and plotting ------
if (SVM_PERM_METHOD != "by_y") {
  cat("WARNING: SVM_PERM_METHOD can only be 'by_y' for regression. Proceed as such.\n")
  SVM_PERM_METHOD <- "by_y"
}

rbioClass_svm_perm(
  object = svm_m, perm.method = SVM_PERM_METHOD, nperm = SVM_PERM_N,
  parallelComputing = PSETTING, clusterType = CPU_CLUSTER,
  n_cores = CORES,
  perm.plot = FALSE,
  verbose = FALSE
)
rbioUtil_perm_plot(
  perm_res = svm_m_perm,
  plot.SymbolSize = SVM_PERM_PLOT_SYMBOL_SIZE,
  plot.legendSize = SVM_PERM_PLOT_LEGEND_SIZE,
  plot.xLabelSize = SVM_PERM_PLOT_X_LABEL_SIZE,
  plot.xTickLblSize = SVM_PERM_PLOT_X_TICK_LABEL_SIZE,
  plot.yLabelSize = SVM_PERM_PLOT_Y_LABEL_SIZE,
  plot.yTickLblSize = SVM_PERM_PLOT_Y_TICK_LABEL_SIZE,
  plot.Width = SVM_PERM_PLOT_WIDTH, plot.Height = SVM_PERM_PLOT_HEIGHT
)

sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("------ Permutation test ------\n")
svm_m_perm
sink()

# ------ clean up the mess and export ------
## clean up the mess from Pathview
suppressWarnings(rm(cpd.simtypes, gene.idtype.bods, gene.idtype.list, korg))

## export to results files if needed
output_for_dl <- rffs_selected_dfm

write.csv(file = paste0(MAT_FILE_NO_EXT, "_dl.csv"), output_for_dl, row.names = FALSE)

svm_training <- ml_dfm
save(
  list = c("svm_m", "svm_training", "svm_m_cv"),
  file = paste0("cv_only_", MAT_FILE_NO_EXT, "_final_svm_model.Rdata")
)


## cat the vairables to export to shell scipt
# cat("\t", dim(raw_sample_dfm), "\n") # line 1: file dimension
# cat("First five variable names: ", names(raw_sample_dfm)[1:5])
if (CORE_OUT_OF_RANGE) {
  cat("WARNING: CPU core out of range! Set to maximum cores - 1. \n")
  cat("-------------------------------------\n\n")
}
cat("ML data file summary\n")
cat("-------------------------------------\n")
cat("ML file dimensions: ", dim(ml_dfm), "\n")
cat("\n\n")
cat("Label randomization\n")
cat("-------------------------------------\n")
cat("Randomized y order saved to file: ml_randomized_group_label_order.csv\n")
cat("\n\n")
cat("Data split\n")
cat("-------------------------------------\n")
if (TRAINING_PERCENTAGE <= options()$ts.eps || TRAINING_PERCENTAGE == 1) cat("Invalid percentage. Use default instead.\n")
cat("Training set percentage: ", TRAINING_PERCENTAGE, "\n")
cat("\n\n")
cat("SVM modelling with nested cross-validation\n")
cat("-------------------------------------\n")
svm_m
cat("Total internal cross-validation RMSE: ", rbioReg_svm_rmse(object = svm_m), "\n")
cat("Final SVM model saved to file: ", paste0("cv_only_", MAT_FILE_NO_EXT, "_final_svm_model.Rdata\n"))
cat("Data with selected features saved to file: ", paste0(MAT_FILE_NO_EXT, "_dl.csv\n"))
cat("\n\n")
cat("SVM permutation test\n")
cat("-------------------------------------\n")
svm_m_perm
cat("Permutation test results saved to file: svm_m.perm.csv\n")
cat("Permutation plot saved to file: svm_m_perm.svm.perm.plot.pdf\n")
cat("\n\n")
cat("Clustering analysis\n")
# cat("PCA on SVM selected pairs\n")
cat("-------------------------------------\n")
cat("Hierarchical clustering on CV-SVR-rRF-FS selected pairs saved to:\n")
cat("\tOn all data:\n")
cat("\t\t", paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_all_samples_heatmap.pdf"), "\n")
