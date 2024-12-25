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
folder = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed'; % replace with the path to your folder

% 2. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_before_ICA';

% 3. Set the folder path that you want the CSV reports to be saved
save_pathway_csv = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\CSV_preprocessing';



% % % % % % Part 1: Reading in all the files in specified folder % % % % %
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
    StartingSec= EEG.xmax;
    
    %Remove DC offset
    EEG = pop_rmbase( EEG, [],[]);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    
    %Filter the data 0.5 - 30 Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',30);
    
    %Checks for channels that need interpolation
    EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
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
    
    % Other way of removing segments
    threshold = 100;
    
    % Find columns to delete
    columnsToDelete = any(EEG.data >= threshold, 1);
    
    % Delete the selected columns
    EEG.data(:, columnsToDelete) = [];
    
    % Find columns to delete
    columnsToDelete2 = any(EEG.data <= threshold*-1, 1);
    
    % Delete the selected columns
    EEG.data(:, columnsToDelete2) = [];
    
    % Rereference to whole head
    EEG = eeg_checkset( EEG );
    EEG = pop_reref( EEG, []);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 91,'gui','off'); 
    
    % TRACKING: Remaining minutes after segmentation rejection
    EEG_size = size(EEG.data);
    Remaining_Samples = EEG_size(2);
    RemainingSec = (Remaining_Samples/EEG.srate);
      
    % Save the data so it can be ready to use for ICA testing. Specifically
    % we need number of interpolated electrodes for 'PCA' argument. 
   
    DataLog = table( ...
        {Current_eegFile},...
        StartingChannels', ...
        Num_Interpolation', ...
        StartingSec,...
        RemainingSec,...
        'VariableNames', { ...
        'FileName',...
        'StartingChannels',...
        'NumInterpolated',...
        'StartingSec',...
        'RemainingSec'});


    % This sets the working directory where the CSV files will be saved
    cd(save_pathway_csv);
    
    % Save the file
    writetable(DataLog, [Current_eegFile '.csv']);
    
    % Saving the EEG data
    Save_FileName = Current_eegFile
    EEG = pop_saveset(EEG, 'filename',Save_FileName, ...
        'filepath',[save_pathway]);
end

