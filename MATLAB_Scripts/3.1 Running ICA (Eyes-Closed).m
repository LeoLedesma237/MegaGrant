% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% Set the working directory
cd('Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW')

% Specify the filename
filename = 'EEG Raw File Names2.xlsx';

% Read the data from the Excel file (Eyes-Closed)
data = readtable(filename, 'Sheet', 1);


% 1. Set the folder path to record the names of all the files there
input_filepath = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_before_ICA\'; 

% 2. Set directory for where channel information is saved
channel_info_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_preprocessing\';

% 3. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_after_ICA\';


% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 
fileNames = data.file_name2;

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed= dir(save_pathway);

% Extract .set files
Already_Processed = {Already_Processed(contains({Already_Processed.name}, ".set")).name};

% Remove files that have already been preprocessed
eegFiles = fileNames(~ismember(fileNames,Already_Processed));


% % % Part 2: Running the cleaning script on the following files % % % %
% Run an automatic version of the code for the FIRST 100 FILES!!!!
for ii = 1:length(eegFiles)
    Current_eegFile = eegFiles{ii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
    
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',input_filepath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    % Load the CSV with channel information
    ChanelInformationFile = [Current_eegFile '.csv'];
    ChannelInformation = readtable([channel_info_pathway ChanelInformationFile]);

    % Extract the required information
    Starting_Channels = ChannelInformation.StartingChannels;
    Interpolation_Num = ChannelInformation.NumInterpolated;
    
    % Calculate the PCA Number
    PCA_number = Starting_Channels - Interpolation_Num - 1 % The minus one represents re-referencing
    
    % Down sample data to 250 Hz to make ICA faste
    EEG = pop_resample( EEG, 250);

    % Run ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'pca',PCA_number,'interrupt','on');
    
    % Saving the EEG data with ICA ran
    Save_FileName = strrep(Current_eegFile, '.set', '');
    EEG = pop_saveset(EEG, 'filename',Save_FileName,'filepath',save_pathway);

end