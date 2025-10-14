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

###### sys variables --------
# ------ warning flags ------
CORE_OUT_OF_RANGE <- FALSE

# ------ file name variables ------
DAT_FILE <- args[6] # ML file
MAT_FILE_NO_EXT <- args[7] # from the raw mat file, for naming export data

# ------ directory variables ------
RES_OUT_DIR <- args[8]

# ------ processing varaibles ------
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

SVM_ROC_SMOOTH <- eval(parse(text = args[36]))
SVM_ROC_SYMBOL_SIZE <- as.numeric(args[37])
SVM_ROC_LEGEND_SIZE <- as.numeric(args[38])
SVM_ROC_X_LABEL_SIZE <- as.numeric(args[39])
SVM_ROC_X_TICK_LABEL_SIZE <- as.numeric(args[40])
SVM_ROC_Y_LABEL_SIZE <- as.numeric(args[41])
SVM_ROC_Y_TICK_LABEL_SIZE <- as.numeric(args[42])
SVM_ROC_WIDTH <- as.numeric(args[43])
SVM_ROC_HEIGHT <- as.numeric(args[44])

PCA_SCALE_DATA <- eval(parse(text = args[45]))
PCA_CENTRE_DATA <- eval(parse(text = args[46]))
PCA_BIPLOT_SAMPLELABEL_TYPE <- args[47]
PCA_BIPLOT_SAMPLELABEL_SIZE <- as.numeric(args[48])
PCA_BIPLOT_SYMBOL_SIZE <- as.numeric(args[49])
PCA_BIPLOT_ELLIPSE <- eval(parse(text = args[50]))
PCA_BIPLOT_LOADING <- eval(parse(text = args[51]))
PCA_BIPLOT_LOADING_TEXTSIZE <- as.numeric(args[52])
PCA_BIPLOT_MULTI_DESITY <- eval(parse(text = args[53]))
PCA_BIPLOT_MULTI_STRIPLABEL_SIZE <- as.numeric(args[54])
PCA_RIGHTSIDE_Y <- eval(parse(text = args[55]))
PCA_X_TICK_LABEL_SIZE <- as.numeric(args[56])
PCA_Y_TICK_LABEL_SIZE <- as.numeric(args[57])
PCA_WIDTH <- as.numeric(args[58])
PCA_HEIGHT <- as.numeric(args[59])
SVM_RFFS_PCA_PC <- eval(parse(text = args[60]))
SVM_RFFS_PCA_BIPLOT_ELLIPSE_CONF <- as.numeric(args[61])

# below: for if to do the univariate redution
CVUNI <- eval(parse(text = args[62]))
LOG2_TRANS <- eval(parse(text = args[63]))
CONTRAST <- args[64]
UNI_FDR <- eval(parse(text = args[65]))
UNI_ALPHA <- as.numeric(args[66])

# below: RFFS heatmap
RFFS_HTMAP_TEXTSIZE_COL <- as.numeric(args[67])
RFFS_HTMAP_TEXTANGLE_COL <- as.numeric(args[68])
HTMAP_LAB_ROW <- eval(parse(text = args[69]))
RFFS_HTMAP_TEXTSIZE_ROW <- as.numeric(args[70])
RFFS_HTMAP_KEYSIZE <- as.numeric(args[71])
RFFS_HTMAP_KEY_XLAB <- args[72]
RFFS_HTMAP_KEY_YLAB <- args[73]
RFFS_HTMAP_MARGIN <- eval(parse(text = args[74]))
RFFS_HTMAP_WIDTH <- as.numeric(args[75])
RFFS_HTMAP_HEIGHT <- as.numeric(args[76])

# random state
RANDOM_STATE <- as.numeric(args[77])

###### R script --------
# ------ set random state if available
if (RANDOM_STATE) {
  set.seed(RANDOM_STATE)
}

# ------ set the output directory as the working directory ------
setwd(RES_OUT_DIR) # the folder that all the results will be exports to

# ------ import svm models ------
load(paste0(MAT_FILE_NO_EXT, "_final_svm_model.Rdata"))

