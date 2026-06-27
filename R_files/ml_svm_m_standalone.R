###### general info --------
## name: ml_svm.R
## purpose: svm modelling featuring rRF-FS

## flags from Rscript
# NOTE: the order of the flags depends on the Rscript command
args <- commandArgs()
# print(args)

######  load libraries --------
require(RBioFS)
require(RBioArray)
require(foreach)
require(parallel)
require(limma)

# ------ sys variables --------
# --- warning flags ---
CORE_OUT_OF_RANGE <- FALSE

# --- file name variables ---
DAT_FILE <- args[6] # ML file
MAT_FILE_NO_EXT <- args[7] # from the raw mat file, for naming export data

# --- directory variables ---
RES_OUT_DIR <- args[8]

# --- processing varaibles ---
# NOTE: convert string to expression using eval(parse(text = "string"))
# -- from flags --
PSETTING <- eval(parse(text = args[9]))
CORES <- as.numeric(args[10])
if (PSETTING && CORES > parallel::detectCores()) {
  CORE_OUT_OF_RANGE <- TRUE
  CORES <- parallel::detectCores() - 1
}

# -- (from config file) --
cpu_cluster <- args[11]
training_percentage <- as.numeric(args[12])
if (training_percentage <= options()$ts.eps || training_percentage == 1) training_percentage <- 0.8

svm_cv_centre_scale <- eval(parse(text = args[13]))
svm_cv_kernel <- args[14]
svm_cv_cross_k <- as.numeric(args[15])
svm_cv_tune_method <- args[16]
svm_cv_tune_cross_k <- as.numeric(args[17])
svm_cv_tune_boot_n <- as.numeric(args[18])
svm_cv_fs_rf_ifs_ntree <- as.numeric(args[19])
svm_cv_fs_rf_sfs_ntree <- as.numeric(args[20])
svm_cv_best_model_method <- args[21]
svm_cv_fs_count_cutoff <- as.numeric(args[22])

svm_cross_k <- as.numeric(args[23])
svm_tune_cross_k <- as.numeric(args[24])
svm_tune_boot_n <- as.numeric(args[25])

svm_roc_x_label_size <- as.numeric(args[39])
svm_roc_x_tick_label_size <- as.numeric(args[40])
svm_roc_y_label_size <- as.numeric(args[41])
svm_roc_y_tick_label_size <- as.numeric(args[42])
svm_roc_width <- as.numeric(args[43])
svm_roc_height <- as.numeric(args[44])

# below: for if to do the univariate redution
CVUNI <- eval(parse(text = args[62]))
log2_trans <- eval(parse(text = args[63]))
CONTRAST <- args[64]
uni_fdr <- eval(parse(text = args[65]))
uni_alpha <- as.numeric(args[66])

# random state
random_state <- as.numeric(args[77])

###### R script --------
# ------ set random state if available
if (random_state) {
  set.seed(random_state)
}

# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR) # the folder that all the results will be exports to

# ------ load and processed ML data files ------
ml_dfm <- read.csv(file = DAT_FILE, stringsAsFactors = FALSE, check.names = FALSE)
ml_dfm$y <- factor(ml_dfm$y, levels = unique(ml_dfm$y))
input_n_total_features <- ncol(ml_dfm[, !names(ml_dfm) %in% c("sampleid", "y"), drop = FALSE])

# stratified resampling: proportionally sample by groups
training <- foreach(i = levels(ml_dfm$y), .combine = "rbind") %do% {
  dfm <- ml_dfm[ml_dfm$y == i, ]
  dfm_rand <- dfm[sample(nrow(dfm)), ]
  training_n <- ceiling(nrow(dfm_rand) * training_percentage)
  training <- dfm_rand[1:training_n, ]
}
test <- ml_dfm[!rownames(ml_dfm) %in% rownames(training), ]

