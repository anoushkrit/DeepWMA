
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
subject_ID=779370

# Data Folders
input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
CNN_model_folder=./SegModels/CNN/


# placeholders
nhdr_data=$path_dwi$patient_id.nhdr
# subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd
subject_b0=atlas/100HCP-population-mean-T2.nii.gz # convert to .nrrd
subject_tract=${input_folder}/${subject_ID}_ukf.vtk


# DeepWMA training 
# inputFeat=/home/ang/Documents/GitHub/DeepWMA/data/999999/999999_featMatrix.h5
# input_feature=/home/ang/Documents/GitHub/DeepWMA/data/909090/909090_featMatrix.h5
input_feature=/media/ang/Data/data/779370/${subject_ID}_featMatrix.h5

# input_label=/home/ang/Documents/GitHub/DeepWMA/data/999999/999999_labels.h5
input_label=/media/ang/Data/data/779370/${subject_ID}_label.h5
output_dir=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}/model_output

python ./unnerve_train.py ${input_feature} ${input_label} ${output_dir} -outPrefix ${subject_ID} -architecture 'CNN-simple'