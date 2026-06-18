#!/usr/bin/env bash
# Name: cv_connectivity_ml.sh
# Description: A shell script application for automated machine learning analysis for MEG connectivity data, with "CV_only" methods.
# 				This application uses the same config file as connectivity_ml.sh, with unused items ignored.
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python
# Note: all sub scripts can assess the parent scope variables directly

# ------ variables ------
# load utils and zzz config file
start_t=`date +%s`
APP_NAME="cv_connectivity_ml.sh"
source ./zzz
source ./src/global_var
source ./src/legacy_help_var_class_conn
source ./src/utils
source ./scripts/legacy_sys_init_class_conn.sh

# -- dependency file id variables --
# file arrays
# bash scrit array use space to separate
R_SCRIPT_FILES=(r_dependency_check.R input_dat_process.R univariate.R cv_ml_svm.R cv_plsda_val_svm.R)

# ------ system check ------
source ./scripts/sys_check.sh

# ------ config loading ------
source ./scripts/config_init.sh

# ------ read input files ------
# -- input mat and annot files processing --
echo -e "--------------------- source script: input_dat_process.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/input_dat_process.R "$RAW_FILE" "$MAT_FILENAME_WO_EXT" \
"$ANNOT_FILE" "$SAMPLE_ID" "$GROUP_ID" \
"${OUT_DIR}/OUTPUT" \
"$minmax_norm" "$zscore_standardization" \
"$CONTRAST" \
--save 2>>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
group_summary=`echo "${r_var[@]}" | sed -n "1p"` # this also serves as a variable check variable. See the R script.
if [ "$group_summary" == "none_existent" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: -s or -g variables not found in the -a annotation file. Program terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$group_summary" == "unequal_length" ]; then
	echo -e "${COLOUR_RED}\nERROR: annotation file failed to match mat file sample length (third dimension value). Program terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$group_summary" == "na_values" ]; then
	echo -e "${COLOUR_RED}\nERROR: NAs found in the annotation file. Program terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$group_summary" == "single_value" ]; then
	echo -e "${COLOUR_RED}\nERROR: only single value detected in the outcome variable of the annotation file. Program terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$group_summary" == "contrast_none_existent" ]; then
	echo -e "${COLOUR_RED}\nERROR: contrast groups not matching input data groups. Program terminated.${NO_COLOUR}\n" >&2
	exit 1
fi
mat_dim=`echo "${r_var[@]}" | sed -n "2p"`  # pipe to sed to print the second line (i.e. 2p)

# -- display --
echo -e "\n"
echo -e "Input files"
echo -e "=========================================================================="
echo -e "Input data file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MAT_FILENAME${NO_COLOUR}"
echo -e "$mat_dim"
echo -e "\nSample metadata"
echo -e "\tFile name: ${COLOUR_GREEN_L}$ANNOT_FILENAME${NO_COLOUR}"
echo -e "$group_summary"
echo -e "\nNode data"
echo -e "\tFile name: ${COLOUR_GREEN_L}$NODE_FILENAME${NO_COLOUR}"
echo -e "\nData transformed into 2D format and saved to file: ${MAT_FILENAME_WO_EXT}_2D.csv"
echo -e "=========================================================================="

# -- set up variables for output 2d data file
dat_2d_file="${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_2D.csv"
# -- file check before next step --
if ! [ -f "$dat_2d_file" ]; then
	# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
	echo -e "${COLOUR_RED}\nERROR: File processing failed. Program terminated.${NO_COLOUR}\n" >&2
	# end time and display
	end_t=`date +%s`
	tot=`hms $((end_t-start_t))`
	echo -e "\n"
	echo -e "Total run time: $tot"
	echo -e "\n"
	exit 1  # exit 1: terminating with error
fi


