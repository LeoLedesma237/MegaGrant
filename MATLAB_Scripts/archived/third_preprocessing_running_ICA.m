% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% 1. Set the folder path to record the names of all the files there
% that need ICA run
folder = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed_before_ICA\\'; % replace with the path to your folder

% 2. Set the folder path where the excel files with interpolation data are
% saved
Excelfiles_folder = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_before_ICA\';

% 3. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed_after_ICA\\';

% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 
% % % % % % Part 1: Reading in all the files in specified folder % % % % %
files = dir(folder);

% Create a for loop that keeps only real files present from the folder
AllFileNames = {};
for i = 1:length(files)
    if files(i).isdir == 0 % check if the file is not a directory
        AllFileNames{end+1} = files(i).name;
    end
end

%Use the startsWith function to find the location of where the .eeg files
eegIndx = endsWith(AllFileNames, '.set');

%Use the location of the .eeg files to extract them and save only them
eegFiles = AllFileNames(eegIndx);

% Only Eyes Open files
eegIndx = startsWith(eegFiles, 'EyesOpen');
eegFiles = eegFiles(eegIndx);

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed_Files = dir(save_pathway);

% Create a for loop that keeps only real files present from the folder
All_Processed_Files = {};
for i = 1:length(Already_Processed_Files)
    if Already_Processed_Files(i).isdir == 0 % check if the file is not a directory
        All_Processed_Files{end+1} = Already_Processed_Files(i).name;
    end
end


% Removes the already processed files from the vector that will be input into the for loop 
for i = 1:length(eegFiles)
    for j = 1:length(All_Processed_Files)
        if strcmp(eegFiles{i}, All_Processed_Files{j})
            eegFiles{i} = [];
            break
        end
    end
end


% Remove empty cells from the vector
eegFiles = eegFiles(~cellfun('isempty',eegFiles));

% Problematic EEG files
filesToRemove = {'example1',
                 'example 2',
                  };


% Removes the remove files from the rsEEG files vector
for i = 1:length(eegFiles)
    for j = 1:length(filesToRemove)
        if strcmp(eegFiles{i}, filesToRemove{j})
            eegFiles{i} = [];
            break
        end
    end
end

% Remove empty cells from rsEEG files vector
eegFiles = eegFiles(~cellfun('isempty',eegFiles));


% % % Part 2: Running the cleaning script on the following files % % % %
% Run an automatic version of the code for the FIRST 100 FILES!!!!


for ii = 1:length(eegFiles)
    Current_eegFile = eegFiles{ii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
    
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    % Load in excel file of interest
    Excel_fileName = [Current_eegFile(1:end-3), 'set'];
    Load_Excel_file = [Excelfiles_folder Excel_fileName '.csv'];
    
    Excel_variables = xlsread(Load_Excel_file);
    Starting_Channels = Excel_variables(2);
    Interpolation_Num = Excel_variables(4);
    
    PCA_number = Starting_Channels - Interpolation_Num - 1 % The minus one represents re-referencing
    
    
    % Run ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'pca',PCA_number,'interrupt','on');
    
    % Saving the EEG data with ICA ran
    Save_FileName = strrep(Current_eegFile, '.set', '');
    EEG = pop_saveset(EEG, 'filename',Save_FileName,'filepath',save_pathway);

end