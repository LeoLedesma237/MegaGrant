% 1. Set the folder path to record the names of all the files there
folder = append(Data_Location, 'Preprocessed_RAW\RAW_eyes_open_and_eyes_closed\');

% 2. Set the folder path that you want the EEG data saved in
save_pathway = append(Data_Location, 'Preprocessed_RAW\RAW_eyes_open_and_eyes_closed_cleaned');

% 3. Set the folder path that you want the CSV reports to be saved
save_pathway_csv = append(Data_Location, 'Preprocessed_RAW\CSV_preprocessing\');


% % % % % % Part 1: Reading in all the files in specified folder % % % % %
% % % % % % REMAINING CODE IS AUTOMATIC % % % % % % % % 

% Specify the filename
filename = append(Data_Location, 'Preprocessed_RAW\EEG_Raw_File_Names2.xlsx');

% Read the data from the Excel file (Eyes-Closed)
data = readtable(filename, 'Sheet', 1);
eegFiles = data.file_name2;


%%%%%
%%%%%%%% Part 2: Removing Processed Files From EEG Cleaning Pipeline 
%%%%

% Create a variable for the current condition saved pathway
Already_Processed = {dir(save_pathway).name};

% Remove files that have already been processed
eegFiles = eegFiles(~ismember(eegFiles, Already_Processed));

% Problematic EEG files
filesToRemove = {'example1', 
                 'example2'};

% Obtain the number of available cores
numCores = feature('numcores');
disp(['Number of available cores: ', num2str(numCores)]);

% Start the recruting these cores
parpool(numCores); 

% Set N, the number of iterations to do
N = length(eegFiles);

% Variables to be saved for each iteration
InitialSec = zeros(1,N);
StartingChannels = zeros(1,N);
rank1 = zeros(1,N);
Num_Interpolation = zeros(1,N);
BadChannelsString = cell(1,N);
rank2 = zeros(1,N);
PCA_number = zeros(1,N);
RejectedEyeComponentNum = cell(1,N);
RejectedMuscleComponentNum = cell(1,N);
CompRejsString = cell(1,N);
RemainingSec = zeros(1,N);
Percent_Remaining = zeros(1,N);


% % % Part 2: Running the cleaning script on the following files % % % %
parfor ii = 1:N
    try

    % Load in the EEG file
    Current_eegFile = eegFiles{ii} %MUST BE SQUIGGLY LINE FOR SEGMENTATION TO WORK!!!!
    
    %Import data - change the name of the ID
    EEG = pop_loadset('filename',Current_eegFile,'filepath',folder);

    %Removing not needed channels
    %For this dataset it's EOGs and Aux ports
    EEG = pop_select( EEG, 'nochannel',{'Aux1','Aux2', 'VEOG', 'HEOG'});
    
    %Add channels
    EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\lledesma\\Documents\\MATLAB\\eeglab2024.2\\plugins\\dipfit\\standard_BEM\\elec\\standard_1005.elc');

    % Save starting Rank
    rank1(ii) = rank(EEG.data);

    % Save the intial length of the EEG recording
    EEG_size = size(EEG.data);
    Remaining_Samples = EEG_size(2);
    InitialSec(ii) = (Remaining_Samples/EEG.srate);
    
    %TRACKING: starting channel number and how long the EEG recording is
    StartingChannels(ii) = EEG.nbchan;
    
    %Filter the data 0.5 - 30 Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',30);
    
    %Checks for channels that need interpolation and runs ASR
    EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','on','Distance','Euclidian');
        
    % The following if and else statement is IDs that have/do not have channels
    % that need interpolation. If they need interpolation they go into the if
    % statement. If not then they are directed to the code in the else.
    if  sum(ismember(fieldnames(EEG1.etc), 'clean_channel_mask')) == 1
            
        %Returns the names of the channels that need to be interpolated
        Bad_Channels = {find(EEG1.etc.clean_channel_mask == 0)};
        
        %TRACKING: Number of channels that were interpolated
        Num_Interpolation(ii) = length(Bad_Channels{1});
        
        % Inteporlate the channels based on the object that we saved
        EEG = pop_interp(EEG, Bad_Channels{1}', 'spherical');
        
    else
        
        % Returns zero for Bad_Channels
        Bad_Channels = {0};
    
        %TRACKING: Number of channels that were NOT interpolated
        Num_Interpolation(ii) = 0;
        
    end
    
    % Convert Bad Channels into a string variable
    BadChannelsStr = sprintf('%g, ', Bad_Channels{1}); % Create a comma-separated string
    BadChannelsStr(end-1:end) = []; % Remove the trailing comma and space

    % Save the Bad Channel information
    BadChannelsString{ii} = {BadChannelsStr};
    
    % Rereference to whole head
    EEG = eeg_checkset( EEG );
    EEG = pop_reref( EEG, []);
    
    % Save the EEG rank of the data
    rank2(ii) = rank(EEG.data);
      
    % Calculate the number needed for PCA
    PCA_number(ii) = StartingChannels(ii) - Num_Interpolation(ii) - 1; % The minus one represents referencing to whole head
    
    % Run ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'pca',PCA_number(ii),'interrupt','on');

    % Load IC Label
    EEG = pop_iclabel(EEG, 'default');
    
    % Identify eye and muscle components
    eye_components = find(EEG.etc.ic_classification.ICLabel.classifications(:, 3) > 0.75);
    muscle_components = find(EEG.etc.ic_classification.ICLabel.classifications(:, 2) > 0.75);

    % Save the component if it is in the top 15
    eye_components = eye_components(eye_components < 15);
    muscle_components = muscle_components(muscle_components < 15);

    % Save this information in an object 
    RejectedEyeComponentNum{ii} = {eye_components};
    RejectedMuscleComponentNum{ii} = {muscle_components};

    % Combine eye and muscle component
    components_to_reject = unique([eye_components; muscle_components]);

    % Remove eye components 
    EEG = pop_subcomp(EEG, components_to_reject, 0);

    % Segmentation Rejection (75 microVolts)
    threshold_volt = 75;
        
    % Find columns to delete
    columnsToDelete = any(EEG.data >= threshold_volt | EEG.data <= threshold_volt*-1, 1);
        
    % Delete the selected columns
    EEG.data(:, columnsToDelete) = [];
        
    % Save the length of the EEG recording after segmentation rejection
    EEG_size = size(EEG.data);
    Remaining_Samples = EEG_size(2);
    RemainingSec(ii) = (Remaining_Samples/EEG.srate);

    % Obtain the percentage of the recording remaining
    Percent_Remaining(ii) = round(RemainingSec(ii)/InitialSec(ii)*100,2);

    % Save the data so it can be ready to use for ICA testing. Specifically
    % we need number of interpolated electrodes for 'PCA' argument. 
   
    % Create a table with the outputs of the cleaning process
    Output_Table = table( ...
            {Current_eegFile}, ...
            InitialSec(ii)',...
            StartingChannels(ii)',...
            rank1(ii)',...
            Num_Interpolation(ii)', ...
            BadChannelsString{ii}',...
            rank2(ii)',...
            PCA_number(ii)',...
            RejectedEyeComponentNum{ii}',...
            RejectedMuscleComponentNum{ii}',...
            RemainingSec(ii)',...
            Percent_Remaining(ii)',...
            {'-'},...
            'VariableNames', { ...
            'File_Name',...
            'Start_Recording_Sec',...
            'Channel_Num',...
            'EEG_Rank1',...
            'Interpolated_Chan_Num',...
            'Interpolated_Channels',...
            'EEG_Rank2',...
            'PCA_Number',...
            'Eye_Component',...
            'Muscle_Component',...
            'Remaining_Recording_Sec',...
            'Percent_Remaining',...
            'Error'})

    % Save the file
    writetable(Output_Table, append(save_pathway_csv,strrep(Current_eegFile, ".set", ".csv")));
    
    % Saving the EEG data
    EEG = pop_saveset(EEG, 'filename',Current_eegFile, ...
            'filepath',save_pathway);

    catch ME

        % Save results only if the value hasn't already been set
        if isempty(InitialSec(ii))
            InitialSec(ii) = 0;
        end
        if isempty(rank1(ii))
            rank1(ii) = 0;
        end
        if isempty(StartingChannels(ii))
            StartingChannels(ii) = 0;
        end
        if isempty(Num_Interpolation(ii))
            Num_Interpolation(ii) = 0;
        end
        if isempty(BadChannelsString{ii})
            BadChannelsString{ii} = '-';
        end
        if isempty(rank2(ii))
            rank2(ii) = 0;
        end
        if isempty(PCA_number(ii))
            PCA_number(ii) = 0;
        end
        if isempty(RejectedEyeComponentNum{ii})
            RejectedEyeComponentNum{ii} = '-';
        end
        if isempty(RejectedMuscleComponentNum{ii})
            RejectedMuscleComponentNum{ii} = '-';
        end
        if isempty(RemainingSec(ii))
            RemainingSec(ii) = 0;
        end
        if isempty(Percent_Remaining(ii))
            Percent_Remaining(ii) = 0;
        end
        % Create the output table
        Output_Table = table( ...
            {Current_eegFile}, ...
            InitialSec(ii)',...
            StartingChannels(ii)',...
            rank1(ii)',...
            Num_Interpolation(ii)', ...
            BadChannelsString{ii}',...
            rank2(ii)',...
            PCA_number(ii)',...
            RejectedEyeComponentNum{ii}',...
            RejectedMuscleComponentNum{ii}',...
            RemainingSec(ii)',...
            Percent_Remaining(ii)',...
            {ME.message}',...
            'VariableNames', { ...
            'File_Name',...
            'Start_Recording_Sec',...
            'Channel_Num',...
            'EEG_Rank1',...
            'Interpolated_Chan_Num',...
            'Interpolated_Channels',...
            'EEG_Rank2',...
            'PCA_Number',...
            'Eye_Component',...
            'Muscle_Component',...
            'Remaining_Recording_Sec',...
            'Percent_Remaining',...
            'Error'})

        % Save the file
        writetable(Output_Table, append(save_pathway_csv,strrep(Current_eegFile, ".set", ".csv")));
    
    end

end

% Release the recruited cores
delete(gcp('nocreate'))

