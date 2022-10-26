

BRAINSFitCLI=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/BRAINSFit
Slicer=/home/ang/Documents/Slicer-5.0.2/Slicer
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz

export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/:$LD_LIBRARY_PATH


# Take in the NIFTI file for the brain image, bvel, bvec, and NIFTI file of the brain mask 
# dHCP

path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1/
# path_dwi=/media/ang/Data/dMRI_data/dHCP/sub-CC00542XX15/ses-165800/dwi/
# cd ${path_dwi}
# patient_id=165800
# nifti=sub-CC00542XX15_ses-165800_desc-preproc_dwi.nii.gz
# bvec=sub-CC00542XX15_ses-165800_desc-preproc_dwi.bvec
# bval=sub-CC00542XX15_ses-165800_desc-preproc_dwi.bval
# mask=sub-CC00542XX15_ses-165800_desc-preproc_space-dwi_brainmask.nii.gz

mean_b0=100HCP-population-mean-b0.nii.gz
nhdr_data=$path_dwi$patient_id.nhdr
# UKF_path=

convert_path=/home/ang/Documents/GitHub/SupWMA/conversion/conversion
# conda activate SupWMA

# for the input NIFTI
# python3 $convert_path/nhdr_write.py --nifti $nifti --bval $bval --bvec $bvec --nhdr $nhdr_data

# for the mask
# python3 $convert_path/nhdr_write.py --nifti $nifti --nhdr $mask
# Convert all the NIFTI files to NHDR using NIFTI->NHDR write form the conversion pipeline in the UKFTractography 


# Pass the .vtk file in the subject specific parcellation to clusters and the tracts 


# Create the inpur training data for SupWMA



# Create the label files 

#Inputs from the user

subject_ID=999999

# Data Folders
input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}

subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd
# subject_b0=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1/100HCP-population-mean-b0.nii.gz
subject_b0=atlas/100HCP-population-mean-T2.nii.gz # TODO: convert to .nrrd
subject_tract=${input_folder}/${subject_ID}_ukf.vtk

(cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $nhdr_data)
$BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine
python ./dlt_extract_tract_feat.py ${output_folder}/${subject_ID}_ukf.vtk $output_folder -outPrefix ${subject_ID} -feature RAS-3D -numPoints 15
