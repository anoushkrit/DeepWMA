import src.tract_feat as tract_feat
import src.nn_model as nn_model

import whitematteranalysis as wma
import numpy as np

import argparse
import os
import h5py

import tensorflow as tf
from tensorflow.keras.models import load_model

from tensorflow.compat.v1 import ConfigProto
from tensorflow.compat.v1 import InteractiveSession
import warnings

def fxn():
    warnings.warn("deprecated", DeprecationWarning)

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    fxn()

# Assign GPU usage.
config = ConfigProto()
# # fix the gpu memory usage portion
# config.gpu_options.per_process_gpu_memory_fraction = 0.8
# dynamic assign gpu memory
config.gpu_options.allow_growth = True
session = InteractiveSession(config=config)

# -----------------
# Parse arguments
# ----------------
parser = argparse.ArgumentParser(
    description="Train a model.",
    epilog="Written by Fan Zhang, fzhang@bwh.harvard.edu")

parser.add_argument(
    'inputFeat',
    help='Input tract feature data as an h5 file.')
parser.add_argument(
    'inputLabel',
    help='Input ground truth label as an h5 file.')
parser.add_argument(
    'outputDir',
    help='The output directory should be a new empty directory. It will be created if needed.')

parser.add_argument(
    '-outPrefix', type=str,
    help='A prefix string of all output files.')

parser.add_argument(
    '-architecture', type=str,
    help='Name of DL architecture, including" `CNN-simple`')

parser.add_argument(
    '-validationFeat', action="store", type=str,
    help='Validation tract feature data as an h5 file.')
parser.add_argument(
    '-validationLabel', action="store", type=str,
    help='Validation ground truth label as an h5 file.')

parser.add_argument(
    '-tract', action="store", type=str,
    help='Train a model on a certain tract.')

parser.add_argument(
    '-bilateral', action='store_true',
    help='Bilateral nor not.')

args = parser.parse_args()

script_name = '<train>'

if not os.path.exists(args.inputFeat):
    print(script_name, "Error: Input feature ", args.inputFeat, "does not exist.")
    exit()

if not os.path.exists(args.inputLabel):
    print(script_name, "Error: Input label ", args.inputLabel, "does not exist.")
    exit()

if not os.path.exists(args.outputDir):
    print(script_name, "Output directory", args.outputDir, "does not exist, creating it.")
    os.makedirs(args.outputDir)

# set parameter
params = dict()
params['single_multiple_tract_model'] = True
params['downsample_step'] = 1

if args.bilateral:
    params['bilateral_feature'] = True
else:
    params['bilateral_feature'] = False

print(script_name, params)

tmp_h5_feat = os.path.join(args.outputDir, args.outPrefix + '_tmp_feature.h5')
if not os.path.exists(tmp_h5_feat):

# editing for scenario where every single feature matrix is mapped to a label
    # with h5py.File(args.inputFeat, "r") as f:
    #     deep_wm_features = f['sc_feat'].value
    #     other_wm_features = f['other_feat'].value
    #     x_train = np.concatenate((deep_wm_features, other_wm_features), axis=0)
    #     # x_train = f['feat'].value
    #     # TODO: what is the SWM feature doing in the DeepWMA feature set
    #     print(script_name, 'Input SWM feat shape:', deep_wm_features.shape)
    #     print(script_name, 'Input other fiber fiber shape', other_wm_features.shape)
    #     print(script_name, 'Input original feat shape:', x_train.shape)

    with h5py.File(args.inputFeat, "r") as f:
        deep_wm_features = f['feat'][()]
        x_train = deep_wm_features
        # other_wm_features = f['other_feat'].value
        # x_train = np.concatenate((deep_wm_features, other_wm_features), axis=0)
        # x_train = f['feat'].value
        # TODO: what is the SWM feature doing in the DeepWMA feature set
        print(script_name, 'Input DeepWMA feat shape:', deep_wm_features.shape)
        print(script_name, 'Input original feat shape:', x_train.shape)

