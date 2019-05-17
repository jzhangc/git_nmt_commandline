#!/usr/bin/env bash
# for testing small things
# below: some colours
# COLOUR_YELLOW="\033[0;33m"
# COLOUR_RED="\033[0;31m"
# COLOUR_GREEN_L="\033[1;32m"
# NO_COLOUR="\033[0;0m"

# A="/mnt/c/Users/Jing Zhang/OneDrive/knowledge_lib/0.bioinformatics/0.in_dev_codes/git_repos/private/meg_bash_test"
# B="/mnt/c/Users/Jing Zhang/OneDrive/1.labs/sickkids/projects/bash_ml_app/test_data/raw/test_data.mat"
# while getopts ":c:" opt; do
#   case $opt in
#     c)
#       CONTRAST=$OPTARG  # file with full path and extension\
#       ;;
#     :)
#       echo -e "${COLOUR_RED}\nERROR: Option -$OPTARG requires an argument.${NO_COLOUR}\n" >&2
#       exit 1
#       ;;
#     *)  # if the input option not defined
#       echo ""
#       echo -e "${COLOUR_RED}\nERROR: Invalid option: -$OPTARG${NO_COLOUR}\n" >&2
#       exit 1
#       ;;
#   esac
# done

dat_ml_file="dat_ml.csv"
MAT_FILENAME_WO_EXT="matfile"
OUT_DIR=.
PSETTING=TRUE
CORES=3

cpu_cluster="FORK"
training_percentage=0.8
svm_cv_centre_scale=TRUE
svm_cv_kernel="radial"
svm_cv_cross_k=10
svm_cv_tune_method="cross"
svm_cv_tune_cross_k=10
svm_cv_tune_boot_n=10
svm_cv_fs_rf_ifs_ntree=501
svm_cv_fs_rf_sfs_ntree=501
svm_cv_fs_count_cutoff=2
svm_cross_k=10
svm_tune_cross_k=10
svm_tune_boot_n=10
svm_perm_method="by_y"
svm_perm_n=99
svm_perm_plot_symbol_size=2
svm_perm_plot_legend_size=9
svm_perm_plot_x_label_size=10
svm_perm_plot_x_tick_label_size=10
svm_perm_plot_y_label_size=10
svm_perm_plot_y_tick_label_size=10
svm_perm_plot_width=300
svm_perm_plot_height=50
svm_roc_threshold=50 
svm_roc_smooth=FALSE
svm_roc_symbol_size=2
svm_roc_legend_size=9
svm_roc_x_label_size=10
svm_roc_x_tick_label_size=10
svm_roc_y_label_size=10
svm_roc_y_tick_label_size=10
svm_roc_width=170
svm_roc_height=150

Rscript ./r_temp.R "$dat_ml_file" "$MAT_FILENAME_WO_EXT" \
"${OUT_DIR}/OUTPUT" \
"$PSETTING" "$CORES" \
"$cpu_cluster" "$training_percentage" \
"$svm_cv_centre_scale" "$svm_cv_kernel" "$svm_cv_cross_k" "$svm_cv_tune_method" "$svm_cv_tune_cross_k" "$svm_cv_tune_boot_n" \
"$svm_cv_fs_rf_ifs_ntree" "$svm_cv_fs_rf_sfs_ntree" "$svm_cv_fs_count_cutoff" \
"$svm_cross_k" "$svm_tune_cross_k" "$svm_tune_boot_n" \
"$svm_perm_method" "$svm_perm_n" \
"$svm_perm_plot_symbol_size" "$svm_perm_plot_legend_size" "$svm_perm_plot_x_label_size" "$svm_perm_plot_x_tick_label_size" \
"$svm_perm_plot_y_label_size" "$svm_perm_plot_y_tick_label_size" "$svm_perm_plot_width" "$svm_perm_plot_height" \
"$svm_roc_threshold" "$svm_roc_smooth" "$svm_roc_symbol_size" "$svm_roc_legend_size" "$svm_roc_x_label_size" \
"$svm_roc_x_tick_label_size" "$svm_roc_y_label_size" "$svm_roc_y_tick_label_size" "$svm_roc_width" "$svm_roc_height" \
--save 2>>./test_R_log.log \
| tee -a ./test_shell_log.log
