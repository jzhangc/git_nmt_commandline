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
source ./src/help_var_pred_class_2d_x
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


# --- config file and variables ---
echo -e "\n"
echo -e "Config file: ${COLOUR_GREEN_L}$CONFIG_FILENAME${NO_COLOUR}"
echo -e "=========================================================================="
# load application variables from config file; or set their default settings if no config file
if [ $CONF_CHECK -eq 0 ]; then  # variables read from the configeration file
  #source connectivity_ml_config
  source "$CONFIG_FILE"
  ## below: to check the completeness of the file: the variables will only load if all the variables are present
  # -z tests if the variable has zero length. returns True if zero.
  # v1, v2, etc are placeholders for now
  if [[ -z $newdata_centre_scale || -z $probability_method \
	|| -z $cpu_cluster \
	|| -z $pie_width || -z $pie_height ]]; then
    echo -e "${COLOUR_YELLOW}WARNING: Config file detected. But one or more vairables missing.${NO_COLOUR}"
    CONF_CHECK=1
  else
    echo -e "Config file detected and loaded."
  fi
fi

if [ $CONF_CHECK -eq 1 ]; then
  echo -e "Config file not found or loaded. Proceed with default settings."
  # set the values back to default
	cpu_cluster="PSOCK"
	newdata_centre_scale=TRUE
	probability_method="softmax"
	pie_width=170
	pie_height=150
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
echo -e "Parallel computering"
echo -e "\tcpu_cluster=$cpu_cluster"
echo -e "\nSettings for SVM prediction"
echo -e "\tnewdata_centre_scale=$newdata_centre_scale"
echo -e "\tprobability_method=$probability_method"
echo -e "\nFigure settings"
echo -e "\tpie_width=$pie_width"
echo -e "\tpie_height=$pie_height"
echo -e "=========================================================================="


# ------ input 2d files processing ------
echo -e "--------------------- source script: pred_dat_process_2d.R ---------------------\n" >>"${OUT_DIR}"/LOG/processing_R_log_$CURRENT_DAY.log
r_var=`Rscript ./R_files/pred_dat_process_2d.R "$RAW_FILE" "$MAT_FILENAME_WO_EXT" \
"$SAMPLE_ID" \
"${OUT_DIR}/PREDICTION" \
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

# -- display --
echo -e "\n"
echo -e "Input file"
echo -e "=========================================================================="
echo -e "Input data file"
echo -e "\tFile name: ${COLOUR_GREEN_L}$MAT_FILENAME${NO_COLOUR}"
echo -e "\n\tData transformed into 2D format and saved to file: ${MAT_FILENAME_WO_EXT}_2D.csv"
echo -e "\nSample annotation"
echo -e "$nsamples_to_pred"
echo -e "=========================================================================="

# -- set up variables for output 2d data file
dat_2d_file="${OUT_DIR}/PREDICTION/${MAT_FILENAME_WO_EXT}_2D.csv"
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