#!/bin/tcsh

# Date: Original April 2021, modified on 2/19/25
# Author: P Taylor
# Modified by: Daniela del Rio and then translated into bash with help from Deepseek
# Obtaining the transformation between a standard space and native subject space.
# Note the MNI template should be in the afni binaries directory.
# Based on https://discuss.afni.nimh.nih.gov/t/convert-roi-from-mni-to-native-space/2997/4

# Observe how the edges look like with this transformation. Perhaps you could smooth them.

# Setting up the directories
subj="FreqAP08"
top_dir="/mnt/bcm_serv/Dani/FreqAP_Lingyan/Raw_data/${subj}"
atlas_dir="/home/dani/abin"

#################################################
######## Standard space to native subject space. ##############

cd "${top_dir}/Preprocessing" || { echo "Directory not found"; exit 1; }

3dAFNItoNIFTI -prefix "${subj}_ANAT_1+orig.nii.gz" "${subj}_ANAT_c1234+orig"
printf "Copied 3dcopy anat into .nii.gz\n"

# subject anatomy, native (subject) space
dset_anat="${top_dir}/Preprocessing/${subj}_ANAT_1+orig.nii.gz"  # myanat.sub007.nii.gz

cd "${atlas_dir}"
cp "MNI152_2009_template_SSW.nii.gz" "${top_dir}/Preprocessing"
# This would have to be on SSW space, (on grid of MNI*SSW*nii.gz)


dset_atl="${top_dir}/Preprocessing/MNI152_2009_template_SSW.nii.gz"


# -------------------------- Apply sswarper2 -----------------------------
# Documentation here: https://afni.nimh.nih.gov/pub/dist/doc/program_help/sswarper2.html
cd "${top_dir}/Preprocessing" || { echo "Directory not found"; exit 1; }

sswarper2 \
    -input  "$dset_anat" \
    -base   "$dset_atl"  \
    -subid  "$subj"      \
    -odir   "${top_dir}/mask_creation" \
    -giant_move # There was a bad alignment, so let's see if this fixes it.
