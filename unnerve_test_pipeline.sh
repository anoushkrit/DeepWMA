# for 105 HCP patients where the 72 fiber tracts are available via 


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

#statics for HCP subjects
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz
path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1
mean_b0=100HCP-population-mean-b0.nii.gz


echo "_______________EXTRACT_FEAT_MATRIX for each TRACT of subject ${subject_ID}____________"

for filename in $path_105HCP/*.vtk; do
    tract_name=${filename#"$path_105HCP/"}
    tract_name=${tract_name%".trk.vtk"}

    echo ---------------${tract_name}----
    python ./dlt_extract_tract_feat.py ${filename} $output_folder -outPrefix ${subject_ID}_T_${tract_name} -feature RAS-3D -numPoints 15

done


# test 105HCP subject
subject_ID=999999   # enter your subject ID
input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}

trained_model_weights=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_last_weights.h5
model_label_names=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_label_names.h5
model_params=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_params.npy

# placeholders
nhdr_data=$path_dwi/$patient_id.nhdr
subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd
subject_b0=atlas/100HCP-population-mean-T2.nii.gz # convert to .nrrd
subject_tract=${input_folder}/${subject_ID}_ukf.vtk
