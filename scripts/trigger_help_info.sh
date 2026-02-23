#!/usr/bin/env bash
# Name: trigger_help_info.sh
# Discription: display help info
# Note: in Shell, 0 is true, and 1 is false - reverted from other languages like R and Python

# ------ trigger help info and exit ------
echo -e $HELP
echo -e "\n"
echo -e "=========================================================================="
echo -e "${COLOUR_ORANGE}$CITE${NO_COLOUR}\n"
exit 0