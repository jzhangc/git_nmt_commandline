##### current main objective: separate the formatting from diagonal matrix to a 2D table functionality from correlation functions
rm(list = ls(all = TRUE))

###### load the R file ----
setwd("~/OneDrive/1.labs/sickkids/ben D data/longitudinal ptsd/raw_mat_files")
load(file = "meg_longitudinal.Rdata")


###### load libraries ----
require(doParallel)
require(foreach)
library(limma)
library(edgeR)
library(R.matlab) # to read .mat files
library(gplots)
library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(RBioArray)
setwd("~/OneDrive/knowledge_lib/0.bioinformatics/0.in_dev_codes/git_repos/git_RBioArray/RBioArray") # package wd
library(RBioFS)
setwd("~/OneDrive/knowledge_lib/0.bioinformatics/0.in_dev_codes/git_repos/git_RBioFS/RBioFS/") # pacakge wd


###### DE analysis ------
## data formating
X <- devDat_dfm[, -c(1:2)]
E <- apply(t(X), c(1, 2), FUN = function(x)log2(x + 2))
colnames(E) <- devDat_dfm$dataid
pair <- data.frame(ProbeName = seq(ncol(devDat_dfm) - 2), pair = colnames(devDat_dfm)[-c(1:2)])

sample <- paste0(devDat_dfm$dataid, "_", annot_prelearn$group)
idx <- data.frame(devDat_dfm[, c(1:2)], group = factor(annot_prelearn$group, levels = unique(annot_prelearn$group)), sample = sample)
rawlist <- list(E = E, genes = pair, targets = idx)

## normalization
normdata <- suppressMessages(rbioarray_PreProc(rawlist = rawlist, offset = 2, normMethod = "quantile", bgMethod = "none"))

rbioarray_hcluster(plotName = "low_theta_test", fltlist = normdata, n = "all",
                   fct = factor(idx$sample, levels = unique(idx$sample)),
                   ColSideCol = FALSE, mapColour = "PRGn",
                   sampleName = idx$sample,
                   genesymbolOnly = FALSE,
                   trace = "none", ctrlProbe = FALSE, rmControl = FALSE,
                   srtCol = 90, offsetCol = 0, dataProbeVar = "ProbeName",
                   key.title = "", cexCol = 0.7, cexRow = 0.2,labRow = "",
                   keysize = 1.5, key.xlab = "Normalized AEC", key.ylab = "Connection count",
                   plotWidth = 8, plotHeight = 7, margin = c(6, 4))

## set up design and DE analysis
nsy <- splines::ns(devDat_dfm$pcl)
design <- model.matrix(~ nsy)

rbioarray_DE(objTitle = "prelearn_test",
             input.outcome.mode = "cont",
             output.mode = "probe.all",
             fltlist = normdata, design = design, contra = NULL,
             weights = NULL,
             plot = FALSE, ctrlProbe = FALSE)

sig_connection <- as.character(prelean_test_fit$pair[prelean_test_fit$P.Value < 0.05])

###### setup SVM data ----
x_ml <- t(normdata$E)[, sig_connection]  # use quantile normalized values
ml_dfm <- data.frame(y = devDat_dfm$pcl, x_ml, check.names = FALSE)

ml_dfm_randomized <- ml_dfm[sample(nrow(ml_dfm)), ]
training_n <- ceiling(nrow(ml_dfm_randomized) * 0.9)  # this is 0.9 now

ml_training_set <- ml_dfm_randomized[1:training_n , ]
ml_test_set <- ml_dfm_randomized[(training_n + 1):nrow(ml_dfm_randomized), ]


## nested CV
svm_nested_cv <- rbioClass_svm_ncv_fs(x = ml_training_set[, -c(1:2)],
                                      y = ml_training_set$y,
                                      center.scale = TRUE, kernel = "radial",
                                      cross.k = 10, tune.method = "cross", tune.cross.k = 10,
                                      tune.boot.n = 10, fs.method = "rf", rf.ifs.ntree = 1001,
                                      rf.sfs.ntree = 1001, fs.count.cutoff = 2,
                                      parallelComputing = TRUE, n_cores = parallel::detectCores() - 1,
                                      clusterType = "FORK", verbose = TRUE)
