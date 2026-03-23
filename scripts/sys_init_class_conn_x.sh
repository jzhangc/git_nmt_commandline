#!/usr/bin/env bash
# Name: sys_init_2d.sh
# Discription: system initiation with flag checks and dependency checks
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ variables ------
# -- initiate mandatory variable check variable. initial value 1 (false) --
CONF_CHECK=1

# --- flag check and flag variables (unfinished) ---
# initiate mandatory variable check variable. initial value 1 (false)
PSETTING=FALSE  # note: PSETTING is to be passed to R. therefore a separate variable is used
CORES=1  # this is for the parallel computing

IFLAG=1
AFLAG=1
SFLAG=1
GFLAG=1
NFLAG=1
DFLAG=1
RFLAG=1
CFLAG=1

# below: CV univariate reduction
UFLAG=1
CVUNI=FALSE
KFLAG=1   # prior univariate knowledge
XFLAG=1

# optional flag values
OUT_DIR=.  # set the default to output directory


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

	# -- initial message --
	echo -e "\nYou are running ${COLOUR_BLUE_L}$APP_NAME${NO_COLOUR}"
	echo -e "Version: $VERSION"
	echo -e "Current OS: $PLATFORM"
	echo -e "Today is: $CURRENT_DAY\n"
	echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"

	while getopts ":kuxp:i:a:s:g:n:d:r:c:m:o:" opt; do
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
			g)
				GROUP_ID=$OPTARG
				GFLAG=0
				;;
			n)
				# if [[ $OPTARG == *"~"* ]]; then
				# 	NODE_FILE=$(expand_path $OPTARG)
				# else
				# 	NODE_FILE=$(get_abs_filename $OPTARG)
				# fi	
				NODE_FILE=$(path_resolve $OPTARG)
				if ! [ -f "$NODE_FILE" ]; then
					# >&2 means assign file descripter 2 (stderr). >&1 means assign to file descripter 1 (stdout)
					echo -e "${COLOUR_RED}\nERROR: -n node annotation file not found.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				NODE_FILENAME=`basename "$NODE_FILE"`
				if [ ${NODE_FILENAME: -4} != ".csv" ]; then
					echo -e "${COLOUR_RED}\nERROR: -N node annotation file needs to be .csv format.${NO_COLOUR}\n" >&2
					exit 1  # exit 1: terminating with error
				fi

				NFLAG=0
				;;
			d)
				NODE_ID=$OPTARG
				DFLAG=0
				;;
			r)
				REGION_NAME=$OPTARG
				RFLAG=0
				;;
			c)
			 	CONTRAST=$OPTARG
				CFLAG=0
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
			k)
				KFLAG=0  # no to set CVUNI as FALSE is the default
				;;
			u)
				UFLAG=0
				CVUNI=TRUE
				;;
			x)
				XFLAG=0
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

# ------ flag check -----
if [[ $IFLAG -eq 1 || $AFLAG -eq 1 || $SFLAG -eq 1 ||$GFLAG -eq 1 || $NFLAG -eq 1 || $DFLAG -eq 1 || $RFLAG -eq 1 || $CFLAG -eq 1 ]]; then
	echo -e "${COLOUR_RED}ERROR: -i, -a, -s, -g, -n, -d, -r, -c flags are mandatory. Use -h or --help to see help info.${NO_COLOUR}\n" >&2
	exit 1
fi

if [[ $KFLAG -eq 0 && $UFLAG -eq 0 ]]; then
	echo -e "${COLOUR_RED}ERROR: Set either -u or -k, but not both.${NO_COLOUR}\n" >&2
	exit 1
fi


# --- flag message ---
if [[ $UFLAG -eq 0 || $KFLAG -eq 0 || $XFLAG -eq 0 ]]; then
	echo -e "\nYou are running with following optional flags\n"
	if [ $UFLAG -eq 0 ]; then
		echo -e "-u: use univariate analysis result during CV-SVM-rRF-FS. NOTE: the analysis on all data is still done.\n"
	fi
	if [ $KFLAG -eq 0 ]; then
		echo -e "-k: incorporate univariate prior knowledge to SVM analysis.\n"
	fi
	if [ $XFLAG -eq 0 ]; then
		echo -e "-x: cross-validation only\n"
	fi
fi


# ------ display output folder ------
echo -e "Output direcotry: ${COLOUR_BLUE_L}$OUT_DIR${NO_COLOUR}"