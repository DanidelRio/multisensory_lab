#!/bin/bash

# Date: 2/18/25
# Author: Daniela del Rio
# This script aligns the second half of EPI data to a single ANAT file.
# Each subject has 4 sessions, 8 scans/runs per session.

# ----------------------------------
# Elise's comments:
# -dicom_org: organizes scan files by number
# -gert_create_dataset: actually creates the output dataset, implies the -quit option
# -gert_to3d_prefix: sets prefix of resulting .HEAD and .BRIK files
# ----------------------------------

# Setting up the directories
subj="FreqAP08"
top_dir="/mnt/bcm_serv/Dani/FreqAP_Lingyan/Raw_data/${subj}"

#############################################################
######## Align all the EPI files to ANAT_c1234 ##############

printf "Aligning EPI files"
cd "${top_dir}/Preprocessing"

# Note the cost function for intra-modality alignment (Part1_preprocessing_bash.sh) is lpa
# Here, for different modality alignment, it is lpc (local pearson correlation)

for scan in 25 26 27 28 29 30 31 32 16 18; do
	align_epi_anat.py -dset1 "${subj}_ANAT_c1234+orig." -dset2 "${subj}_EPI${scan}+orig." -dset2to1 -cost lpc -ginormous_move

	# Copy resulting .HEAD and .BRIK to Preprocessing folder
	# cp "${subj}_EPI${scan}+orig.HEAD" "${top_dir}/Preprocessing"
	# cp "${subj}_EPI${scan}+orig.BRIK" "${top_dir}/Preprocessing"

done