# ------ internal nested cross-validation and feature selection ------
error_flag <- NA
sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("------ Internal nested cross-validation with rRF-FS error messages ------\n")
if (input_n_total_features == 1) {
  cat("WARNING: input data for ML only has one feature. No need for nested CV-rRF-FS-SVM analysis\n")
  svm_rf_selected_features <- names(ml_dfm[, !names(ml_dfm) %in% "y", drop = FALSE])
  rffs_selected_dfm <- ml_dfm
} else {
  tryCatch(
    {
      svm_nested_cv_fs <- rbioClass_svm_ncv_fs(
        x = training[, !colnames(training) %in% c("sampleid", "y")],
        y = factor(training$y, levels = unique(training$y)),
        univariate.fs = CVUNI, uni.log2trans = log2_trans,
        uni.fdr = uni_fdr, uni.alpha = uni_alpha,
        uni.contrast = CONTRAST,
        center.scale = svm_cv_centre_scale,
        kernel = svm_cv_kernel,
        cross.k = svm_cv_cross_k,
        tune.method = svm_cv_tune_method,
        tune.cross.k = svm_cv_tune_cross_k,
        tune.boot.n = svm_cv_tune_boot_n,
        fs.method = "rf",
        rf.ifs.ntree = svm_cv_fs_rf_ifs_ntree, rf.sfs.ntree = svm_cv_fs_rf_sfs_ntree,
        fs.count.cutoff = svm_cv_fs_count_cutoff,
        cross.best.model.method = svm_cv_best_model_method,
        parallelComputing = PSETTING, n_cores = CORES,
        clusterType = cpu_cluster,
        verbose = TRUE
      )
    },
    error = function(e) {
      cat(paste0("\nCV-rRF-FS-SVM feature selection step failed. try a larger uni_alpha value or running the command without -u or -k\n", "\tRef error message: ", e, "\n"))
      # below: has to add \n so cat does not output partial end of line sign: %
      error_flag <<- "fs_failure\n" # use <<- to assign global vars
      # assign("error_flag", "fs_failure\n", envir = .GlobalEnv)
    }
  )

  # extract selected features
  svm_rf_selected_features <- svm_nested_cv_fs$selected.features
  rffs_selected_dfm <- ml_dfm[, colnames(ml_dfm) %in% c("sampleid", "y", svm_rf_selected_features)] # training + testing
}
sink()
# output to the shell script
# has to add \n so cat does not output partial end of line sign: %
if (!is.na(error_flag)) {
  cat(error_flag)
  quit()
}

sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
if (input_n_total_features > 1) {
  # plotting for rRF-FS
  cat("\n\n------ SFS plot error messages ------\n")
  for (i in 1:svm_cv_cross_k) { # plot SFS curve
    tryCatch(
      {
        rbioFS_rf_SFS_plot(
          object = get(paste0("svm_nested_iter_", i, "_SFS")),
          n = "all",
          plot.file.title = paste0("svm_nested_iter_", i),
          plot.title = NULL,
          plot.titleSize = 10, plot.symbolSize = 2, plot.errorbar = c("sem"),
          plot.errorbarWidth = 0.2, plot.fontType = "sans",
          plot.xLabel = "Features",
          plot.xLabelSize = svm_roc_x_label_size,
          plot.xTickLblSize = svm_roc_x_tick_label_size,
          plot.xAngle = 0,
          plot.xhAlign = 0.5, plot.xvAlign = 0.5,
          plot.xTickItalic = FALSE, plot.xTickBold = FALSE,
          plot.yLabel = "OOB error rate",
          plot.yLabelSize = svm_roc_y_label_size, plot.yTickLblSize = svm_roc_y_tick_label_size,
          plot.yTickItalic = FALSE, plot.yTickBold = FALSE,
          plot.rightsideY = TRUE,
          plot.Width = svm_roc_width,
          plot.Height = svm_roc_height, verbose = FALSE
        )
        cat("CV fold ", i, ": no SFS plot error\n")
      },
      error = function(e) {
        cat(paste0("rRF-FS iteraction: ", i, " failed. No SFS plot for this iteration.\n", "\tRef error message: ", e, "\n"))
      }
    )
  }
}
sink()


# ------ SVM modelling ------
# -- sub set the training/test data using the selected features --
if (input_n_total_features == 1) {
  svm_training <- training[, !names(training) %in% "sampleid"]
  svm_test <- test[, !names(test) %in% "sampleid"]
} else {
  svm_training <- training[, c("y", svm_rf_selected_features)]
  svm_test <- test[, c("y", svm_rf_selected_features)]
}
training_sampleid <- training$sampleid

