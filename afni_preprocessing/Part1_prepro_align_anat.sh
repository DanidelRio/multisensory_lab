#!/bin/bash

# Date: 2/11/25
# Author: Daniela del Rio
# Deepseek converted the Part1_preprocessing.sh tcsh script into bash.
# The main changes are replacing foreach loops with for loops, variable assignments and proper Bash syntax.
# This script takes dicom files (Osirixed scanner data) and creates .HEAD and .BRIK files
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
# stim_dir="$top_dir/EventFiles"

#################################################################
######## Part 1. Create HEAD and BRIK data for epi and anat ##############

# Obtains HEAD and BRIK files for Session 1
# Echo-planar imaging (EPI) data
for scan in 1 2 3 4 5 6 7 8; do
	cd "${top_dir}/Session1/ep2d_bold_sms_abcd_${scan}"
	printf "Processing ${subj} EPI ${scan}"
	Dimon -infile_prefix IM -dicom_org -gert_create_dataset -gert_to3d_prefix "${subj}_EPI${scan}" # Instead of _EPI, Lingyan used the name _SOMAT and Elise TacFreqEnc

	# Copy resulting .HEAD and .BRIK to Preprocessing folder
	cp "${subj}_EPI${scan}+orig.HEAD" "${top_dir}/Preprocessing"
	cp "${subj}_EPI${scan}+orig.BRIK" "${top_dir}/Preprocessing"
done


# Anat data for Session 1
cd "${top_dir}/Session1/3D_sagittal_T1W"
printf "Processing ${subj} ANAT session 1"
to3d -prefix "${subj}_ANAT_1" *dcm # Instead of Lingyan's MPRAGE, we will use ANAT

# Obtains HEAD and BRIK files for Session 2
for scan in 9 10 11 12 13 14 15 16; do
	cd "${top_dir}/Session2/ep2d_bold_sms_abcd_${scan}"
	printf "Processing ${subj} EPI ${scan}"
	Dimon -infile_prefix IM -dicom_org -gert_create_dataset -gert_to3d_prefix "${subj}_EPI${scan}"

	# Copy resulting .HEAD and .BRIK to Preprocessing folder
	cp "${subj}_EPI${scan}+orig.HEAD" "${top_dir}/Preprocessing"
	cp "${subj}_EPI${scan}+orig.BRIK" "${top_dir}/Preprocessing"
done

cd "${top_dir}/Session2/3D_sagittal_T1W"
printf "Processing ${subj} ANAT session 2"
to3d -prefix "${subj}_ANAT_2" *dcm

# Obtains HEAD and BRIK files for Session 3
for scan in 17 18 19 20 21 22 23 24; do
	cd "${top_dir}/Session3/ep2d_bold_sms_abcd_${scan}"
	printf "Processing ${subj} EPI ${scan}"
	Dimon -infile_prefix IM -dicom_org -gert_create_dataset -gert_to3d_prefix "${subj}_EPI${scan}"

	# Copy resulting .HEAD and .BRIK to Preprocessing folder
	cp "${subj}_EPI${scan}+orig.HEAD" "${top_dir}/Preprocessing"
	cp "${subj}_EPI${scan}+orig.BRIK" "${top_dir}/Preprocessing"
done

cd "${top_dir}/Session3/3D_sagittal_T1W"
printf "Processing ${subj} ANAT session 3"
to3d -prefix "${subj}_ANAT_3" *dcm

# Obtains HEAD and BRIK files for Session 4
for scan in 25 26 27 28 29 30 31 32; do
	cd "${top_dir}/Session4/ep2d_bold_sms_abcd_${scan}"
	printf "Processing ${subj} EPI ${scan}"
	Dimon -infile_prefix IM -dicom_org -gert_create_dataset -gert_to3d_prefix "${subj}_EPI${scan}"

	# Copy resulting .HEAD and .BRIK to Preprocessing folder
	cp "${subj}_EPI${scan}+orig.HEAD" "${top_dir}/Preprocessing"
	cp "${subj}_EPI${scan}+orig.BRIK" "${top_dir}/Preprocessing"
done

cd "${top_dir}/Session4/3D_sagittal_T1W"
printf "Processing ${subj} ANAT session 4"
to3d -prefix "${subj}_ANAT_4" *dcm

# Creating the HEAD and BRIK files for all the anatomy files
for session in 1 2 3 4; do
	cd "${top_dir}/Session${session}/3D_sagittal_T1W"
	cp "${subj}_ANAT_${session}+orig.HEAD" "${top_dir}/Preprocessing"
	cp "${subj}_ANAT_${session}+orig.BRIK" "${top_dir}/Preprocessing"
done

#################################################
######## Part 2. Align all the ANAT files ##############

printf "Aligning ANAT files"
cd "${top_dir}/Preprocessing"

# Elise's note: in 'align_epi_anat.py' it is best to use -cost lpa for intra-modality alignment
align_epi_anat.py -dset1 "${subj}_ANAT_1+orig." -dset2 "${subj}_ANAT_2+orig." -dset2to1 -cost lpa -ginormous_move
align_epi_anat.py -dset1 "${subj}_ANAT_1+orig." -dset2 "${subj}_ANAT_3+orig." -dset2to1 -cost lpa -ginormous_move
align_epi_anat.py -dset1 "${subj}_ANAT_1+orig." -dset2 "${subj}_ANAT_4+orig." -dset2to1 -cost lpa -ginormous_move

# Averaging all the anatomy files into a single anatomy file.
3dMean -prefix "${subj}_ANAT_c1234" "${subj}_ANAT_1+orig" "${subj}_ANAT_2_al+orig" "${subj}_ANAT_3_al+orig" "${subj}_ANAT_4_al+orig"