# ------ univariant analysis ------
echo -e "\n"
echo -e "Unsupervised learning and univariate anlaysis"
echo -e "=========================================================================="
echo -e "Processing data file: ${COLOUR_GREEN_L}${MAT_FILENAME_WO_EXT}_2D.csv${NO_COLOUR}"
echo -en "Unsupervised learning and univariate anlaysis..."
echo -e "--------------------- source script: univariate.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/univariate.R "$dat_2d_file" "$MAT_FILENAME_WO_EXT" \
"$NODE_FILE" \
"${OUT_DIR}/OUTPUT" \
"$log2_trans" \
"$htmap_textsize_col" "$htmap_textangle_col" \
"$htmap_lab_row" "$htmap_textsize_row" \
"$htmap_keysize" "$htmap_key_xlab" "$htmap_key_ylab" \
"$htmap_margin" "$htmap_width" "$htmap_height" \
"$pca_scale_data" "$pca_centre_data" "$pca_pc" \
"$pca_biplot_samplelabel_type" "$pca_biplot_samplelabel_size" "$pca_biplot_symbol_size" \
"$pca_biplot_ellipse" "$pca_biplot_ellipse_conf" \
"$pca_biplot_loading" "$pca_biplot_loading_textsize" \
"$pca_biplot_multi_desity" "$pca_biplot_multi_striplabel_size" \
"$pca_rightside_y" "$pca_x_tick_label_size" "$pca_y_tick_label_size" \
"$pca_width" "$pca_height" \
"$CONTRAST" \
"$uni_fdr" "$uni_alpha" "$uni_fold_change" \
"$volcano_n_top_connection" "$volcano_symbol_size" "$volcano_sig_colour" "$volcano_nonsig_colour" \
"$volcano_x_text_size" "$volcano_y_text_size" "$volcano_width" "$volcano_height" \
"$sig_htmap_textsize_col" "$sig_htmap_textangle_col" "$sig_htmap_textsize_row" \
"$sig_htmap_keysize" "$sig_htmap_key_xlab" "$sig_htmap_key_ylab" \
"$sig_htmap_margin" "$sig_htmap_width" "$sig_htmap_height" \
"$sig_pca_pc" "$sig_pca_biplot_ellipse_conf" \
"$NODE_ID" "$REGION_NAME" \
"$uni_analysis" \
--save 2>>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log
node_check=`echo "${r_var[@]}" | sed -n "1p"` # this also serves as a variable check variable. See the R script.
rscript_display=`echo "${r_var[@]}"`
echo -e "Done!\n\n"