# -- modelling --
svm_m <- rbioClass_svm(
  x = svm_training[, -1, drop = FALSE], y = factor(svm_training$y, levels = unique(svm_training$y)),
  center.scale = svm_cv_centre_scale, kernel = svm_cv_kernel,
  svm.cross.k = svm_cross_k,
  tune.method = svm_cv_tune_method,
  tune.cross.k = svm_tune_cross_k, tune.boot.n = svm_tune_boot_n,
  verbose = FALSE
)

# CV modelling
sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("\n\n------ CV modelling ------\n")
svm_m_cv <- rbioClass_svm_cv(
  x = svm_training[, -1], y = factor(svm_training$y, levels = unique(svm_training$y)),
  center.scale = svm_cv_centre_scale, kernel = svm_cv_kernel, cross.k = svm_cross_k, cross.best.model.method = svm_cv_best_model_method,
  tune.method = svm_cv_tune_method, tune.cross.k = svm_tune_cross_k, tune.boot.n = svm_tune_boot_n,
  parallelComputing = PSETTING, n_cores = CORES,
  clusterType = cpu_cluster,
  verbose = TRUE
)
sink()


# ------ clean up the mess and export ------
## variables for display
orignal_y <- factor(ml_dfm$y, levels = unique(ml_dfm$y))
orignal_y_summary <- foreach(i = 1:length(levels(orignal_y)), .combine = "c") %do%
  paste0(levels(orignal_y)[i], "(", summary(orignal_y)[i], ")")

training_y <- factor(training$y, levels = unique(training$y))
training_summary <- foreach(i = 1:length(levels(training_y)), .combine = "c") %do%
  paste0(levels(training_y)[i], "(", summary(training_y)[i], ")")
test_y <- factor(test$y, levels = unique(test$y))
test_summary <- foreach(i = 1:length(levels(test_y)), .combine = "c") %do%
  paste0(levels(test_y)[i], "(", summary(test_y)[i], ")")

## FS count plot
rbioUtil_fscount_plot(svm_nested_cv_fs,
  export.name = paste0(MAT_FILE_NO_EXT),
  plot.yLabelSize = 20, plot.xLabelSize = 20,
  plot.Width = 170, plot.Height = 150
)

## export to results files if needed
# y_randomized <- data.frame(`New order` = seq(length(ml_dfm_randomized$y)), `Randomized group labels` = ml_dfm_randomized$y,
#                            check.names = FALSE)
write.csv(file = "ml_training.csv", training, row.names = FALSE)
write.csv(file = "ml_test.csv", test, row.names = FALSE)
save(
  list = c("svm_m", "svm_m_cv", "svm_nested_cv_fs", "svm_rf_selected_features", "svm_training", "svm_test", "rffs_nested_cv_auc", "final_cv_auc", "svm_m_training_svm_roc_auc", "svm_m_test_svm_roc_auc"),
  file = paste0(MAT_FILE_NO_EXT, "_final_svm_model.Rdata")
)


## cat the vairables to export to shell scipt
# cat("\t", dim(raw_sample_dfm), "\n") # line 1: file dimension
# cat("First five variable names: ", names(raw_sample_dfm)[1:5])
if (CORE_OUT_OF_RANGE) {
  cat("WARNING: CPU core number out of range! Set to maximum cores - 1. \n")
  cat("-------------------------------------\n\n")
}
cat("ML data file summary\n")
cat("-------------------------------------\n")
cat("ML file dimensions: ", dim(ml_dfm), "\n")
cat("Group labels (size): ", orignal_y_summary, "\n")
cat("\n\n")
cat("Label randomization\n")
cat("-------------------------------------\n")
cat("Training and test files saved to: ml_training.csv ml_test.csv\n")
cat("\n\n")
cat("Data split\n")
cat("-------------------------------------\n")
if (training_percentage <= options()$ts.eps || training_percentage == 1) cat("Invalid percentage. Use default instead.\n")
cat("Training set percentage: ", training_percentage, "\n")
cat("Training set: ", training_summary, "\n")
cat("test set: ", test_summary, "\n")
cat("\n\n")
cat("SVM nested cross validation with rRF-FS\n")
cat("-------------------------------------\n")
svm_nested_cv_fs
cat("\n\n")
cat("SVM modelling\n")
cat("-------------------------------------\n")
svm_m
cat("Total internal cross-validation accuracy: ", svm_m$tot.accuracy / 100, "\n")
cat("Final SVM model saved to file: ", paste0(MAT_FILE_NO_EXT, "_final_svm_model.Rdata\n"))
