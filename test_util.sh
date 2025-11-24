#!/usr/bin/env bash
# Name: train_class.sh
# Discription: A generalized version of connectivity_ml.sh that takes 2D data table, instead of functional connectivity 3D mat adjacency matrices. 
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# --- config file and variables ---
echo -e "\n"
echo -e "Config file: ${COLOUR_GREEN_L}$CONFIG_FILENAME${NO_COLOUR}"
echo -e "=========================================================================="
# load application variables from config file; or set their default settings if no config file
if [ $CONF_CHECK -eq 0 ]; then  # variables read from the configeration file
  source "$CONFIG_FILE"
  ## below: to check the completeness of the file: the variables will only load if all the variables are present
  # -z tests if the variable has zero length. returns True if zero.
  # v1, v2, etc are placeholders for now
  if [[ -z $random_state || -z $log2_trans || -z $uni_analysis || -z $htmap_textsize_col || -z $htmap_textangle_col || -z $htmap_lab_row \
	|| -z $htmap_textsize_row || -z $htmap_keysize || -z $htmap_key_xlab || -z $htmap_key_ylab || -z $htmap_margin \
	|| -z $htmap_width || -z $htmap_height || -z $pca_scale_data || -z $pca_centre_data || -z $pca_pc \
	|| -z $pca_biplot_samplelabel_type || -z $pca_biplot_samplelabel_size || -z $pca_biplot_symbol_size \
	|| -z $pca_biplot_ellipse || -z $pca_biplot_ellipse_conf || -z $pca_biplot_loading || -z $pca_biplot_loading_textsize \
	|| -z $pca_biplot_multi_desity || -z $pca_biplot_multi_striplabel_size || -z $pca_rightside_y || -z $pca_x_tick_label_size \
	|| -z $pca_y_tick_label_size || -z $pca_width || -z $pca_height || -z $uni_fdr || -z $uni_alpha || -z $uni_fold_change \
	|| -z $volcano_n_top_connection || -z $volcano_symbol_size || -z $volcano_sig_colour || -z $volcano_nonsig_colour \
	|| -z $volcano_x_text_size || -z $volcano_y_text_size || -z $volcano_width || -z $volcano_height \
	|| -z $sig_htmap_textsize_col || -z $sig_htmap_textangle_col || -z $sig_htmap_textsize_row || -z $sig_htmap_keysize \
	|| -z $sig_htmap_key_xlab || -z $sig_htmap_key_ylab || -z $sig_htmap_margin || -z $sig_htmap_width \
	|| -z $sig_htmap_height || -z $sig_pca_pc || -z $sig_pca_biplot_ellipse_conf || -z $cpu_cluster || -z $training_percentage \
	|| -z $svm_cv_centre_scale || -z $svm_cv_kernel || -z $svm_cv_cross_k || -z $svm_cv_tune_method || -z $svm_cv_tune_cross_k \
	|| -z $svm_cv_tune_boot_n || -z $svm_cv_fs_rf_ifs_ntree || -z $svm_cv_fs_rf_sfs_ntree || -z $svm_cv_best_model_method || -z $svm_cv_fs_count_cutoff \
	|| -z $svm_cross_k || -z $svm_tune_cross_k || -z $svm_tune_boot_n || -z $svm_perm_method || -z $svm_perm_n \
	|| -z $svm_perm_plot_symbol_size || -z $svm_perm_plot_legend_size || -z $svm_perm_plot_x_label_size \
	|| -z $svm_perm_plot_x_tick_label_size || -z $svm_perm_plot_y_label_size || -z $svm_perm_plot_y_tick_label_size \
	|| -z $svm_perm_plot_width || -z $svm_perm_plot_height || -z $svm_roc_smooth || -z $svm_roc_symbol_size \
	|| -z $svm_roc_legend_size || -z $svm_roc_x_label_size || -z $svm_roc_x_tick_label_size || -z $svm_roc_y_label_size \
	|| -z $svm_roc_y_tick_label_size || -z $svm_roc_width || -z $svm_roc_height || -z $svm_rffs_pca_pc \
	|| -z $svm_rffs_pca_biplot_ellipse_conf || -z $rffs_htmap_textsize_col || -z $rffs_htmap_textangle_col \
	|| -z $rffs_htmap_textsize_row || -z $rffs_htmap_keysize || -z $rffs_htmap_key_xlab || -z $rffs_htmap_key_ylab \
	|| -z $rffs_htmap_margin || -z $rffs_htmap_width || -z $rffs_htmap_height \
	|| -z $plsda_validation || -z $plsda_validation_segment || -z $plsda_init_ncomp \
	|| -z $plsda_ncomp_select_method || -z $plsda_ncomp_select_plot_symbol_size || -z $plsda_ncomp_select_plot_legend_size \
	|| -z $plsda_ncomp_select_plot_x_label_size || -z $plsda_ncomp_select_plot_x_tick_label_size \
	|| -z $plsda_ncomp_select_plot_y_label_size || -z $plsda_ncomp_select_plot_y_tick_label_size || -z $plsda_perm_method \
	|| -z $plsda_perm_n || -z $plsda_perm_plot_symbol_size || -z $plsda_perm_plot_legend_size \
	|| -z $plsda_perm_plot_x_label_size || -z $plsda_perm_plot_x_tick_label_size || -z $plsda_perm_plot_y_label_size \
	|| -z $plsda_perm_plot_y_tick_label_size || -z $plsda_perm_plot_width || -z $plsda_perm_plot_height \
	|| -z $plsda_scoreplot_ellipse_conf || -z $plsda_roc_smooth || -z $plsda_vip_alpha || -z $plsda_vip_boot \
	|| -z $plsda_vip_boot_n || -z $plsda_vip_plot_errorbar || -z $plsda_vip_plot_errorbar_width \
	|| -z $plsda_vip_plot_errorbar_label_size || -z $plsda_vip_plot_x_textangle|| -z $plsda_vip_plot_x_label_size \
	|| -z $plsda_vip_plot_x_tick_label_size || -z $plsda_vip_plot_y_label_size || -z $plsda_vip_plot_y_tick_label_size \
	|| -z $plsda_vip_plot_width || -z $plsda_vip_plot_height ]]; then
    echo -e "${COLOUR_YELLOW}WARNING: Config file detected. But one or more vairables missing.${NO_COLOUR}"
    CONF_CHECK=1
  else
    echo -e "Config file detected and loaded."
  fi
