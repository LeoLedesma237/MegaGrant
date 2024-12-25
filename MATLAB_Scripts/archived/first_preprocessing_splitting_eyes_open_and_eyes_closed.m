% The following script will be separating eyes open from eyes closed in the
% MegaGrants rsEEG data. The files names were obtaine from an r script.
% most of the rsEEG files are in a specific folder (about 600 or so). Any
% files that cause errors will be removed over time from the file

% Load in EEGLAB
cd('C:\Users\lledesma.TIMES\Documents\MATLAB\eeglab2022.0')
eeglab

% 1. Set the folder path to record the names of all the files there
folder = 'Y:\STUDY 1\All EEG Files Organized\RAW\'; % replace with the path to your folder

% 2. Set the folder path that you want the EEG data saved in
save_pathway = 'Y:\STUDY 1\All EEG Files Organized\Preprocessed_RAW\RAW_eyes_open_and_eyes_closed';

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
eegIndx = endsWith(AllFileNames, '.eeg');

%Use the location of the .eeg files to extract them and save only them
eegFiles = AllFileNames(eegIndx);


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

% Change the vector of names from the processed files from .set/.fdt to
% .eeg
All_Processed_Files_removed_set = cellfun(@(str) str(1:end-3), All_Processed_Files, 'UniformOutput', false);
All_Processed_Files_added_eeg = cellfun(@(str) [str 'eeg'], All_Processed_Files_removed_set, 'UniformOutput', false);

% We need to remove EyesOpen and EyesClosed from the vector name too
% Remove "EyesOpened" and "EyesClosed" from each string
All_Processed_Files_added_eeg = cellfun(@(str) strrep(str, 'EyesOpen', ''), All_Processed_Files_added_eeg, 'UniformOutput', false);
All_Processed_Files_added_eeg = cellfun(@(str) strrep(str, 'EyesClosed', ''), All_Processed_Files_added_eeg, 'UniformOutput', false);


% Removes the already processed files from the vector that will be input into the for loop 
for i = 1:length(eegFiles)
    for j = 1:length(All_Processed_Files_added_eeg)
        if strcmp(eegFiles{i}, All_Processed_Files_added_eeg{j})
            eegFiles{i} = [];
            break
        end
    end
end


% Remove empty cells from the vector
eegFiles = eegFiles(~cellfun('isempty',eegFiles));


% Problematic EEG files
filesToRemove = {'12473_RAW.eeg', 
                 '13189_RAW.eeg',
                 '15124_RAW.eeg',
                 '15590_RAW.eeg',
                 '15959_RAW.eeg',
                 '19487_RAW.eeg',
                 '19628_RAW.eeg',
                 '21139_RAW.eeg',
                 '22095_RAW.eeg',
                 '22264_RAW.eeg',
                 '23507_RAW.eeg',
                 '23567_RAW.eeg',
                 '24096_RAW.eeg',
                 '25123_RAW.eeg',
                 '25264_RAW.eeg',
                 '26014_RAW.eeg',
                 '27151_RAW.eeg',
                 '28222_RAW.eeg',
                 '28787_RAW.eeg',
                 '29323_RAW.eeg',
                 '30367_RAW.eeg',
                 '30367_RAW2.eeg',
                 '30518_RAW.eeg',
                 '30663_RAW.eeg',
                 '33500_RAW.eeg',
                 '34392_RAW.eeg',
                 '35509_RAW.eeg',
                 '35509_RAW_2.eeg',
                 '36936_RAW.eeg',
                 '39330_RAW.eeg',
                 '39601_RAW.eeg',
                 '39739_RAW.eeg',
                 '41207_RAW.eeg',
                 '41684_RAW.eeg',
                 '41869_RAW.eeg',
                 '43563_RAW.eeg',
                 '44168__RAW.eeg',
                 '44520_RAW.eeg',
                 '44715_RAW.eeg',
                 '47829_RAW.eeg',
                 '47884_RAW.eeg',
                 '48448_RAW.eeg',
                 '48633_RAW.eeg',
                 '48647_RAW.eeg',
                 '48818_RAW.eeg',
                 '50548_RAW.eeg',
                 '51344_RAW.eeg',
                 '52858_RAW.eeg',
                 '53437_RAW.eeg',
                 '54093_RAW.eeg',
                 '54498_RAW.eeg',
                 '55648_RAW.eeg',
                 '55745_RAW.eeg',
                 '57475_RAW.eeg',
                 '57830_RAW.eeg',
                 '60474_RAW.eeg',
                 '60942_RAW.eeg',
                 '63280_RAW.eeg',
                 '64220_RAW.eeg',
                 '66444_RAW.eeg',
                 '67168_RAW.eeg',
                 '69031_RAW.eeg',
                 '69951_RAW.eeg'
                 '72007_RAW.eeg',
                 '72585_RAW.eeg',
                 '72619_RAW.eeg',
                 '73817_RAW.eeg',
                 '74313_RAW.eeg',
                 '74743_RAW.eeg',
                 '74743_RAW_2.eeg',
                 '78505_RAW.eeg',
                 '81303_RAW.eeg',
                 '82384_RAW.eeg',
                 '85137_RAW.eeg',
                 '86796_RAW.eeg',
                 '87292_RAW.eeg',
                 '88630_RAW.eeg',
                 '88787_RAW.eeg',
                 '89864_RAW.eeg',
                 '90089_RAW.eeg',
                 '91086_RAW.eeg',
                 '92332_RAW.eeg',
                 '93481_RAW.eeg',
                 '94394_RAW.eeg',
                 '96037_RAW.eeg',
                 '96359_RAW.eeg',
                 '96881_RAW.eeg',
                 '97543_RAW.eeg',
                 '97676_RAW.eeg',
                 '97943_RAW.eeg',
                 '98539_RAW.eeg',
                 '99495_RAW.eeg',
                 '99589_RAW.eeg',
                 'RAW_47454.eeg',
                 'RAW_57123.eeg'
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

% Start the for loop
for iii = 1:length(eegFiles)

CurrentFileName = eegFiles{iii}
fullpath = strcat(folder,CurrentFileName);

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

% Take the latencies and divide by 100 to convert them into seconds
S1_Latency = S1Row{2}/1000; % The start (sec) of the eyes closed condition
S2_Latency = S2Row{2}/1000; % The start (sec) of the eyes opened condition
S3_Latency = S3Row{2}/1000; % The end (sec) of the eyes open condition


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
