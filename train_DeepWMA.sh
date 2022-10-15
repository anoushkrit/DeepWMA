
BRAINSFitCLI=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/BRAINSFit
Slicer=/home/ang/Documents/Slicer-5.0.2/Slicer
atlas_T2 = /home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz

# Training the Model
# Input VTK file
train_data=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/example-UKF-data.vtk


# GroundTruthFIle


# mean b0 subject specific 
subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd




# Testing this pretrained model
CNN_model_folder=./SegModels/CNN/

# input data
subject_ID=101410

input_folder=./TestData/${subject_ID}/
output_folder=./TestData/${subject_ID}/DeepWMAOutput
mkdir $output_folder

subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd
# why is the mean b0, subject specific? 
subject_tract=${input_folder}/${subject_ID}_ukf_l40_f10k.vtp 
# example whole brain tractography with fiber length over 40 mm. `wm_preprocess_all.py` can be used to remove short fibers for your own data.

# TODO: delete two lines below or change them to your Slicer module path
# export the defined environment variable which sets the path that the linker should look into while linking dynamic libraries/shared libraries.
# export LD_LIBRARY_PATH=/home/victor/alarge/Softwares/Slicer-4.10.2-linux-amd64/lib/Slicer-4.10/cli-modules/
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/:$LD_LIBRARY_PATH


# export LD_LIBRARY_PATH=/home/victor/alarge/Softwares/Slicer-4.10.2-linux-amd64/lib/Slicer-4.10/:$LD_LIBRARY_PATH

# Volume registration
$BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine

# Transform the vtp models (tractography): 101410_ukf_l40_f10k.vtp in the input folder using transformation obtained from last step
wm_harden_transform.py ${input_folder} $output_folder $Slicer -t $output_folder/b0_to_atlasT2.tfm -j 1

# No ground truth, no downsampleStep
# FiberMap computation
python ./dlt_extract_tract_feat.py ${output_folder}/${subject_ID}_ukf_l40_f10k.vtp $output_folder -outPrefix ${subject_ID} -feature RAS-3D -numPoints 15

# DeepWMA segmentation
python ./dlt_test.py ${CNN_model_folder}/cnn_model.h5 -modelLabelName ${CNN_model_folder}/cnn_label_names.h5 $output_folder/${subject_ID}_featMatrix.h5 $output_folder -outPrefix ${subject_ID} -tractVTKfile ${subject_tract}

# Clean temp files
rm -r $output_folder/${subject_ID}_featMatrix.h5 ${output_folder}/${subject_ID}_ukf_l40_f10k.vtp