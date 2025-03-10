% READ ME: This MainScript only works if you have the EEG wiki
% available on your computer with the custom made functions to
% clean and process rsEEG data. 


%%%%%%%%%%%%%%%%%%%% CONFIGURATION NEEDED %%%%%%%%%%%%%%%%%%%%5
% Set pathway to run EEGLAB
EEGLAB_Path = 'C:\Users\lledesma\Documents\MATLAB\eeglab2024.2';
addpath(EEGLAB_Path)
eeglab

% Set Pathway to EEG Functions
EEGFUN_path = append('C:\Users\lledesma\Documents\GitHub\EEG\EEG_Cleaning');
addpath(EEGFUN_path)


%%%%%%%%%%%%%%%% Clean the rsEEG data %%%%%%%%%%%%%%%%%%%%

% Inset the needed parameters
EEG_dir = 'C:\Users\lledesma\Documents\MegaGrant\03_Eyes_Open_Eyes_Closed_Separated\';
EEG_dir_info = dir(EEG_dir);
EEG_filenames = {EEG_dir_info(contains({EEG_dir_info.name}, ".set")).name};
EEG_fullpath = append(EEG_dir, EEG_filenames);
EEG_save_path = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_Data\';
EEG_csv_save_path = 'C:\Users\lledesma\Documents\MegaGrant\04_Clean_EEG_QS_CSV\';
EEG_excel_save_path = 'C:\Users\lledesma\Documents\MegaGrant\';
chan_loc = 'C:\\Users\\lledesma\\Documents\\MATLAB\\eeglab2024.2\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc';
input_ex = '_RAW.set';
output_ex = '_RAW_cleaned.set';

% Run the rsEEG cleaning code
clean_wet_rseeg(EEG_fullpath, '.set', EEG_save_path, EEG_csv_save_path, ...
    EEG_excel_save_path, 'No', chan_loc, 62, 500, 70, input_ex, output_ex )