# editing for passing y_prediction.h5 as the input label for training the CNN-simple model
    # with h5py.File(args.inputLabel, "r") as f:
    #     y_train = f['label_array'].value.astype(int)
    #     # # y_values is not used
    #     # y_values = f['label_values'].value
    #     y_names = f['label_names'].value
    #     print(script_name, 'Input original y_names:', y_names)
    #     print(max(y_train))

    with h5py.File(args.inputLabel, "r") as f:
            y_train = f['label_array'][()].astype(int)
            # # y_values is not used
            # y_values = f['label_values'].value
            y_names = f['label_names'][()]  
            print(script_name, 'Input original y_names:', y_names)
            print(max(y_train))

    if args.validationFeat is not None:
        with h5py.File(args.validationFeat, "r") as f:
            x_validation = f['feat'][()]

        with h5py.File(args.validationLabel, "r") as f:
            y_validation = f['label_array'][()].astype(int)
            # y_value = f['label_values'].value
            # y_names = f['label_names'].value

        idx_train = None
        idx_validation = None

    else:
        split_rate = 0.85

        print(script_name, 'Spliting data into train and validation, rate:', split_rate)
        y_org = y_train
        x_train, y_train, x_validation, y_validation, idx_train, idx_validation = tract_feat.split_data(x_train,
                                                                                                        y_train,
                                                                                                        split_rate)

    ''' The following augment steps are for down/up-sample'''

    if args.tract is None:
            if 1:  # dowmsample training data
                print(script_name, 'Feat Preprocessing - dowmsample with step:{}'.format(params['downsample_step']))
                # x_train, y_train = tract_feat.downsample(5, x_train, y_train)
                x_train, y_train = tract_feat.downsample(params['downsample_step'], x_train, y_train)
                print("x_train after downsample", x_train.shape)
                print("y_train_after downsample", y_train.shape)

    # TODO: uncomment it if necessary
    # ''' The folllowing steps are for re-grouping'''
    #
    # if params['single_multiple_tract_model']:
    #     print(script_name,
    #           'Train a multi-tract model, where each tract ONLY contains TRUE POSTIVE fibers, while all false postive fibers as another model.')
    #
    #     print(script_name,
    #           ' # Feat Preprocessing - combine subdiviations of some tracts including CBLM, SupT, and Others.')
    #     y_train, y_names, y_validation = tract_feat.combine_tract_subdiviations_and_merge_outliers(y_train, y_names,
    #                                                                                                y_validation=y_validation,
    #                                                                                                verbose=True)
    #
    # else:
    #     print(script_name,
    #           ' # Feat Preprocessing - combine subdiviations of some tracts including CBLM, SupT, and Others.')
    #     y_train, y_names, y_validation = tract_feat.combine_tract_subdiviations_and_keep_outlier_tracts(y_train,
    #                                                                                                     y_names,
    #                                                                                                     y_validation=y_validation,
    #                                                                                                     verbose=True)
    #
    #     if args.tract is None:
    #         print(script_name,
    #               'Train a multi-tract model, where each tract contains BOTH true and false positve fibers.')
    #         print(script_name, ' # Feat Preprocessing - combine true postive and false positve fibers together.')
    #         y_train, y_names, y_validation = tract_feat.combine_truepositive_and_falsepositive(y_train, y_names,
    #                                                                                            y_validation=y_validation,
    #                                                                                            verbose=True)
    #
    #     else:
    #         print(script_name, 'Train a tract-specific model to separate true and false postive fibers.')
    #         print(script_name, ' # Feat Preprocessing - extract tract:', args.tract)
    #         y_names, y_train, x_train, y_validation, x_validation, idx_train, idx_validation = \
    #             tract_feat.get_tract_specific_data(args.tract, y_names, y_train, x_train, y_validation=y_validation,
    #                                                x_validation=x_validation, idx_data=idx_train,
    #                                                idx_validation=idx_validation)

    ''' The following augment steps are for bilateral '''

    if params['bilateral_feature']:
        print(script_name, 'Make a bilateral feature for each fiber.')
        y_train, y_names, y_validation = tract_feat.bilateralize_feature(y_train, y_names, y_validation=y_validation,
                                                                         verbose=True)

        x_train, y_train = tract_feat.bilateral_X_data(x_train, fliped_copy=True, y_data=y_train)
        x_validation, _ = tract_feat.bilateral_X_data(x_validation)

    ''' Compress label values and label names. '''
    if 1:  # We should always do this.
        print(script_name, 'Compress label values (from 1 to N) and label names.')
        y_train, y_names, y_validation = tract_feat.compress_labels_and_names(y_train, y_names,
                                                                              y_validation=y_validation)
        # print(script_name, ' ## Compresed feature names:', y_names)

    # save labels
    h5_y_name = os.path.join(args.outputDir, args.outPrefix + '_label_names.h5')
    with h5py.File(h5_y_name, "w") as f:
        f.create_dataset('y_names', data=y_names)

    # save parameters
    params_name = os.path.join(args.outputDir, args.outPrefix + '_params.npy')
    np.save(params_name, params)

