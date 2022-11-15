import h5py 
import numpy as np
import pandas as pd
import os
from tqdm import tqdm

label_mapping_72 = pd.read_csv("/home/ang/Documents/GitHub/DeepWMA/labels_reference.csv", names=["label_names", "label_array"])
label_mapping_72['label_names'] = label_mapping_72['label_names'].astype('|S')
label_hdf_dtype = np.dtype([('label_names', 'a30'), ('label_values', int), ('label_array', int)])
feat_hdf_dtype = np.dtype([('feat', np.ndarray)])


subject_ID = "779370"
patient_data_path = "/media/ang/Data/unnerve_data/779370/"
output_folder="/media/ang/Data/unnerve_data/".format(subject_ID)
reducing_fraction = 0.3
streamlines = 0 

# TODO: Set args parameters for making this file working through bash 

for filename in tqdm(os.listdir(patient_data_path)):
    if filename.endswith((".h5")):
        if ".vtk" not in filename:
            if "atlas" not in filename:
                tract_name = filename.replace(subject_ID + "_T_", "").replace("_featMatrix.h5", "")
                tract_label = label_mapping_72.loc[label_mapping_72.label_names == bytes(tract_name, 'utf-8'),'label_array'].item()
                print(tract_name, tract_label, type(tract_label))

                # read featarray and pass tract_label
                with h5py.File(patient_data_path + filename, "r") as f:
                    feat_array = f.get('feat')[()]
                feat_label=np.empty(feat_array.shape[0], dtype=label_hdf_dtype)
                feat_label.fill((tract_name, tract_label, tract_label))

                # limit the size of the numpy array to reducing fraction of the array so that the error of big size can be resolved 
                n_tracts = int(reducing_fraction*feat_array.shape[0])

                feat_array = feat_array[0:n_tracts]
                feat_label = feat_label[0:n_tracts]

                # append this to a numpy array 

                if streamlines==0:
                    featMatrix = feat_array
                    featLabel = feat_label

                featMatrix = np.append(featMatrix, feat_array, axis=0)
                featLabel = np.append(featLabel, feat_label, axis=0)

                print("(featMatrix, featLabel)", featMatrix.shape, featLabel.shape)
                streamlines = feat_array.shape[0] + streamlines
                print("No. of Streamlines {}".format(streamlines))
    else: 
        continue

# feed the numpy array to a combined hdf5 file
h5_feat_array = h5py.File("/media/ang/Data/data/779370/{}_featMatrix.h5".format(subject_ID), 'w')
h5_feat_array.create_dataset('feat', data=featMatrix)
h5_feat_array.close()

h5_feat_label =  h5py.File("/media/ang/Data/data/779370/{}_label.h5".format(subject_ID), 'w')
h5_feat_label.create_dataset('label_array', data=featLabel['label_array'])# type: ignore
h5_feat_label.create_dataset('label_values', data=featLabel['label_values'])  # type: ignore
h5_feat_label.create_dataset('label_names', data=featLabel['label_names'])  # type: ignore

h5_feat_label.close()