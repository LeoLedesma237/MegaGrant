% Load in EEGLAB
cd('C:\Users\lledesma\Documents\MATLAB\eeglab2024.2')
eeglab

%1. Set the location to excel file with eyes open infomation
excel_loc = '\\files.times.uh.edu\labs\MIR_Lab\MEGAGRANT\STUDY 1\MODIFIED_DS\EEG\rsEEG\';

% 2. Set the folder path to record the names of all the files there
% that need ICA run
input_filepath = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_after_ICA\'; % replace with the path to your folder

% 3. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_after_component_rejection\';

% 4. Set the folder path that you want the CSV reports to be saved
save_pathway_csv = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_components rejected\';


% % % % % % Part 1: Reading in all the files in specified folder % % % % %
% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 

% Specify the filename
filename = append(excel_loc, 'EEG_Raw_File_Names2.xlsx');

% Read the data from the Excel file (Eyes-Open)
data = readtable(filename, 'Sheet', 2);

% Save this information into fileNames
fileNames = data.file_name2;

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed= dir(save_pathway);

% Extract .set files
Already_Processed = {Already_Processed(contains({Already_Processed.name}, ".set")).name};

% Remove files that have already been preprocessed
eegFiles = fileNames(~ismember(fileNames,Already_Processed));


% % % Part 2: Running the cleaning script on the following files % % % %
for ii = 1:length(eegFiles)

    Current_eegFile = eegFiles{ii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
        
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',input_filepath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

    % Run MARA
    [ALLEEG,EEG,CURRENTSET] = processMARA(ALLEEG,EEG,CURRENTSET)
    EEG = eeg_checkset( EEG );

    % Record number of components flagged for rejection
    Rejected_Component = find(EEG.reject.gcompreject == 1);
    RejectedComponentNum = length(Rejected_Component);
    
    % Reject the flagged components
    EEG = pop_subcomp(EEG, Rejected_Component, 0);
    
    % Save output into DataLog    
    DataLog = table( ...
        {Current_eegFile},...
        RejectedComponentNum', ...
        'VariableNames', { ...
        'FileName',...
        'CompRejNum'});

    % This sets the working directory where the CSV files will be saved
    cd(save_pathway_csv);
    
    % Save the file
    writetable(DataLog, [Current_eegFile '.csv']);
    
    % Saving the EEG data
    Save_FileName = Current_eegFile
    EEG = pop_saveset(EEG, 'filename',Save_FileName, ...
        'filepath',[save_pathway]);

end

