# for 105 HCP patients where the 72 fiber tracts are available
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
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ang/ANTs/Build/ITKv5/Modules/IO/ImageBase/include/itkImageFileReader.hxx
export PYTHONWARNINGS="ignore"
convert_path=/home/ang/Documents/GitHub/DeepWMA/conversion_scripts/conversion

#statics for HCP subjects
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz
path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1/
mean_b0=100HCP-population-mean-b0.nii.gz


# test 105HCP subject
subject_ID=654754   # enter your subject ID
test_subject_ID=673455 # reference test subject
# input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
subject_trk_source=/media/ang/Data/dMRI_data/105HCP/Fiber_Tracts/${subject_ID}
# output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/media/ang/Data/unnerve_data/${subject_ID}
nhdr_data=$path_dwi/${subject_ID}.nhdr
mkdir ${subject_trk_source}/vtk_tracts
reducing_fraction=0.3
# mkdir ${subject_trk_source}/tracts

echo "_______________CONVERT .trk to .vtk for ${subject_ID}__________________"

## convert the .trk files to .vtk files

# loop over all the .trk files
mv ${subject_trk_source}/${subject_ID}.trk ${subject_trk_source}/tracts/
for filename in ${subject_trk_source}/tracts/*.trk; do
    fiber_name=`echo ${filename} | sed 's:.*/::'`
    # echo _______CONVERSION:[.trk to .tck]_________
    # shift terminal directory to the .trk source and executee trk2tck
    (cd ${subject_trk_source}/tracts; trampolino convert -t ${filename} trk2tck)

    # cleaning up temporary files
    mv ${subject_trk_source}/tracts/trampolino/track.tck ${subject_trk_source}/tracts/${subject_ID}.tck
    sudo rm -rf ${subject_trk_source}/tracts/meta
    rm -rf ${subject_trk_source}/tracts/trampolino

    tckinfo ${subject_trk_source}/tracts/${subject_ID}.tck
    # echo _________CONVERSION:[.tck to .vtk]_________
    tckconvert ${subject_trk_source}/tracts/${subject_ID}.tck ${subject_trk_source}/vtk_tracts/${fiber_name}.vtk -force
    echo ${subject_trk_source}/${fiber_name}.vtk
    # echo ${subject_trk_source}/vtk_tracts/$fiber_name.vtk
done
echo "converting .trk to .vtk for subject ${subject_ID} complete"


echo "_______________EXTRACT_FEAT_MATRIX for each TRACT of subject ${subject_ID}____________"

for filename in ${subject_trk_source}/vtk_tracts/*.vtk; do
    tract_name=${filename#"${subject_trk_source}/"}
    tract_name=${tract_name%".trk.vtk"}
    tract_name=${tract_name#"vtk_tracts/"}

    echo ---------------${tract_name}----
    python ./dlt_extract_tract_feat.py ${filename} $output_folder -outPrefix ${subject_ID}_T_${tract_name} -feature RAS-3D -numPoints 15

done

echo "extracted all feat_matrix for subject ${subject_ID}"

# generate labels.h5 for all the feature matrices
# subject tractography parcellation missing because wse are using ground truth tract files the input and their names are taken as label mapping

echo "_______________GENERATE, REDUCE, MERGE label and featMatrix for ${subject_ID}____________"
# args.featMatrix_path + "/{}_label.h5"
# args.featMatrix_path + "/{}_featMatrix.h5"

python ./vtp2featMatrix.py ${subject_ID} ${output_folder} 0.3

# shuffle the featMatrix for testing the featMatrix

# model config
trained_model_weights=${output_folder}/model_output/${test_subject_ID}_last_weights.h5
model_label_names=${output_folder}/model_output/${test_subject_ID}_label_names.h5
model_params=${output_folder}/model_output/${test_subject_ID}_params.npy

trained_model_weights=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_last_weights.h5
model_label_names=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_label_names.h5
model_params=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_params.npy
subject_b0=${output_folder}/${subject_ID}-dwi_meanb0.nhdr

# TODO: convert nii.gz to .nrrd
(cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $path_dwi/${subject_ID}_b0.nhdr)
(cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $atlas_T2 --nhdr ${subject_b0})
# (cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $atlas_T2 --nhdr ${output_folder}/${subject_ID}_atlas.nhdr)

echo "_________converted to nhdr ______________"


# Perform BRAINSFit Transformations
$BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine
wm_harden_transform.py ${subject_trk_source}/vtk_tracts/ $output_folder/ $Slicer -t $output_folder/b0_to_atlasT2.tfm -j 1

# python ./dlt_test.py ${trained_model_weights} ${output_folder}/${subject_ID}_featMatrix.h5 $output_folder/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5 -Dataset ${model_label_names}
python ./dlt_test.py ${trained_model_weights} ${model_label_names} ${output_folder}/${subject_ID}_featMatrix.h5 $output_folder/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5

# python ./dlt_test.py ${trained_model_weights} ${model_label_names} ${output_folder}/${subject_ID}_featMatrix.h5 $output_folder/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5 -tractVTKfile ${subject_tract}