# ------ permuation test and plotting ------
if (input_n_total_features == 1 && SVM_PERM_METHOD == "by_feature_per_y") {
  cat("WARNING: SVM_PERM_METHOD == 'by_feature_per_y' not valid with only one selected features. Set to 'by_y'.\n")
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
cat("\n\n------ Permutation test results display ------\n")
svm_m_perm
sink()


# ------ ROC-AUC ------
sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("\n\n------ ROC-AUC results display ------\n")
if (input_n_total_features == 1) {
  cat("WARNING: no need for ROC for CV-rRF-FS-SVM models with only one input feature.")
} else {
  cat("-- On CV-SVM-rRF-FS (nested) models --\n")
  tryCatch(
    {
      # nested cv roc-auc
      rbioClass_svm_cv_roc_auc(svm_nested_cv_fs,
        plot.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )

      rffs_nested_cv_auc <- vector(mode = "list", length = length(unique(ml_dfm$y)))
      for (i in 1:length(rffs_nested_cv_auc)) {
        out <- vector(length = length(svm_nested_cv_fs_svm_nestedcv_roc_auc))
        for (j in 1:length(svm_nested_cv_fs_svm_nestedcv_roc_auc)) {
          out[j] <- svm_nested_cv_fs_svm_nestedcv_roc_auc[[j]]$svm.roc_object[[i]]$auc
        }
        rffs_nested_cv_auc[[i]] <- out
      }

      for (i in 1:length(svm_nested_cv_fs_svm_nestedcv_roc_auc)) { # set up group names for display
        skip_to_next <- FALSE
        nested_cv_names <- tryCatch(
          {
            names(svm_nested_cv_fs_svm_nestedcv_roc_auc[[i]]$svm.roc_object)
          },
          error = function(e) skip_to_next <<- TRUE
        )
        if (skip_to_next) {
          next
        } else {
          break
        }
      }
      names(rffs_nested_cv_auc) <- nested_cv_names

      for (i in 1:length(rffs_nested_cv_auc)) {
        cat(paste0("CV-SVM-rRF-FS ", names(rffs_nested_cv_auc)[i], " AUC(mean): ", mean(rffs_nested_cv_auc[[i]]), "\n"))
        cat(paste0("CV-SVM-rRF-FS ", names(rffs_nested_cv_auc)[i], " AUC(SD): ", sd(rffs_nested_cv_auc[[i]]), "\n"))
      }

      # nested cv mean roc-auc with interporlation
      rbioClass_svm_cv_roc_auc_mean(
        object = svm_nested_cv_fs, roc.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )
      cat("\n")
    },
    error = function(e) cat(paste0("ROC-AUC for nested CV-SVM-rRF-FS generated error(s)\n", "\tRef error message: ", e, "\n"))
  )

  tryCatch(
    {
      cat("-- On final CV models --\n")
      # cv on mean roc-auc
      rbioClass_svm_cv_roc_auc(svm_m_cv,
        plot.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )

      # mean cv auc with interporlation
      rbioClass_svm_cv_roc_auc_mean(
        object = svm_m_cv, roc.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )

      # final cv auc
      final_cv_auc <- vector(mode = "list", length = length(unique(ml_dfm$y)))
      for (i in 1:length(final_cv_auc)) {
        out <- vector(length = length(svm_m_cv_svm_cv_roc_auc))
        for (j in 1:length(svm_m_cv_svm_cv_roc_auc)) {
          tryCatch(
            {
              out[j] <- svm_m_cv_svm_cv_roc_auc[[j]]$svm.roc_object[[i]]$auc
            },
            error = function(e) {
              cat(paste0("ERROR: svm_m_cv_svm_cv_roc_auc[[", j, "]] not found. Skip to next.\n", "\tRef error message: ", e, "\n"))
              out[j] <- NA
            }
          )
        }
        final_cv_auc[[i]] <- out
      }

      for (i in 1:length(svm_m_cv_svm_cv_roc_auc)) { # set up group names for display
        skip_to_next <- FALSE
        final_cv_names <- tryCatch(
          {
            names(svm_m_cv_svm_cv_roc_auc[[i]]$svm.roc_object)
          },
          error = function(e) skip_to_next <<- TRUE
        )
        if (skip_to_next) {
          next
          cat(paste0("WARNING: svm_m_cv_svm_cv_roc_auc[[", i, "]]\n"))
        } else {
          break
        }
      }
      names(final_cv_auc) <- final_cv_names

      for (i in 1:length(final_cv_auc)) {
        cat(paste0("Final CV ", names(final_cv_auc)[i], " AUC(mean): ", mean(final_cv_auc[[i]]), "\n"))
        cat(paste0("Final CV ", names(final_cv_auc)[i], " AUC(SD): ", sd(final_cv_auc[[i]]), "\n"))
      }

      cat("\n-- On training data --\n")
      rbioClass_svm_roc_auc(
        object = svm_m, fileprefix = "svm_m_training",
        plot.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE, plot.SymbolSize = SVM_ROC_SYMBOL_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )

      cat("\n-- On holdout test data --\n")
      rbioClass_svm_roc_auc(
        object = svm_m, fileprefix = "svm_m_test",
        newdata = svm_test[, -1], newdata.label = factor(svm_test$y, levels = unique(svm_test$y)),
        center.scale.newdata = SVM_CV_CENTRE_SCALE,
        plot.smooth = SVM_ROC_SMOOTH,
        plot.legendSize = SVM_ROC_LEGEND_SIZE, plot.SymbolSize = SVM_ROC_SYMBOL_SIZE,
        plot.xLabelSize = SVM_ROC_X_LABEL_SIZE, plot.xTickLblSize = SVM_ROC_X_TICK_LABEL_SIZE,
        plot.yLabelSize = SVM_ROC_Y_LABEL_SIZE, plot.yTickLblSize = SVM_ROC_Y_TICK_LABEL_SIZE,
        plot.Width = SVM_ROC_WIDTH, plot.Height = SVM_ROC_HEIGHT,
        verbose = FALSE
      )
    },
    error = function(e) cat(paste0("ROC-AUC for final cv and final models generated error(s)\n", "\tRef error message: ", e, "\n"))
  )
}
sink()


# ------ SHAP analysis ------
sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("\n\n------ Aggregated SHAP analysis messages ------\n")
tryCatch(
  {
    shap_out <- rbioClass_svm_shap_aggregated(
      model = svm_m, X = svm_test[, -1], bg_X = svm_training[, -1],
      parallelComputing = PSETTING, clusterType = "PSOCK",
      n_cores = CORES, randomState = RANDOM_STATE,
      plot.type = "both", plot.n = Inf,
      plot.filename.prefix = "svm_m",
      plot.bee.colorscale = "D",
      plot.xLabel = NULL, plot.yLabel = NULL, plot.yTickLblSize = 12,
      plot.Width = 410, plot.Height = 255
    )
  },
  error = function(e) {
    cat(paste0("ERROR: . \n", "\tError message: ", e, "\n"))
  },
  warining = function(w) {
    cat(paste0("Warning message(s) generated during aggregated SHAP analysis\n", "\tRef warning message: ", w, "\n"))
  }
)
sink()


# ------ PCA & clustering ------
# -- PCA --
sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("\n\n------ PCA error messages ------\n")
if (length(SVM_RFFS_PCA_PC) > length(svm_rf_selected_features)) {
  SVM_RFFS_PCA_PC <- 1:length(svm_rf_selected_features)
  cat("PCA: set PCs greater than selected features. Proceed with PC = number of features\n")
}

# FS PCA on training
pca_svm_rffs_training <- data.frame(row_num = 1:nrow(svm_training), svm_training, check.names = FALSE)

tryCatch(
  {
    rbioFS_PCA(
      input = pca_svm_rffs_training, 
      export.mode = "full", 
      sampleIDVar = "row_num", groupIDVar = "y",
      scaleData = PCA_SCALE_DATA, centerData = PCA_CENTRE_DATA, boxplot = TRUE,
      boxplot.Title = NULL, boxplot.Width = PCA_WIDTH, boxplot.Height = PCA_HEIGHT,
      biplot = TRUE, biplot.comps = SVM_RFFS_PCA_PC, biplot.Title = NULL,
      biplot.sampleLabel.type = PCA_BIPLOT_SAMPLELABEL_TYPE, biplot.sampleLabelSize = PCA_BIPLOT_SAMPLELABEL_SIZE,
      biplot.sampleLabel.padding = 0.5, biplot.SymbolSize = PCA_BIPLOT_SYMBOL_SIZE,
      biplot.ellipse = PCA_BIPLOT_ELLIPSE, biplot.ellipse_conf = SVM_RFFS_PCA_BIPLOT_ELLIPSE_CONF,
      biplot.xAngle = 0, biplot.xhAlign = 0.5, biplot.xvAlign = 0.5,
      biplot.loadingplot = PCA_BIPLOT_LOADING, biplot.loadingplot.textsize = PCA_BIPLOT_LOADING_TEXTSIZE,
      biplot.mtx.densityplot = PCA_BIPLOT_MULTI_DESITY, biplot.mtx.stripLblSize = PCA_BIPLOT_MULTI_STRIPLABEL_SIZE,
      biplot.Width = PCA_WIDTH, biplot.Height = PCA_HEIGHT, rightsideY = PCA_RIGHTSIDE_Y,
      fontType = "sans", xTickLblSize = PCA_X_TICK_LABEL_SIZE, yTickLblSize = PCA_Y_TICK_LABEL_SIZE,
      verbose = FALSE
    )
    cat("No PCA error\n")
  },
  error = function(e) {
    cat(paste0("PCA on training data failed. Check the data. \n", "\tRef error message: ", e, "\n"))
    pca_svm_rffs_training_pca_obj <- NULL
  }
)

# below: FS PCA on all data
pca_svm_rffs_all_samples <- data.frame(
  row_num = 1:nrow(rffs_selected_dfm), rffs_selected_dfm[, !colnames(rffs_selected_dfm) %in% "sampleid"],
  check.names = FALSE
)

tryCatch(
  {
    rbioFS_PCA(
      input = pca_svm_rffs_all_samples, 
      export.mode = "full", 
      sampleIDVar = "row_num", groupIDVar = "y",
      scaleData = PCA_SCALE_DATA, centerData = PCA_CENTRE_DATA, boxplot = TRUE,
      boxplot.Title = NULL, boxplot.Width = PCA_WIDTH, boxplot.Height = PCA_HEIGHT,
      biplot = TRUE, biplot.comps = SVM_RFFS_PCA_PC, biplot.Title = NULL,
      biplot.sampleLabel.type = PCA_BIPLOT_SAMPLELABEL_TYPE, biplot.sampleLabelSize = PCA_BIPLOT_SAMPLELABEL_SIZE,
      biplot.sampleLabel.padding = 0.5, biplot.SymbolSize = PCA_BIPLOT_SYMBOL_SIZE,
      biplot.ellipse = PCA_BIPLOT_ELLIPSE, biplot.ellipse_conf = SVM_RFFS_PCA_BIPLOT_ELLIPSE_CONF,
      biplot.xAngle = 0, biplot.xhAlign = 0.5, biplot.xvAlign = 0.5,
      biplot.loadingplot = PCA_BIPLOT_LOADING, biplot.loadingplot.textsize = PCA_BIPLOT_LOADING_TEXTSIZE,
      biplot.mtx.densityplot = PCA_BIPLOT_MULTI_DESITY, biplot.mtx.stripLblSize = PCA_BIPLOT_MULTI_STRIPLABEL_SIZE,
      biplot.Width = PCA_WIDTH, biplot.Height = PCA_HEIGHT, rightsideY = PCA_RIGHTSIDE_Y,
      fontType = "sans", xTickLblSize = PCA_X_TICK_LABEL_SIZE, yTickLblSize = PCA_Y_TICK_LABEL_SIZE,
      verbose = FALSE
    )
  },
  error = function(e) {
    cat(paste0("PCA on all data failed. try with less PCs.\n", "\tRef error message: ", e, "\n"))
    pca_svm_rffs_all_samples_pca_obj <- NULL
  }
)
sink()

sink(file = paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), append = TRUE)
cat("\n\n------ hcluster error messages ------\n")
# -- hcluster after nested CV: all data --
rffs_selected_E <- rffs_selected_dfm[, -c(1:2)] # all sample: training + test
normdata_crosscv <- list(
  E = t(rffs_selected_E),
  genes = data.frame(ProbeName = seq(ncol(rffs_selected_E)), pair = colnames(rffs_selected_E)),
  targets = data.frame(id = seq(nrow(rffs_selected_dfm)), sample = rffs_selected_dfm$sampleid),
  ArrayWeight = NULL
)

