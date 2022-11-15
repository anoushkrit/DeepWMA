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
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ang/Documents/programs/ParaView-5.10.1-MPI-Linux-Python3.9-x86_64/lib  # for .trk to .vtp

export PYTHONWARNINGS="ignore"
convert_path=/home/ang/Documents/GitHub/DeepWMA/conversion_scripts/conversion

#statics for HCP subjects
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz
path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1
mean_b0=100HCP-population-mean-b0.nii.gz

# test 105HCP subject
subject_ID=999999   # enter your subject ID
# input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
input_data_folder=/media/ang/Data/dMRI_data/105HCP/Fiber_Tracts/${subject_ID}
output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/media/ang/Data/unnerve_data/${subject_ID}

echo "_______________CONVERT .trk to .vtk for ${subject_ID}__________________"

## convert the .trk files to .vtk files

# loop over all the .trk files
for filename in ${input_data_folder}/tracts/*.trk; do
    fiber_name=`echo ${filename} | sed 's:.*/::'`
    # echo _______CONVERSION:[.trk to .tck]_________
    # shift terminal directory to the .trk source and execute trk2tck
    (cd ${input_data_folder}/tracts; trampolino convert -t ${filename} trk2tck)

    # cleaning up temporary files
    mv ${input_data_folder}/tracts/trampolino/track.tck ${input_data_folder}/tracts/${subject_ID}.tck
    sudo rm -rf ${input_data_folder}/tracts/meta
    rm -rf ${input_data_folder}/tracts/trampolino

    tckinfo ${input_data_folder}/tracts/${subject_ID}.tck
    # echo _________CONVERSION:[.tck to .vtk]_________
    tckconvert ${input_data_folder}/tracts/${subject_ID}.tck ${input_data_folder}/vtk_tracts/${fiber_name}.vtk -force
    echo ${input_data_folder}/${fiber_name}.vtk
    # echo ${input_data_folder}/vtp_tracts/$fiber_name.vtk
done
echo "converting .trk to .vtk for subject ${subject_ID} complete"

echo "_______________EXTRACT_FEAT_MATRIX for each TRACT of subject ${subject_ID}____________"

for filename in ${input_data_folder}/vtk_tracts/*.vtk; do
    tract_name=${filename#"${input_data_folder}/"}
    tract_name=${tract_name%".trk.vtk"}

    echo ---------------${tract_name}----
    python ./dlt_extract_tract_feat.py ${filename} $output_folder -outPrefix ${subject_ID}_T_${tract_name} -feature RAS-3D -numPoints 15

done

echo "extracted all feat_matrix for subject ${subject_ID}"

trained_model_weights=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_last_weights.h5
model_label_names=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_label_names.h5
model_params=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_params.npy

# placeholders
nhdr_data=$path_dwi/$patient_id.nhdr

subject_b0=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz # convert to .nrrd
# subject_tract=${input_folder}/${subject_ID}_ukf.vtk

# convert nii.gz to .nrrd
(cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $nhdr_data)

# Perform BRAINSFit Transformations
$BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine
# Extract 
python ./dlt_extract_tract_feat.py ${output_folder}/${subject_ID}_ukf.vtk $output_folder -outPrefix ${subject_ID} -feature RAS-3D -numPoints 15


python ./dlt_test.py ${CNN_model_folder}/cnn_model.h5 -modelLabelName ${CNN_model_folder}/cnn_label_names.h5 $output_folder/${subject_ID}_featMatrix.h5 $output_folder -outPrefix ${subject_ID} -tractVTKfile ${subject_tract}

