%%%%%%%%%%%%%%%%%%%% CONFIGURATION NEEDED %%%%%%%%%%%%%%%%%%%%5
% Set the pathway to the MegaGrant Scripts
MegaGrant_GH = 'C:\Users\lledesma\Documents\GitHub\MegaGrant\';

% Set pathway to run EEGLAB
EEGLAB_Path = 'C:\Users\lledesma\Documents\MATLAB\eeglab2024.2';
addpath(EEGLAB_Path)
eeglab

% Set Pathway to customized functions
%Functions_path = append(ONR_MBAP,'\Preprocessing\GeneralFunctions\');
%addpath(Functions_path)

% Specify where the data is saved
Data_Location = '\\files.times.uh.edu\Labs\MIR_Lab\MEGAGRANT\STUDY 1\All EEG Files Organized\';

% Change directory to the location of the MATLAB scripts
MATLABScripts = append(MegaGrant_GH,'Preprocessing');
cd(MATLABScripts)


%%%%%%%%%%% Running the Cleaning Code %%%%%%%%%%%%%%%
