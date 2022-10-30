
BRAINSFitCLI=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/BRAINSFit
Slicer=/home/ang/Documents/Slicer-5.0.2/Slicer
atlas_T2=/home/ang/Documents/GitHub/DeepWMA/atlas/100HCP-population-mean-T2.nii.gz

export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/cli-modules/
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/Slicer-5.0/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/Documents/Slicer-5.0.2/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/anaconda3/envs/SupWMA/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ang/anaconda3/envs/pnlpipe3/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/
export PYTHONWARNINGS="ignore"

convert_path=/home/ang/Documents/GitHub/DeepWMA/conversion_scripts/conversion
subject_ID=779370 # TODO: find 6 digit number in the path starting and ending with /, use regex (outer loop)
# statics
path_105HCP=/media/ang/Data/dMRI_data/105HCP/Fiber_Tracts/${subject_ID}/vtp_tracts
path_vtp_tracts=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/AnatomicalTracts
path_dwi=/home/ang/Documents/GitHub/WMA/WMA_tutorial_data/ORG-Atlases-1.1.1/
mean_b0=100HCP-population-mean-b0.nii.gz


# subject specific variables

input_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
# input_folder=/media/ang/Data/unnerve_data/DeepWMA/${subject_ID}
# output_folder=/home/ang/Documents/GitHub/DeepWMA/data/${subject_ID}
output_folder=/media/ang/Data/unnerve_data/${subject_ID}
mkdir $input_folder 
mkdir $output_folder
subject_b0=${input_folder}/${subject_ID}-dwi_meanb0.nrrd # TODO: find subject specific b0 if available (outer loop)
subject_b0=/media/ang/Data/dMRI_data/ORG_Atlases/100HCP-population-mean-b0.nii.gz
nhdr_data=${input_folder}/${subject_ID}-mean-b0.nhdr

# $BRAINSFitCLI --fixedVolume $atlas_T2 --movingVolume $subject_b0 --linearTransform $output_folder/b0_to_atlasT2.tfm --useRigid --useAffine # outer loop
# (cd ${convert_path}; python3 $convert_path/nhdr_write.py --nifti $path_dwi$mean_b0 --nhdr $nhdr_data)

# subject_tract=${input_folder}/${subject_ID}_ukf.vtk # for training, but this would become redundant because
# only .h5 file will be passed to training


echo "_______________EXTRACT_FEAT_MATRIX for each TRACT of subject ${subject_ID}____________"

for filename in $path_105HCP/*.vtk; do
    tract_name=${filename#"$path_105HCP/"}
    tract_name=${tract_name%".trk.vtk"}

    echo ---------------${tract_name}----
    python ./dlt_extract_tract_feat.py ${filename} $output_folder -outPrefix ${subject_ID}_T_${tract_name} -feature RAS-3D -numPoints 15

done
