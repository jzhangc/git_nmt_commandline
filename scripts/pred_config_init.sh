#!/usr/bin/env bash
# Name: pred_config_init.sh
# Description: Initialize config file
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python
# Note: all sub scripts can assess the parent scope variables directly

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


# ------ message display ------
if [[ $minmax_norm == TRUE && $zscore_standardization == TRUE ]]; then
	echo -e "${COLOUR_YELLOW}\nWARNING: minmax_norm=TRUE, zscore_standardization=TRUE: equivalent to zscore_standardization=TRUE only. ${NO_COLOUR}\n" >&2
fi