else:
    # Used only when debugging.
    print(script_name, 'Loading existing tmp feat files....')
    with h5py.File(tmp_h5_feat, "r") as f:
        x_train = f['x_train'][()]
        y_train = f['y_train'][()]
        x_validation = f['x_validation'][()]
        y_validation = f['y_validation'][()]
        y_names = f['y_names'][()]

print('===================================')
print(script_name, 'Start Training.')

print(script_name, 'x_train shape:', x_train.shape)
print(script_name, 'y_train shape:', y_train.shape)

print(script_name, 'x_validation shape:', x_validation.shape)
print(script_name, 'y_validation shape:', y_validation.shape)

# print(script_name, 'y_names:', y_names)
# num_classes = np.max(y_org).astype(int) + 1
num_classes = np.max(y_train).astype(int) + 1
print(num_classes)

y_train_mat = tf.keras.utils.to_categorical(y_train, num_classes)
y_validation_mat = tf.keras.utils.to_categorical(y_validation, num_classes)

output_model_path = os.path.join(args.outputDir, args.outPrefix + '_last_weights.h5')
if not os.path.exists(output_model_path):

    if args.architecture == 'CNN-simple':
        print(script_name, 'NN architecture:', args.architecture)

        model = nn_model.CNN_simple(x_train, y_train_mat, x_validation, y_validation_mat, num_classes, args.outputDir,
                                    data_augmentation=False)
        # model = nn_model.CNN_simple(x_train, y_train, x_validation, y_validation, num_classes, args.outputDir, epochs = 50, batch_size = 512, learning_rate = 0.01, data_augmentation=False)

    print(script_name, 'Saving trained model in:', args.outputDir)
    model.save(os.path.join(args.outputDir, args.outPrefix + '_last_weights.h5'))

else:
    print(script_name, 'Loading an existing model:', output_model_path)
    model = load_model(output_model_path)

y_prediction, prediction_report, con_matrix = nn_model.predict(model, x_validation, y_data=y_validation, y_name=y_names,
                                                               verbose=True)

with h5py.File(os.path.join(args.outputDir, args.outPrefix + '_validation_results.h5'), "w") as f:
    f.create_dataset('y_prediction', data=y_prediction)
    f.create_dataset('y_validation', data=y_validation)
    f.create_dataset('idx_validation', data=idx_validation)
    f.create_dataset('idx_train', data=idx_train)
    f.create_dataset('y_train', data=y_train)

with h5py.File(os.path.join(args.outputDir, args.outPrefix + '_validation_report.h5'), "w") as f:
    f.create_dataset('prediction_report', data=prediction_report)
    f.create_dataset('con_matrix', data=con_matrix)