fi

if [ $CONF_CHECK -eq 1 ]; then
  echo -e "Config file not found or loaded. Proceed with default settings."
  # set the values back to default
  	random_state=0
	log2_trans=FALSE
	uni_analysis=FALSE
	htmap_textsize_col=0.5
	htmap_textangle_col=90
	htmap_lab_row=FALSE
	htmap_textsize_row=0.2
	htmap_keysize=1.5
	htmap_key_xlab="Normalized connectivity value"
	htmap_key_ylab="Pair count"
	htmap_margin="c(4, 5)"
	htmap_width=6
	htmap_height=5
	pca_scale_data=TRUE
	pca_centre_data=TRUE
	pca_pc="c(1, 2)"
	pca_biplot_samplelabel_type="none"
	pca_biplot_samplelabel_size=2
	pca_biplot_symbol_size=5
	pca_biplot_ellipse=TRUE
	pca_biplot_ellipse_conf=0.95
	pca_biplot_loading=FALSE
	pca_biplot_loading_textsize=3
	pca_biplot_multi_desity=TRUE
	pca_biplot_multi_striplabel_size=10
	pca_rightside_y=FALSE
	pca_x_tick_label_size=10
	pca_y_tick_label_size=10
	pca_width=170
	pca_height=150
	uni_fdr=TRUE
	uni_alpha=0.05
	uni_fold_change=1
	volcano_n_top_connection=10
	volcano_symbol_size=2
	volcano_sig_colour="red"
	volcano_nonsig_colour="gray"
	volcano_x_text_size=10
	volcano_y_text_size=10
	volcano_width=170
	volcano_height=150
	sig_htmap_textsize_col=0.5
	sig_htmap_textangle_col=90
	sig_htmap_textsize_row=0.5
	sig_htmap_keysize=1.5
	sig_htmap_key_xlab="Z score"
	sig_htmap_key_ylab="Count"
	sig_htmap_margin="c(4, 8)"
	sig_htmap_width=6
	sig_htmap_height=5
	sig_pca_pc="c(1, 2)"
	sig_pca_biplot_ellipse_conf=0.9
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
	svm_cv_best_model_method="none"
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
	svm_perm_plot_width=170
	svm_perm_plot_height=150
	svm_roc_smooth=FALSE
	svm_roc_symbol_size=2
	svm_roc_legend_size=9
	svm_roc_x_label_size=10
	svm_roc_x_tick_label_size=10
	svm_roc_y_label_size=10
	svm_roc_y_tick_label_size=10
	svm_roc_width=170
	svm_roc_height=150
	svm_rffs_pca_pc="c(1, 2)"
	svm_rffs_pca_biplot_ellipse_conf=0.95
	rffs_htmap_textsize_col=0.5
	rffs_htmap_textangle_col=90
	rffs_htmap_textsize_row=0.5
	rffs_htmap_keysize=1.5
	rffs_htmap_key_xlab="Z score"
	rffs_htmap_key_ylab="Count"
	rffs_htmap_margin="c(3, 9)"
	rffs_htmap_width=6
	rffs_htmap_height=5
	plsda_validation="CV"
	plsda_validation_segment=10
	plsda_init_ncomp=10
	plsda_ncomp_select_method="1err"
	plsda_ncomp_select_plot_symbol_size=2
	plsda_ncomp_select_plot_legend_size=9
	plsda_ncomp_select_plot_x_label_size=10
	plsda_ncomp_select_plot_x_tick_label_size=10
	plsda_ncomp_select_plot_y_label_size=10
	plsda_ncomp_select_plot_y_tick_label_size=10
	plsda_perm_method="by_y"
	plsda_perm_n=999
	plsda_perm_plot_symbol_size=2
	plsda_perm_plot_legend_size=9
	plsda_perm_plot_x_label_size=10
	plsda_perm_plot_x_tick_label_size=10
	plsda_perm_plot_y_label_size=10
	plsda_perm_plot_y_tick_label_size=10
	plsda_perm_plot_width=170
	plsda_perm_plot_height=150
	plsda_scoreplot_ellipse_conf=0.9  # the other scoreplot settings are the same as the all connections PCA biplot
	plsda_roc_smooth=FALSE
	plsda_vip_alpha=0.8  # 0.8~1 is good
	plsda_vip_boot=TRUE
	plsda_vip_boot_n=50
	plsda_vip_plot_errorbar="SEM"  # options are "SEM" and "SD"
	plsda_vip_plot_errorbar_width=0.2
	plsda_vip_plot_errorbar_label_size=6
	plsda_vip_plot_x_textangle=90
	plsda_vip_plot_x_label_size=10
	plsda_vip_plot_x_tick_label_size=10
	plsda_vip_plot_y_label_size=10
	plsda_vip_plot_y_tick_label_size=10
	plsda_vip_plot_width=170
	plsda_vip_plot_height=150
