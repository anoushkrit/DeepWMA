
# conda env SupWMA
# Libraries
BRAINSFitCLI=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/BRAINSFit
Slicer=/home/ang/Documents/Slicer-5.0.2/Slicer

export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/anaconda3/envs/SupWMA/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/anaconda3/envs/pnlpipe3/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/
export PYTHONWARNINGS="ignore"

convert_path=/home/ang/Documents/GitHub/DeepWMA/conversion_scripts/conversion

# reference files
subject_ID=909090
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz
path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1/
mean_b0=100HCP-population-mean-b0.nii.gz

train_data=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/example-UKF-data.vtk

# Data Folders
input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
CNN_model_folder=./SegModels/CNN/


# placeholders
nhdr_data=$path_dwi$patient_id.nhdr
# subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd
subject_b0=atlas/100HCP-population-mean-T2.nii.gz # convert to .nrrd
subject_tract=${input_folder}/${subject_ID}_ukf.vtk

# convert nii.gz to .nrrd
(cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $nhdr_data)
# python3 conversion/conversion/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $nhdr_data
wm_harden_transform.py ${input_folder}/ $output_folder $Slicer -t $output_folder/b0_to_atlasT2.tfm -j 1
# Perform BRAINSFit Transformations
$BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine

# Extract 
python ./dlt_extract_tract_feat.py ${output_folder}/${subject_ID}_ukf.vtk $output_folder -outPrefix ${subject_ID} -feature RAS-3D -numPoints 15

# DeepWMA training 
# inputFeat=/home/ang/Documents/GitHub/DeepWMA/data/999999/999999_featMatrix.h5
input_feature=/home/ang/Documents/GitHub/DeepWMA/data/909090/909090_featMatrix.h5
# input_label=/home/ang/Documents/GitHub/DeepWMA/data/999999/999999_labels.h5
input_label=/home/ang/Documents/GitHub/DeepWMA/data/909090/909090_labels_new.h5
output_dir=/home/ang/Documents/GitHub/DeepWMA/data/909090/model_output

python ./unnerve_train.py ${input_feature} ${input_label} ${output_dir} -outPrefix ${subject_ID} -architecture 'CNN-simple'