if [ "$node_check" == "none_existent" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: -d or -r variables not found in the -n node annotation file. Program terminated.${NO_COLOUR}\n\n" >&2
	# end time and display
	end_t=`date +%s`
	tot=`hms $((end_t-start_t))`
	echo -e "\n"
	echo -e "Total run time: $tot"
	echo -e "\n"
	exit 1
fi

echo -e "$rscript_display"  # print the screen display from the R script
# Below: producing Rplots.pdf is a ggsave() problem (to be fixed by the ggplot2 dev): temporary workaround
if [ -f "${OUT_DIR}"/OUTPUT/Rplots.pdf ]; then
	rm "${OUT_DIR}"/OUTPUT/Rplots.pdf
fi
# -- set up variables for output ml data file
echo -e "\n"
if [ $KFLAG -eq 1 ]; then
	dat_ml_file="${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_2D.csv"
else
	dat_ml_file="${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_w_prior.csv"
fi
# -- file check before next step --
if ! [ -f "$dat_ml_file" ]; then
	# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
	echo -e "${COLOUR_RED}\nERROR: Unsupervised analysis failed. Program terminated.${NO_COLOUR}\n" >&2
	# end time and display
	end_t=`date +%s`
	tot=`hms $((end_t-start_t))`
	echo -e "\n"
	echo -e "Total run time: $tot"
	echo -e "\n"
	exit 1  # exit 1: terminating with error
fi
# -- additional display --
echo -e "Data for machine learning w prior knowledge incorporation: ${MAT_FILENAME_WO_EXT}_w_prior.csv"
echo -e "Data for machine learning wo prior knowledge incorporation: ${MAT_FILENAME_WO_EXT}_2D.csv"
echo -e "=========================================================================="

# ------ SVM machine learning analysis ------
echo -e "\n"
echo -e "CV-rRF-FS-SVM machine learning"
echo -e "=========================================================================="
echo -en "Univariate prior knowledge incorporation: "
if [ $KFLAG -eq 1 ]; then
	echo -e "OFF"
	echo -e "Processing data file: ${COLOUR_GREEN_L}${MAT_FILENAME_WO_EXT}_2D.csv${NO_COLOUR}"
else
	echo -e "ON"
	echo -e "Processing data file: ${COLOUR_GREEN_L}${MAT_FILENAME_WO_EXT}_w_prior.csv${NO_COLOUR}"
fi
echo -en "Univariate reduction for CV-SVM-rRF-FS: "
if [ $UFLAG -eq 1 ]; then
	echo -e "OFF"
elsec
	echo -e "ON"
fi
echo -en "Parallel computing: "
if [ $PSETTING == "FALSE" ]; then
	echo -e "OFF"
else
	echo -e "ON"
	echo -e "Cores: $CORES (Set value. Max thread number minus one if exceeds the hardware config)"
fi
echo -en "CV-rRF-FS-SVM machine learning analysis..."
echo -e "--------------------- source script: cv_ml_svm.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/cv_ml_svm.R "$dat_ml_file" "$MAT_FILENAME_WO_EXT" \
"${OUT_DIR}/OUTPUT" \
"$PSETTING" "$CORES" \
"$cpu_cluster" "$training_percentage" \
"$svm_cv_centre_scale" "$svm_cv_kernel" "$svm_cv_cross_k" "$svm_cv_tune_method" "$svm_cv_tune_cross_k" "$svm_cv_tune_boot_n" \
"$svm_cv_fs_rf_ifs_ntree" "$svm_cv_fs_rf_sfs_ntree" "$svm_cv_best_model_method" "$svm_cv_fs_count_cutoff" \
"$svm_cross_k" "$svm_tune_cross_k" "$svm_tune_boot_n" \
"$svm_perm_method" "$svm_perm_n" \
"$svm_perm_plot_symbol_size" "$svm_perm_plot_legend_size" "$svm_perm_plot_x_label_size" "$svm_perm_plot_x_tick_label_size" \
"$svm_perm_plot_y_label_size" "$svm_perm_plot_y_tick_label_size" "$svm_perm_plot_width" "$svm_perm_plot_height" \
"$svm_roc_smooth" "$svm_roc_symbol_size" "$svm_roc_legend_size" "$svm_roc_x_label_size" "$svm_roc_x_tick_label_size" \
"$svm_roc_y_label_size" "$svm_roc_y_tick_label_size" "$svm_roc_width" "$svm_roc_height" \
"$pca_scale_data" "$pca_centre_data" \
"$pca_biplot_samplelabel_type" "$pca_biplot_samplelabel_size" "$pca_biplot_symbol_size" \
"$pca_biplot_ellipse" \
"$pca_biplot_loading" "$pca_biplot_loading_textsize" \
"$pca_biplot_multi_desity" "$pca_biplot_multi_striplabel_size" \
"$pca_rightside_y" "$pca_x_tick_label_size" "$pca_y_tick_label_size" \
"$pca_width" "$pca_height" \
"$svm_rffs_pca_pc" "$svm_rffs_pca_biplot_ellipse_conf" \
"$CVUNI" "$log2_trans" "$CONTRAST" "$uni_fdr" "$uni_alpha" \
"$rffs_htmap_textsize_col" "$rffs_htmap_textangle_col" "$htmap_lab_row" \
"$rffs_htmap_textsize_row" "$rffs_htmap_keysize" "$rffs_htmap_key_xlab" \
"$rffs_htmap_key_ylab" "$rffs_htmap_margin" "$rffs_htmap_width" "$rffs_htmap_height" \
"$random_state" \
--save 2>>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log
rscript_display=`echo "${r_var[@]}"`
# Below: producing Rplots.pdf is a ggsave() problem (to be fixed by the ggplot2 dev): temporary workaround
if [ -f "${OUT_DIR}"/OUTPUT/Rplots.pdf ]; then
	rm "${OUT_DIR}"/OUTPUT/Rplots.pdf
fi
# -- error handling --
if [ "$rscript_display" == "fs_failure" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: CV-rRF-FS-SVM failed. Program terminated. See ${NO_COLOUR}\n\n" >&2
	# end time and display
	end_t=`date +%s`
	tot=`hms $((end_t-start_t))`
	echo -e "\n"
	echo -e "Total run time: $tot"
	echo -e "\n"
	exit 1
fi
# -- set up variables for output svm model file --
svm_model_file="${OUT_DIR}/OUTPUT/cv_only_${MAT_FILENAME_WO_EXT}_final_svm_model.Rdata"
# -- file check before next step --
if ! [ -f "$svm_model_file" ]; then
	# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
	echo -e "${COLOUR_RED}\nERROR: SVM analysis failed. Program terminated.${NO_COLOUR}\n" >&2
	# end time and display
	end_t=`date +%s`
	tot=`hms $((end_t-start_t))`
	echo -e "\n"
	echo -e "Total run time: $tot"
	echo -e "\n"
	exit 1  # exit 1: terminating with error
fi
echo -e "Done!"
echo -e "SVM analysis results saved to file: cv_only_${MAT_FILENAME_WO_EXT}_svm_results.txt\n\n"
echo -e "$rscript_display" # print the screen display from the R script
echo -e "=========================================================================="

# ------ PLS-DA machine learning analysis ------
echo -e "\n"
echo -e "PLS-DA machine learning for SVM results evaluation"
echo -e "=========================================================================="
echo -e "SVM model file: ${COLOUR_GREEN_L}cv_only_${MAT_FILENAME_WO_EXT}_final_svm_model.Rdata${NO_COLOUR}"
echo -en "Parallel computing: "
if [ $PSETTING == "FALSE" ]; then
	echo -e "OFF"
else
	echo -e "ON"
	echo -e "Cores: $CORES"
fi
echo -en "PLS-DA analysis..."
echo -e "--------------------- source script: cv_plsda_val_svm.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/cv_plsda_val_svm.R "$svm_model_file" "$MAT_FILENAME_WO_EXT" \
"${OUT_DIR}/OUTPUT" \
"$PSETTING" "$CORES" \
"$cpu_cluster" \
"$plsda_validation" "$plsda_validation_segment" "$plsda_init_ncomp" "$plsda_ncomp_select_method" \
"$plsda_ncomp_select_plot_symbol_size" "$plsda_ncomp_select_plot_legend_size" \
"$plsda_ncomp_select_plot_x_label_size" "$plsda_ncomp_select_plot_x_tick_label_size" \
"$plsda_ncomp_select_plot_y_label_size" "$plsda_ncomp_select_plot_y_tick_label_size" \
"$plsda_perm_method" "$plsda_perm_n" \
"$plsda_perm_plot_symbol_size" "$plsda_perm_plot_legend_size" \
"$plsda_perm_plot_x_label_size" "$plsda_perm_plot_x_tick_label_size" \
"$plsda_perm_plot_y_label_size" "$plsda_perm_plot_y_tick_label_size" \
"$plsda_perm_plot_width" "$plsda_perm_plot_height" \
"$plsda_scoreplot_ellipse_conf" \
"$pca_biplot_symbol_size" \
"$pca_biplot_ellipse" \
"$pca_biplot_multi_desity" "$pca_biplot_multi_striplabel_size" \
"$pca_rightside_y" "$pca_x_tick_label_size" "$pca_y_tick_label_size" \
"$pca_width" "$pca_height" \
"$plsda_roc_smooth" \
"$svm_roc_symbol_size" "$svm_roc_legend_size" "$svm_roc_x_label_size" "$svm_roc_x_tick_label_size" \
"$svm_roc_y_label_size" "$svm_roc_y_tick_label_size" \
"$plsda_vip_alpha" "$plsda_vip_boot" "$plsda_vip_boot_n" \
"$plsda_vip_plot_errorbar" "$plsda_vip_plot_errorbar_width" "$plsda_vip_plot_errorbar_label_size" \
"$plsda_vip_plot_x_textangle" "$plsda_vip_plot_x_label_size" "$plsda_vip_plot_x_tick_label_size" \
"$plsda_vip_plot_y_label_size" "$plsda_vip_plot_y_tick_label_size" \
"$plsda_vip_plot_width" "$plsda_vip_plot_height" \
"$random_state" \
--save 2>>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/LOG/processing_shell_log_$CURRENT_DAY.log
rscript_display=`echo "${r_var[@]}"`
# Below: producing Rplots.pdf is a ggsave() problem (to be fixed by the ggplot2 dev): temporary workaround
if [ -f "${OUT_DIR}"/OUTPUT/Rplots.pdf ]; then
	rm "${OUT_DIR}"/OUTPUT/Rplots.pdf
fi
echo -e "Done!"
echo -e "Additional PLS-DA analysis results saved to file: ${MAT_FILENAME_WO_EXT}_plsda_results.txt\n\n"
echo -e "$rscript_display" # print the screen display from the R script
echo -e "=========================================================================="


# end time and display
end_t=`date +%s`
tot=`hms $((end_t-start_t))`
echo -e "\n"
echo -e "Total run time: $tot"
echo -e "\n"
