% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% 1. Set the folder path to record the names of all the files there
% When opening up an existing dataset, double all back slashes and have two backslashes at the end
folder = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed\\'; % replace with the path to your folder

% 2. Set Line Noise Criterion
LineNoiseCriterion = 7;

% 3. Set down sampling rate (Higher the number the less length needed for
% godd ICA)
Sample_Rate = 500;

% 4. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed_before_ICA\\';

% 5. Set the folder path that you want the CSV reports to be saved
save_pathway_csv = 'Y:\\STUDY 1\\All EEG Files Organized\\Preprocessed_RAW\\RAW_eyes_open_and_eyes_closed_before_ICA\\';


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
filesToRemove = {'EyesOpenРюмина Е.Е._RAW.set', % weird named
                 'EyesOpenRAW_97676.set', % wont load channels
                 'EyesOpen82511_RAW.set', %Empty dataset
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

    %Removing not needed channels
    %For this dataset it's EOGs and Aux ports
    EEG = pop_select( EEG, 'nochannel',{'Aux1','Aux2','VEOG','HEOG'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off');
    
    %Add channels
    EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\lledesma.TIMES\\Documents\\MATLAB\\eeglab2022.0\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %TRACKING: starting channel number and how long the EEG recording is
    StartingChannels = EEG.nbchan;
    StartingMin = EEG.xmax/60;
    
    %Remove DC offset
    EEG = pop_rmbase( EEG, [],[]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    
    %Filter the data 0.5 - 45 Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',45);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'setname','ID#_Filtered','gui','off');
    
    
    %Keep it at 500 Hz; the higher the sampling rate, the better the ICA
    EEG = pop_resample( EEG, Sample_Rate);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname','ID#_resampled','gui','off');
    
    %Checks for channels that need interpolation
    EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',LineNoiseCriterion,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    
    % The following if and else statement is IDs that have/do not have channels
    % that need interpolation. If they need interpolation they go into the if
    % statement. If not then they are directed to the code in the else.
    
    if length(fieldnames(EEG1.etc)) > 1
        
        %Returns the names of the channels that need to be interpolated
        Bad_Channels = find(EEG1.etc.clean_channel_mask == 0);
    
        %TRACKING: Number of channels that were interpolated
        Num_Interpolation = length(Bad_Channels);
    
        % Inteporlate the channels based on the object that we saved
        EEG = pop_interp(EEG, Bad_Channels', 'spherical');
    
    
    else
    
        %TRACKING: Number of channels that were NOT interpolated
        Num_Interpolation = 0;
    
    end
    
    % This following code is where the automatic removal of bad 'segments'
    % begins. Based on the results from the debugging code, the default for
    % 'segmentation' rejection is adequate and does a good job at cleaning
    % data. Compared to manual techniques, it is less stricter!

    % Other way of removing segments
    threshold = 75;
    
    % Find columns to delete
    columnsToDelete = any(EEG.data >= threshold, 1);
    
    % Delete the selected columns
    EEG.data(:, columnsToDelete) = [];
    
    % Find columns to delete2
    threshold2 = - 75;
    columnsToDelete2 = any(EEG.data <= threshold2, 1);
    
    % Delete the selected columns
    EEG.data(:, columnsToDelete2) = [];
    
    % Rereference to whole head
    EEG = eeg_checkset( EEG );
    EEG = pop_reref( EEG, []);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 91,'gui','off'); 
    
    % TRACKING: Remaining minutes after segmentation rejection
    EEG_size = size(EEG.data);
    Remaining_Samples = EEG_size(2);
    RemainingMin = (Remaining_Samples/500)/60;
      
    
    % Save the data so it can be ready to use for ICA testing
    % First create like a data frame on MATLAB which is lowkey a pain in the
    % ass. This will tell us useful information about the data file, especially
    % to get us the proper PCA number
    
    RowNum = 1;
    VariableName = ["SubjectID" "RowNum" "StartingChannelNum" "StartingMin" "InterpolationNum" "RemainingMin"];
    VariableValuesNum = [RowNum StartingChannels StartingMin Num_Interpolation RemainingMin];
    VariableValuesNum2 = num2cell(VariableValuesNum);
    VariableValues = horzcat(Current_eegFile, VariableValuesNum2);
    DataLog = vertcat(VariableName,VariableValues);
    
    % This sets the working directory where the CSV files will be saved
    cd(save_pathway_csv);
    
    % Set the name for the CSV file that will be saved
    DataLogName = strcat(Current_eegFile,'.csv');
    
    % Saving the CSV file
    writematrix(DataLog, DataLogName);
    
    % Saving the EEG data
    Save_FileName = Current_eegFile
    EEG = pop_saveset(EEG, 'filename',Save_FileName,'filepath',save_pathway);

end

