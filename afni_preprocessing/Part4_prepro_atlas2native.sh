#!/bin/bash

# Date: Original April 2021, modified on 2/19/25
# Author: P Taylor
# Modified by: Daniela del Rio and then translated into bash with help from Deepseek
# Converting from standard space to native subject space.
# Note the SSwarper2 should have run already.
# Based on https://discuss.afni.nimh.nih.gov/t/convert-roi-from-mni-to-native-space/2997/4

# Observe how the edges look like with this transformation. Perhaps you could smooth them.

# Setting up the directories
subj="FreqAP08"
top_dir="/mnt/bcm_serv/Dani/FreqAP_Lingyan/Raw_data/${subj}"
atlas_dir="/home/dani/abin"

#################################################
######## Standard space to native subject space. ##############


# subject anatomy, native (subject) space
dset_anat="${top_dir}/Preprocessing/${subj}_ANAT_1+orig.nii.gz"  # myanat.sub007.nii.gz

dset_atl="${top_dir}/Preprocessing/MNI152_2009_template_SSW.nii.gz"
#dset_atl="${top_dir}/Preprocessing/MNI_Glasser_HCP_v1.0.nii.gz"

# -------------------------- input info -----------------------------


# SSW transform pieces: affine and NL parts.
# These are outputs of sswarper2. This should be applied to the original anatomical space.
ssw_aff="${top_dir}/mask_creation/anatQQ.${subj}.aff12.1D"
ssw_nl="${top_dir}/mask_creation/anatQQ.${subj}_WARP.nii"

# ------------------------ outputs to be made ---------------------------
# prefix of output warp: could be made using a ${subj} variable
ssw_full_inv="anatQQ.${subj}_full_INVWARP.nii.gz"

# ... and to be created, in subj anat space
dset_atl_subj="mni_glass_in_${subj}.nii.gz"  # atlas_native_space.nii.gz

# ----------------------------------------------------------------------
printf "About to start 3dNwarpCat.\n"

# create full inv warp: (aff + nl)^{-1}
# The way I am calling the variables in this part of the code might throw an error
3dNwarpCat                                  \
    -iwarp                                  \
    -warp1  "${ssw_nl}"                     \
    -warp2  "${ssw_aff}"                    \
    -prefix "${ssw_full_inv}"

printf "Done. About to start 3dNwarpApply.\n"
# apply full inv warp, with NN interpolant to preserve ints
3dNwarpApply                                                  \
    -prefix  "${dset_atl_subj}"                               \
    -nwarp   "${ssw_full_inv}"                                \
    -ainterp  NN                                              \
    -source  "${dset_atl}"                                    \
    -master  "${dset_anat}"

printf "Done. About to start 3drefit.\n"


# bonus nicety: attach any labletables/atlas points, as well as have
# it open a nice "ROI-like" colorbar in GUI when overlaid
3drefit -copytables "${dset_atl}"  "${dset_atl_subj}"
3drefit -cmap INT_CMAP             "${dset_atl_subj}"


printf "Done. About to copy files onto specific folders.\n"
# Copy files in specific folders
cp "mni_glass_in_${subj}.nii.gz" "${top_dir}/mask_creation"
cp "anatQQ.${subj}_full_INVWARP.nii.gz" "${top_dir}/mask_creation"

cp "mni_glass_in_${subj}.nii.gz" "${top_dir}/Preprocessing"
cp "anatQQ.${subj}_full_INVWARP.nii.gz" "${top_dir}/Preprocessing"