svm_nested_cv
# SVM model type: regression
#
# Total nested cross-validation RMSE:
#   tot.nested.RMSE              sd             sem
# 22.850254        6.904135        2.183279
#
# Consensus selected features (count threshold: 2):
#   41_48 5_49 29_50 10_54 36_83 51_78 3_54 11_27 44_45 70_77 21_46 28_89 33_42 11_47 17_64 24_65 52_83 9_34


for (i in 1:10){
  rbioFS_rf_SFS_plot(object = get(paste0("svm_nested_iter_", i, "_SFS")),
                     n = "all",
                     plot.file.title = paste0("svm_nested_iter_", i),
                     plot.title = NULL,
                     plot.titleSize = 10, plot.symbolSize = 2, plot.errorbar = c("sem"),
                     plot.errorbarWidth = 0.2, plot.fontType = "sans",
                     plot.xLabel = "Features", plot.xLabelSize = 10, plot.xAngle = 0,
                     plot.xhAlign = 0.5, plot.xvAlign = 0.5, plot.xTickLblSize = 10,
                     plot.xTickItalic = FALSE, plot.xTickBold = FALSE,
                     plot.rightsideY = TRUE, plot.yLabel = "OOB error rate",
                     plot.yLabelSize = 10, plot.yTickLblSize = 10,
                     plot.yTickItalic = FALSE, plot.yTickBold = FALSE, plot.Width = 170,
                     plot.Height = 150, verbose = TRUE)
}


foreach(i = 1:10, .packages = "RBioFS") %do% {
  rbioFS_rf_SFS_plot(object = get(paste0("svm_nested_iter_", i, "_SFS")),
                     n = "all",
                     plot.file.title = paste0("svm_nested_iter_", i),
                     plot.title = NULL,
                     plot.titleSize = 10, plot.symbolSize = 2, plot.errorbar = c("sem"),
                     plot.errorbarWidth = 0.2, plot.fontType = "sans",
                     plot.xLabel = "Features", plot.xLabelSize = 10, plot.xAngle = 0,
                     plot.xhAlign = 0.5, plot.xvAlign = 0.5, plot.xTickLblSize = 10,
                     plot.xTickItalic = FALSE, plot.xTickBold = FALSE,
                     plot.rightsideY = TRUE, plot.yLabel = "OOB error rate",
                     plot.yLabelSize = 10, plot.yTickLblSize = 10,
                     plot.yTickItalic = FALSE, plot.yTickBold = FALSE, plot.Width = 170,
                     plot.Height = 150, verbose = TRUE)
  garbage <- dev.off()
}
stopCluster(cl) # close connect when exiting the function
rm(i,  cl, n_cores)
i = 1

## SVM modelling
svm_traning_set <- ml_training_set[, c("y", svm_nested_cv$selected.features)]
svm_test_set <- ml_test_set[, c("y", svm_nested_cv$selected.features)]

prelearn_svm_model <- rbioClass_svm(x = svm_traning_set[, -1], y = svm_traning_set$y, center.scale = TRUE,
                                    kernel = "radial", svm.cross.k = 10, tune.cross.k = 35)
prelearn_svm_model
# Parameters:
#   SVM-Type:  eps-regression
# SVM-Kernel:  radial
# cost:  4
# gamma:  0.02777778
# epsilon:  0.1
# Sigma:  15.81517
#
# Number of Support Vectors:  38

## permutation test
rbioClass_svm_perm(object = prelearn_svm_model, perm.method = "by_y", nperm = 99,
                   parallelComputing = TRUE, clusterType = "FORK", perm.plot = FALSE,
                   verbose = TRUE)
rbioUtil_perm_plot(perm_res = prelearn_svm_model_perm, plot.Width = 300, plot.Height = 50)

## ROC AUC
rbioClass_svm_roc_auc(object = prelearn_svm_model, newdata = svm_test_set[, -1],
                      newdata.y = svm_test_set$y,
                      y.threshold = 50,
                      center.scale.newdata = TRUE)


## prediction test
rbioClass_svm_predcit(object = prelearn_svm_model, newdata = svm_test_set[, -1],
                      newdata.y = svm_test_set$y,
                      sampleLabel.vector = NULL,
                      center.scale.newdata = TRUE)
prelearn_svm_model_svm_predict
# Model type:  regression
# Total RMSE on test set: 22.43528


#### save the data file ----
rm(cpd.simtypes, gene.idtype.bods, gene.idtype.list, korg, matList, i, j, n_cores, cl)
save(list = ls(all = TRUE), file = "meg_longitudinal.Rdata")
