#!/usr/bin/env bash
# Name: predict_class.sh
# Description: Predict group label for new data using model generated from train_class.sh.
# Usage: TBD
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# load utils and zzz config file
start_t=`date +%s`
APP_NAME="predict_class.sh"
source ./zzz
source ./src/global_var
source ./src/help_var_pred_class_2d
source ./src/utils
source ./scripts/sys_init_pred_class_2d.sh

# -- dependency file id variables --
# file arrays
# bash scrit array use space to separate
R_SCRIPT_FILES=(r_dependency_check.R pred_dat_process_2d.R pred_classif.R)


# ------ system check ------
source ./scripts/sys_check.sh


# ------ config loading ------
source ./scripts/pred_config_init.sh


# ------ input 2d files processing ------
echo -e "--------------------- source script: pred_dat_process_2d.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/pred_dat_process_2d.R "$RAW_FILE" "$MAT_FILENAME_WO_EXT" \
"$SAMPLE_ID" \
"${OUT_DIR}/PREDICTION" \
"$MODEL_FILE" \
--save 2>>"${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
if [ "$nsamples_to_pred" == "none_existent" ]; then  # use "$group_summary" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: -s or variable not found in the annotation information. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
elif [ "$nsamples_to_pred" == "unequal_length" ]; then
	echo -e "${COLOUR_RED}\nERROR: annotation information not matching -i input file sample length. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
fi
nsamples_to_pred=`echo "${r_var[@]}" | sed -n "1p"`

# -- check file and display --
echo -e "\n"
echo -e "Input file"
echo -e "=========================================================================="
echo -e "Input data file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MAT_FILENAME${NO_COLOUR}"
echo -e "\n\tData transformed into 2D format and saved to file: ${MAT_FILENAME_WO_EXT}_2D.csv"
dat_2d_file="${OUT_DIR}/PREDICTION/${MAT_FILENAME_WO_EXT}_2D.csv"
check_file "$dat_2d_file" "2D data file"
echo -e "\nSample annotation"
echo -e "$nsamples_to_pred"
echo -e "=========================================================================="


# ------ Inferencing ------
echo -e "\n"
echo -e "SVM prediction"
echo -e "=========================================================================="
echo -e "Input model file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MODEL_FILENAME${NO_COLOUR}"
echo -en "\nSVM predicting...\n"
echo -e "--------------------- source script: pred_classif.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/pred_classif.R "$dat_2d_file" "$MODEL_FILE" \
"${OUT_DIR}/PREDICTION" \
"$newdata_centre_scale" "$probability_method" \
"$PSETTING" "$CORES" "$cpu_cluster" \
"$pie_width" "$pie_height" \
--save 2>>"${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log \
| tee -a "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log`
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_R_log_$CURRENT_DAY.log
echo -e "\n" >> "${OUT_DIR}"/PREDICTION_LOG/processing_shell_log_$CURRENT_DAY.log  # add one blank lines to the log files
sampleid_pred=`echo "${r_var[@]}" | sed -n "1p"`  # pipe to sed to print the second line (i.e. 1p)
# Below: producing Rplots.pdf is a ggsave() problem (to be fixed by the ggplot2 dev): temporary workaround
if [ -f "${OUT_DIR}"/PREDICTION/Rplots.pdf ]; then
	rm "${OUT_DIR}"/PREDICTION/Rplots.pdf
fi
# echo -e "\nFeature subset according to model"
if [ "$sampleid_pred" == "feature_error" ]; then  # use "$sampleid_pred" (quotations) to avid "too many arguments" error
	echo -e "${COLOUR_RED}\nERROR: Feature mismatch between input data and model. Progream terminated.${NO_COLOUR}\n" >&2
	exit 1
fi
echo -e "\tData with feature subset and saved to file: data_subset.csv"
# echo -e "\nSVM predicted sample IDs:"
# echo -e "\t$sampleid_pred"
echo -e "\tPie charts depicting resutls saved to the ${COLOUR_GREEN_L}PREDICTION${NO_COLOUR} folder in the output directory."
echo -e "=========================================================================="


# ------ end time and display ------
end_t=`date +%s`
tot=`hms $((end_t-start_t))`
echo -e "\n"
echo -e "Total run time: $tot"
echo -e "\n"