tryCatch(
  {
    if (HTMAP_LAB_ROW) {
      rbioarray_hcluster(
        plotName = paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_all_samples"),
        fltlist = normdata_crosscv, n = "all",
        fct = factor(rffs_selected_dfm$y, levels = unique(rffs_selected_dfm$y)),
        ColSideCol = TRUE,
        sampleName = normdata_crosscv$targets$sample,
        genesymbolOnly = FALSE,
        trace = "none", ctrlProbe = FALSE, rmControl = FALSE,
        srtCol = RFFS_HTMAP_TEXTANGLE_COL, offsetCol = 0,
        key.title = "", dataProbeVar = "pair",
        cexCol = RFFS_HTMAP_TEXTSIZE_COL, cexRow = RFFS_HTMAP_TEXTSIZE_ROW,
        keysize = RFFS_HTMAP_KEYSIZE,
        key.xlab = RFFS_HTMAP_KEY_XLAB,
        key.ylab = RFFS_HTMAP_KEY_YLAB,
        plotWidth = RFFS_HTMAP_WIDTH, plotHeight = RFFS_HTMAP_HEIGHT,
        margin = RFFS_HTMAP_MARGIN
      )
    } else {
      rbioarray_hcluster(
        plotName = paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_all_samples"),
        fltlist = normdata_crosscv, n = "all",
        fct = factor(rffs_selected_dfm$y, levels = unique(rffs_selected_dfm$y)),
        ColSideCol = TRUE,
        sampleName = normdata_crosscv$targets$sample,
        genesymbolOnly = FALSE,
        trace = "none", ctrlProbe = FALSE, rmControl = FALSE,
        srtCol = RFFS_HTMAP_TEXTANGLE_COL, offsetCol = 0,
        key.title = "", dataProbeVar = "pair", labRow = FALSE,
        cexCol = RFFS_HTMAP_TEXTSIZE_COL, cexRow = RFFS_HTMAP_TEXTSIZE_ROW,
        keysize = RFFS_HTMAP_KEYSIZE,
        key.xlab = RFFS_HTMAP_KEY_XLAB,
        key.ylab = RFFS_HTMAP_KEY_YLAB,
        plotWidth = RFFS_HTMAP_WIDTH, plotHeight = RFFS_HTMAP_HEIGHT,
        margin = RFFS_HTMAP_MARGIN
      )
    }
    cat("No hclust error\n")
  },
  error = function(e) {
    cat(paste0("ERROR: hclustering failed. skipped.\n", "\tRef error message: ", e, "\n"))
  },
  warining = function(w) {
    cat(paste0("WARNING: hclustering warning generated.\n", "\tRef warning message: ", w, "\n"))
  }
)
sink()