fi
# below: display the (loaded) variables and their values
echo -e "\n"
# echo -e "-------------------------------------"
if [ $CONF_CHECK -eq 1 ]; then
  echo -e "Variables set:"
else
  echo -e "Variables loaded from the config file:"
fi
# below: place loaders
echo -e "Random state (0=FALSE)"
echo -e "\trandom_state=$random_state"
echo -e "\nData processing"
echo -e "\tlog2_trans=$log2_trans"
echo -e "\tunianalysis=$uni_analysis"
echo -e "\nClustering analysis for all connections"
echo -e "\thtmap_textsize_col=$htmap_textsize_col"
echo -e "\thtmap_textangle_col=$htmap_textangle_col"
echo -e "\thtmap_lab_row=$htmap_lab_row"
echo -e "\thtmap_textsize_row=$htmap_textsize_row"
echo -e "\thtmap_keysize=$htmap_keysize"
echo -e "\thtmap_key_xlab=$htmap_key_xlab"
echo -e "\thtmap_key_ylab=$htmap_key_ylab"
echo -e "\thtmap_margin=$htmap_margin"
echo -e "\thtmap_width=$htmap_width"
echo -e "\thtmap_height=$htmap_height"
echo -e "\tpca_scale_data=$pca_scale_data"
echo -e "\tpca_centre_data=$pca_centre_data"
echo -e "\tpca_pc=$pca_pc"
echo -e "\tpca_biplot_samplelabel_type=$pca_biplot_samplelabel_type"
echo -e "\tpca_biplot_samplelabel_size=$pca_biplot_samplelabel_size"
echo -e "\tpca_biplot_symbol_size=$pca_biplot_symbol_size"
echo -e "\tpca_biplot_ellipse=$pca_biplot_ellipse"
echo -e "\tpca_biplot_ellipse_conf=$pca_biplot_ellipse_conf"
echo -e "\tpca_biplot_loading=$pca_biplot_loading"
echo -e "\tpca_biplot_loading_textsize=$pca_biplot_loading_textsize"
echo -e "\tpca_biplot_multi_desity=$pca_biplot_multi_desity"
echo -e "\tpca_biplot_multi_striplabel_size=$pca_biplot_multi_striplabel_size"
echo -e "\tpca_rightside_y=$pca_rightside_y"
echo -e "\tpca_x_tick_label_size=$pca_x_tick_label_size"
echo -e "\tpca_y_tick_label_size=$pca_y_tick_label_size"
echo -e "\tpca_width=$pca_width"
echo -e "\tpca_height=$pca_height"
echo -e "\nUnivariate analysis"
echo -e "\tuni_fdr=$uni_fdr"
echo -e "\tuni_alpha=$uni_alpha"
echo -e "\tuni_fold_change=$uni_fold_change"
echo -e "\tvolcano_n_top_connection=$volcano_n_top_connection"
echo -e "\tvolcano_symbol_size=$volcano_symbol_size"
echo -e "\tvolcano_sig_colour=$volcano_sig_colour"
echo -e "\tvolcano_nonsig_colour=$volcano_nonsig_colour"
echo -e "\tvolcano_x_text_size=$volcano_x_text_size"
echo -e "\tvolcano_y_text_size=$volcano_y_text_size"
echo -e "\tvolcano_width=$volcano_width"
echo -e "\tvolcano_height=$volcano_height"
echo -e "\nClustering analysis for significant connections"
echo -e "\tsig_htmap_textsize_col=$sig_htmap_textsize_col"
echo -e "\tsig_htmap_textangle_col=$sig_htmap_textangle_col"
echo -e "\tsig_htmap_textsize_row=$sig_htmap_textsize_row"
echo -e "\tsig_htmap_keysize=$sig_htmap_keysize"
echo -e "\tsig_htmap_key_xlab=$sig_htmap_key_xlab"
echo -e "\tsig_htmap_key_ylab=$sig_htmap_key_ylab"
echo -e "\tsig_htmap_margin=$sig_htmap_margin"
echo -e "\tsig_htmap_width=$sig_htmap_width"
echo -e "\tsig_htmap_height=$sig_htmap_height"
echo -e "\tsig_pca_pc=$sig_pca_pc"
echo -e "\tsig_pca_biplot_ellipse_conf=$sig_pca_biplot_ellipse_conf"
echo -e "\nMachine learning analysis"
echo -e "\tcpu_cluster=$cpu_cluster"
echo -e "\ttraining_percentage=$training_percentage"
echo -e "\tsvm_cv_centre_scale=$svm_cv_centre_scale"
echo -e "\tsvm_cv_kernel=$svm_cv_kernel"
echo -e "\tsvm_cv_cross_k=$svm_cv_cross_k"
echo -e "\tsvm_cv_tune_method=$svm_cv_tune_method"
echo -e "\tsvm_cv_tune_cross_k=$svm_cv_tune_cross_k"
echo -e "\tsvm_cv_tune_boot_n=$svm_cv_tune_boot_n"
echo -e "\tsvm_cv_fs_rf_ifs_ntree=$svm_cv_fs_rf_ifs_ntree"
echo -e "\tsvm_cv_fs_rf_sfs_ntree=$svm_cv_fs_rf_sfs_ntree"
echo -e "\tsvm_cv_best_model_method=$svm_cv_best_model_method"
echo -e "\tsvm_cv_fs_count_cutoff=$svm_cv_fs_count_cutoff"
echo -e "\tsvm_cross_k=$svm_cross_k"
echo -e "\tsvm_tune_cross_k=$svm_tune_cross_k"
echo -e "\tsvm_tune_boot_n=$svm_tune_boot_n"
echo -e "\tsvm_perm_method=$svm_perm_method"
echo -e "\tsvm_perm_n=$svm_perm_n"
echo -e "\tsvm_perm_plot_symbol_size=$svm_perm_plot_symbol_size"
echo -e "\tsvm_perm_plot_legend_size=$svm_perm_plot_legend_size"
echo -e "\tsvm_perm_plot_x_label_size=$svm_perm_plot_x_label_size"
echo -e "\tsvm_perm_plot_x_tick_label_size=$svm_perm_plot_x_tick_label_size"
echo -e "\tsvm_perm_plot_y_label_size=$svm_perm_plot_y_label_size"
echo -e "\tsvm_perm_plot_y_tick_label_size=$svm_perm_plot_y_tick_label_size"
echo -e "\tsvm_perm_plot_width=$svm_perm_plot_width"
echo -e "\tsvm_perm_plot_height=$svm_perm_plot_height"
echo -e "\tsvm_roc_smooth=$svm_roc_smooth"
echo -e "\tsvm_roc_symbol_size=$svm_roc_symbol_size"
echo -e "\tsvm_roc_legend_size=$svm_roc_legend_size"
echo -e "\tsvm_roc_x_label_size=$svm_roc_x_label_size"
echo -e "\tsvm_roc_x_tick_label_size=$svm_roc_x_tick_label_size"
echo -e "\tsvm_roc_y_label_size=$svm_roc_y_label_size"
echo -e "\tsvm_roc_y_tick_label_size=$svm_roc_y_tick_label_size"
echo -e "\tsvm_roc_width=$svm_roc_width"
echo -e "\tsvm_roc_height=$svm_roc_height"
echo -e "\tsvm_rffs_pca_pc=$svm_rffs_pca_pc"
echo -e "\tsvm_rffs_pca_biplot_ellipse_conf=$svm_rffs_pca_biplot_ellipse_conf"
echo -e "\trffs_htmap_textsize_col=$rffs_htmap_textsize_col"
echo -e "\trffs_htmap_textangle_col=$rffs_htmap_textangle_col"
echo -e "\trffs_htmap_textsize_row=$rffs_htmap_textsize_row"
echo -e "\trffs_htmap_keysize=$rffs_htmap_keysize"
echo -e "\trffs_htmap_key_xlab=$rffs_htmap_key_xlab"
echo -e "\trffs_htmap_key_ylab=$rffs_htmap_key_ylab"
echo -e "\trffs_htmap_margin=$rffs_htmap_margin"
echo -e "\trffs_htmap_width=$rffs_htmap_width"
echo -e "\trffs_htmap_height=$rffs_htmap_height"
echo -e "\nPLS-DA modelling for evaluating SVM results"
echo -e "\tplsda_validation=$plsda_validation"
echo -e "\tplsda_validation_segment=$plsda_validation_segment"
echo -e "\tplsda_init_ncomp=$plsda_init_ncomp"
echo -e "\tplsda_ncomp_select_method=$plsda_ncomp_select_method"
echo -e "\tplsda_ncomp_select_plot_symbol_size=$plsda_ncomp_select_plot_symbol_size"
echo -e "\tplsda_ncomp_select_plot_legend_size=$plsda_ncomp_select_plot_legend_size"
echo -e "\tplsda_ncomp_select_plot_x_label_size=$plsda_ncomp_select_plot_x_label_size"
echo -e "\tplsda_ncomp_select_plot_x_tick_label_size=$plsda_ncomp_select_plot_x_tick_label_size"
echo -e "\tplsda_ncomp_select_plot_y_label_size=$plsda_ncomp_select_plot_y_label_size"
echo -e "\tplsda_ncomp_select_plot_y_tick_label_size=$plsda_ncomp_select_plot_y_tick_label_size"
echo -e "\tplsda_perm_method=$plsda_perm_method"
echo -e "\tplsda_perm_n=$plsda_perm_n"
echo -e "\tplsda_perm_plot_symbol_size=$plsda_perm_plot_symbol_size"
echo -e "\tplsda_perm_plot_legend_size=$plsda_perm_plot_legend_size"
echo -e "\tplsda_perm_plot_x_label_size=$plsda_perm_plot_x_label_size"
echo -e "\tplsda_perm_plot_x_tick_label_size=$plsda_perm_plot_x_tick_label_size"
echo -e "\tplsda_perm_plot_y_label_size=$plsda_perm_plot_y_label_size"
echo -e "\tplsda_perm_plot_y_tick_label_size=$plsda_perm_plot_y_tick_label_size"
echo -e "\tplsda_perm_plot_width=$plsda_perm_plot_width"
echo -e "\tplsda_perm_plot_height=$plsda_perm_plot_height"
echo -e "\tplsda_scoreplot_ellipse_conf=$plsda_scoreplot_ellipse_conf"
echo -e "\tplsda_vip_alpha=$plsda_vip_alpha"
echo -e "\tplsda_vip_boot=$plsda_vip_boot"
echo -e "\tplsda_vip_boot_n=$plsda_vip_boot_n"
echo -e "\tplsda_vip_plot_errorbar=$plsda_vip_plot_errorbar"
echo -e "\tplsda_vip_plot_errorbar_width=$plsda_vip_plot_errorbar_width"
echo -e "\tplsda_vip_plot_errorbar_label_size=$plsda_vip_plot_errorbar_label_size"
echo -e "\tplsda_vip_plot_x_textangle=$plsda_vip_plot_x_textangle"
echo -e "\tplsda_vip_plot_x_label_size=$plsda_vip_plot_x_label_size"
echo -e "\tplsda_vip_plot_x_tick_label_size=$plsda_vip_plot_x_tick_label_size"
echo -e "\tplsda_vip_plot_y_label_size=$plsda_vip_plot_y_label_size"
echo -e "\tplsda_vip_plot_y_tick_label_size=$plsda_vip_plot_y_tick_label_size"
echo -e "\tplsda_vip_plot_width=$plsda_vip_plot_width"
echo -e "\tplsda_vip_plot_height=$plsda_vip_plot_height"
echo -e "=========================================================================="