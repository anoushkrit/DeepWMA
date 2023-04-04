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
subject_ID=898176   # enter your subject ID
test_subject_ID=673455 # reference test subject
# input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
subject_trk_source=/media/ang/Data/dMRI_data/105HCP/Fiber_Tracts/${subject_ID}
# output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/media/ang/Data/unnerve_data/${subject_ID}
nhdr_data=$path_dwi/${subject_ID}.nhdr
mkdir ${subject_trk_source}/vtk_tracts
reducing_fraction=0.3
# mkdir ${subject_trk_source}/tracts

# model config
trained_model_weights=${output_folder}/model_output/${test_subject_ID}_last_weights.h5
model_label_names=${output_folder}/model_output/${test_subject_ID}_label_names.h5
model_params=${output_folder}/model_output/${test_subject_ID}_params.npy

trained_model_weights=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_last_weights.h5
model_label_names=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_label_names.h5
model_params=/home/ang/Documents/GitHub/DeepWMA/data/779370/model_output_9_nov/779370_params.npy
subject_b0=${output_folder}/${subject_ID}-dwi_meanb0.nhdr

# python ./dlt_test.py ${trained_model_weights} ${output_folder}/${subject_ID}_featMatrix.h5 $output_folder/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5 -Dataset ${model_label_names}
# python ./dlt_test.py ${trained_model_weights} ${model_label_names} ${output_folder}/${subject_ID}_featMatrix.h5 ${output_folder}/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5
# python ./dlt_test.py ${trained_model_weights} -modelLabelName ${model_label_names} /media/ang/Data/unnerve_data/898176/898176_featMatrix.h5 ${output_folder}/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5
python ./dlt_test.py ${trained_model_weights} ${model_label_names} /media/ang/Data/unnerve_data/898176/898176_featMatrix.h5 ${output_folder}/test -outPrefix ${subject_ID} -tractVTKfile /media/ang/Data/dMRI_data/105HCP/Fiber_Tracts/898176/vtk_tracts/898176.trk.vtk
# python ./dlt_test.py ${trained_model_weights} ${model_label_names} ${output_folder}/${subject_ID}_featMatrix.h5 $output_folder/test -outPrefix ${subject_ID} -inputLabel ${output_folder}/${subject_ID}_label.h5 -tractVTKfile ${subject_tract}


