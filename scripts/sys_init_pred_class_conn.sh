#!/usr/bin/env bash
# File name: sys_init_pred_class_2d.sh
# Description: Initiate predict-classification workflows (2D-data-based)
# Usage: source scripts/sys_init_pred_class_2d.sh
# Note:
#   This is designed to initialize 2D-data-based predictive classification workflows, including:
#     1. Predict classes using pre-generated models, i.e., ./predict_class.sh
#     2. Generate cross-validated predictions from trained data: TDB
#
# This file can/can't be executed directly, because missing functions are provided via src/utils or connectivity_ml_config.

# ------ variable ------
# mandatory variable check: start as unset. Will be set later.
# -- initiate mandatory variable check variables. initial value 1 (false) --
CONF_CHECK=1

# ---- flag settings and flag variables (to be checked) ---
POSITIONAL=()                        # positional arguments after flag parsing
PSETTING=FALSE                       # parallel setting, TRUE when cores>1 (passed to R)
CORES=1                              # CPU cores for parallel operations

IFLAG=1                               # mandatory flag
SFLAG=1                               # mandatory flag
BFLAG=1                               # mandatory flag

# optional flag values
OUT_DIR=.                             # default: current directory


# ------ set flag variable from command flags ------
if [ $# -eq 0 ]; then
	# echo -e $HELP
	# echo -e "\n"
	# echo -e "=========================================================================="
	# echo -e "${COLOUR_YELLOW}$CITE${NO_COLOUR}\n"
	# exit 0  # exit 0: terminating without error. FYI exit 1 - exit with error, exit 2 - exit with message
	source ./scripts/trigger_help_info.sh
else
	case "$1" in  # "one off" flags
		-h|--help)
			# echo -e $HELP
			# echo -e "\n"
			# echo -e "=========================================================================="
			# echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
			# exit 0
			source ./scripts/trigger_help_info.sh
			;;
		-v|--version)
			echo -e "Current version: $VERSION\n"
			exit 0
			;;
	esac

	# --- initial message ---
	echo -e "\nYou are running ${COLOUR_BLUE_L}$APP_NAME${NO_COLOUR}"
	echo -e "Version: $VERSION"
	echo -e "Current OS: $PLATFORM"
	echo -e "Today is: $CURRENT_DAY\n"
	echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
	
	while getopts ":p:i:a:s:b:m:o:" opt; do
		case $opt in
			p)
				PSETTING=TRUE  # note: PSETTING is to be passed to R. therefore a separate variable is used
				CORES=$OPTARG
				;;
			i)
				# if [[ $OPTARG == *"~"* ]]; then
				#     RAW_FILE=$(expand_path $OPTARG)
				# else
				#     RAW_FILE=$(get_abs_filename $OPTARG)
				# fi
				RAW_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$RAW_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -i input file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME=`basename "$RAW_FILE"`
				if [ ${MAT_FILENAME: -4} != ".mat" ]; then
				echo -e "${COLOUR_RED}\nERROR: -i file should be in .mat format.${NO_COLOUR}\n" >&2
				exit 1  # exit 1: terminating with error
				fi
				MAT_FILENAME_WO_EXT="${MAT_FILENAME%%.*}"
				IFLAG=0
				;;
			a)
				# if [[ $OPTARG == *"~"* ]]; then
				# 	ANNOT_FILE=$(expand_path $OPTARG)
				# else
				# 	ANNOT_FILE=$(get_abs_filename $OPTARG)
				# fi
				ANNOT_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$ANNOT_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -a sample annotation file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				ANNOT_FILENAME=`basename "$ANNOT_FILE"`
				if [ ${ANNOT_FILENAME: -4} != ".csv" ]; then
					echo -e "${COLOUR_RED}\nERROR: -a sample annotation file needs to be .csv format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				AFLAG=0
				;;
			s)
				SAMPLE_ID=$OPTARG
				SFLAG=0
				;;
			b)
				# if [[ $OPTARG == *"~"* ]]; then
				# 	MODEL_FILE=$(expand_path $OPTARG)
				# else
				# 	MODEL_FILE=$(get_abs_filename $OPTARG)
				# fi
				MODEL_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$MODEL_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -l SVM model file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				MODEL_FILENAME=`basename "$MODEL_FILE"`
				if [ ${MODEL_FILENAME: -6} != ".Rdata" ]; then
					echo -e "${COLOUR_RED}\nERROR: -l SMV model file needs to be .Rdata format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				BFLAG=0
				;;
			m)
				# if [[ $OPTARG == *"~"* ]]; then
				#     CONFIG_FILE=$(expand_path $OPTARG)
				# else
				#     CONFIG_FILE=$(get_abs_filename $OPTARG)
				# fi
				CONFIG_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$CONFIG_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_YELLOW}\nWARNING: -m config file not found. Use the default settings.${NO_COLOUR}\n" >&2
				else
					CONFIG_FILENAME=`basename "$CONFIG_FILE"`
					CONF_CHECK=0
				fi
				;;
			o)
				# if [[ $OPTARG == *"~"* ]]; then
				#     OUT_DIR=$(expand_path $OPTARG)
				# else
				#     OUT_DIR=$(get_abs_filename $OPTARG)
				# fi
				OUT_DIR=$(path_resolve $OPTARG)
				if ! [ -d "$OUT_DIR" ]; then
					echo -e "${COLOUR_YELLOW}\nWARNING: -o output direcotry not found. use the current directory instead.${NO_COLOUR}\n" >&1
					OUT_DIR=.
				else
					OFLAG=0
				fi
				;;
			:)
				echo -e "${COLOUR_RED}\nERROR: Option -$OPTARG requires an argument.${NO_COLOUR}\n" >&2
				exit 1
				;;
			*)  # if the input option not defined
				echo ""
				echo -e "${COLOUR_RED}\nERROR: Invalid option: -$OPTARG${NO_COLOUR}\n" >&2
				echo -e $HELP
				echo -e "=========================================================================="
				echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
				exit 1
				;;
		esac
	done

fi

# ------ mandatory flag check ------
mand_flag_check "IFLAG:-i" "SFLAG:-s" "BFLAG:-b"