# -- hcluster after nested CV: training data --
svm_training_E <- svm_training[, -1]
normdata_crosscv_training <- list(
  E = t(svm_training_E),
  genes = data.frame(ProbeName = seq(ncol(svm_training_E)), pair = colnames(svm_training_E)),
  targets = data.frame(id = seq(nrow(training)), sample = training_sampleid),
  ArrayWeight = NULL
)
if (HTMAP_LAB_ROW) {
  rbioarray_hcluster(
    plotName = paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_training"),
    fltlist = normdata_crosscv_training, n = "all",
    fct = factor(svm_training$y, levels = unique(svm_training$y)),
    ColSideCol = TRUE,
    sampleName = normdata_crosscv_training$targets$sample,
    genesymbolOnly = FALSE,
    trace = "none", ctrlProbe = FALSE, rmControl = FALSE,
    srtCol = RFFS_HTMAP_TEXTANGLE_COL, offsetCol = 0,
    key.title = "", dataProbeVar = "pair",
    cexCol = RFFS_HTMAP_TEXTSIZE_COL, cexRow = RFFS_HTMAP_TEXTSIZE_ROW,
    keysize = RFFS_HTMAP_KEYSIZE,
    key.xlab = RFFS_HTMAP_KEY_XLAB,
    key.ylab = RFFS_HTMAP_KEY_YLAB,
    plotWidth = RFFS_HTMAP_WIDTH, plotHeight = RFFS_HTMAP_HEIGHT,
    margin = RFFS_HTMAP_MARGIN
  )
} else {
  rbioarray_hcluster(
    plotName = paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_training"),
    fltlist = normdata_crosscv_training, n = "all",
    fct = factor(svm_training$y, levels = unique(svm_training$y)),
    ColSideCol = TRUE,
    sampleName = normdata_crosscv_training$targets$sample,
    genesymbolOnly = FALSE,
    trace = "none", ctrlProbe = FALSE, rmControl = FALSE,
    srtCol = RFFS_HTMAP_TEXTANGLE_COL, offsetCol = 0,
    key.title = "", dataProbeVar = "pair", labRow = FALSE,
    cexCol = RFFS_HTMAP_TEXTSIZE_COL, cexRow = RFFS_HTMAP_TEXTSIZE_ROW,
    keysize = RFFS_HTMAP_KEYSIZE,
    key.xlab = RFFS_HTMAP_KEY_XLAB,
    key.ylab = RFFS_HTMAP_KEY_YLAB,
    plotWidth = RFFS_HTMAP_WIDTH, plotHeight = RFFS_HTMAP_HEIGHT,
    margin = RFFS_HTMAP_MARGIN
  )
}

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
# write.csv(file = "ml_training.csv", training, row.names = FALSE)
# write.csv(file = "ml_test.csv", test, row.names = FALSE)
# save(
#   list = c("svm_m", "svm_m_cv", "svm_nested_cv_fs", "svm_rf_selected_features", "svm_training", "svm_test", "rffs_nested_cv_auc", "final_cv_auc", "svm_m_training_svm_roc_auc", "svm_m_test_svm_roc_auc"),
#   file = paste0(MAT_FILE_NO_EXT, "_final_svm_model.Rdata")
# )
save(
  list = c("rffs_nested_cv_auc", "final_cv_auc", "svm_m_training_svm_roc_auc", "svm_m_test_svm_roc_auc", "pca_svm_rffs_training_pca_obj", "pca_svm_rffs_all_samples_pca_obj"),
  file = paste0(MAT_FILE_NO_EXT, "_final_svm_assessment.Rdata")
)

