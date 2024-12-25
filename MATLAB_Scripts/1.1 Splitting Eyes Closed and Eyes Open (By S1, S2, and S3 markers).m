% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% Set the working directory
cd('Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW')

% Specify the filename
filename = 'EEG Raw File Names.xlsx';

% Read the data from the Excel file
data = readtable(filename, 'Sheet', 1);


% 1. Set Input filepath 
input_filepath = 'Y:\STUDY 1\All EEG Files Organized\RAW';

% 2. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed';

% % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 
eegFiles = data.all_eeg;

% Remove redundancies
% Only unprocessed files will be ran by the for loop below
Already_Processed= dir(save_pathway);

% Extract .set files
Already_Processed = {Already_Processed(contains({Already_Processed.name}, ".set")).name};

% Change the .set files to .eeg files
Already_Processed = append(erase(Already_Processed, '.set'), '.eeg');

% Remove the 'EyesOpen' and 'EyesClosed' part from the file name
Already_Processed = erase(Already_Processed, 'EyesOpen');
Already_Processed = erase(Already_Processed, 'EyesClosed');

% Keep unique strings
Already_Processed = unique(Already_Processed);

% Keep eegFiles that have not been processed yet
eegFiles = eegFiles(~ismember(eegFiles, Already_Processed));

filesToRemove = {'example1'};

% Remove problematic EEG files
eegFiles = eegFiles(~ismember(eegFiles, filesToRemove));



% Start the for loop
for iii = 1:length(eegFiles)

    CurrentFileName = eegFiles{iii}
    fullpath = strcat(input_filepath,'\',CurrentFileName);
    
    %Import data - change the name of the ID
    EEG = pop_fileio(fullpath, 'dataformat','auto');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','ID#_Imported','gui','off');
    
    
    % The markers show the latency of when they start, meaning at what data
    % sample it begins. We have to turn this into seconds so we can segment the
    % data. To do this, take the data sample and divide it by the sampling rate
    % (1000). 
    % Extract latency information from markers of interest
    Marker_Type = extractfield(EEG.event ,'type');
    Marker_Latency = num2cell(extractfield(EEG.event ,'latency'));
    
    % Take markers and their latency and merge them into a cell array
    Marker_array = [Marker_Type; Marker_Latency];
    Marker_array = Marker_array';
    
    % Use this formula to bring forth the latency for the marker of interest
    S1rowIdx = strcmp(Marker_array(:,1), 'S  1');
    S2rowIdx = strcmp(Marker_array(:,1), 'S  2');
    S3rowIdx = strcmp(Marker_array(:,1), 'S  3');
    
    S1Row = Marker_array(S1rowIdx,:);
    S2Row = Marker_array(S2rowIdx,:);
    S3Row = Marker_array(S3rowIdx,:);
    
    % Take the latencies and divide by 1000 to convert them into seconds
    S1_Latency = S1Row{2}/EEG.srate; % The start (sec) of the eyes closed condition
    S2_Latency = S2Row{2}/EEG.srate; % The start (sec) of the eyes opened condition
    S3_Latency = S3Row{2}/EEG.srate; % The end (sec) of the eyes open condition
    
    
    Eyes_Closed_Sec = S2_Latency - S1_Latency;
    Eyes_Open_Sec = S3_Latency - S2_Latency;
    
    % Use the marker to segment the daya for eyes open and eyes closed
    Closed_EEG = pop_epoch( EEG, {  'S  1'  }, [0  Eyes_Closed_Sec], 'epochinfo', 'yes');
    Closed_EEG = eeg_checkset( Closed_EEG );
    Closed_EEG = pop_rmbase( Closed_EEG, [],[]);
    
    Open_EEG = pop_epoch( EEG, {  'S  2'  }, [0  Eyes_Open_Sec], 'newname', 'ID#_Imported epochs', 'epochinfo', 'yes');
    Open_EEG = eeg_checkset( Open_EEG );
    Open_EEG = pop_rmbase( Open_EEG, [],[]);
    
    % Name eyes closed data
    ID_string = eegFiles{iii};
    Eyes_Closed = 'EyesClosed';
    Eyes_Open = 'EyesOpen';
    FileName1 = strcat(Eyes_Closed,ID_string);
    FileName2 = strcat(Eyes_Open,ID_string);
    
    % save data
    Closed_EEG = pop_saveset( Closed_EEG, 'filename',FileName1,'filepath',save_pathway);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    Open_EEG = pop_saveset( Open_EEG, 'filename',FileName2,'filepath',save_pathway);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    % File Tracker
    Current_file = eegFiles{iii};

end