## cat the vairables to export to shell scipt
# cat("\t", dim(raw_sample_dfm), "\n") # line 1: file dimension
# cat("First five variable names: ", names(raw_sample_dfm)[1:5])
if (CORE_OUT_OF_RANGE) {
  cat("WARNING: CPU core number out of range! Set to maximum cores - 1. \n")
  cat("-------------------------------------\n\n")
}
cat("SVM model file summary\n")
cat("-------------------------------------\n")
cat("\n\n")
cat("SVM permutation test\n")
cat("-------------------------------------\n")
svm_m_perm
cat("Permutation test results saved to file: svm_m.perm.csv\n")
cat("Permutation plot saved to file: svm_m_perm.svm.perm.plot.pdf\n")
cat("\n\n")
cat("ROC-AUC\n")
cat("-------------------------------------\n")
cat("NOTE: Check the SVM results file ", paste0(MAT_FILE_NO_EXT, "_svm_results.txt"), " for AUC values.\n")
cat("ROC figure saved to file (check SVM result file for AUC value):\n\tsvm_nested_cv_fs.cv_roc.GROUP.pdf, svm_nested_cv_fs.cv_roc_mean.pdf\n\tsvm_m_cv.cv_roc_mean.pdf, svm_m_cv.cv_roc.GROUPNAME.pdf\n\tsvm_m_training.svm.roc.pdf, svm_m_test.svm.roc.pdf\n")
cat("\n\n")
cat("Clustering analysis\n")
# cat("PCA on SVM selected pairs\n")
cat("-------------------------------------\n")
cat("PCA on CV-SVM-rRF-FS selected feature saved to:\n")
cat("\tOn all data:\n")
cat("\t\tbiplot: pca_svm_rffs_all_samples.pca.biplot.pdf\n")
cat("\t\tboxplot: pca_svm_rffs_all_samples.pca.boxplot.pdf\n")
cat("\tOn training data:\n")
cat("\t\tbiplot: pca_svm_rffs_training.pca.biplot.pdf\n")
cat("\t\tboxplot: pca_svm_rffs_training.pca.boxplot.pdf\n")
cat("\n\n")
cat("Hierarchical clustering on CV-SVM-rRF-FS selected features saved to:\n")
cat("\tOn all data:\n")
cat("\t\t", paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_all_samples_heatmap.pdf"), "\n")
cat("\tOn training data:\n")
cat("\t\t", paste0(MAT_FILE_NO_EXT, "_hclust_nestedcv_training_heatmap.pdf"), "\n")
