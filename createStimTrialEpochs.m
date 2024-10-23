%{
This script loads in the WashU/Utah CCEP data (stored as a series of .dat
files), loads their respective stim timings (.mat files), and exports the 
epoched data for subsequent processing and analysis with Python/MNE.

Created by Krista Wahlstrom (krista.wahlstrom@utah.edu) & Justin Campbell
11/29/23
%}

%% Set paths (change path when running on personal computer vs. workstation!)

% Add BCI2000 Tools
% addpath(genpath('/Users/justincampbell/Library/CloudStorage/Box-Box/INMANLab/BCI2000/BCI2000Tools')); % path on Justin's computer
addpath(genpath('C:\Users\Justin\Box\INMANLab\BCI2000\BCI2000Tools')); % path on INMAN Lab workstation


%% Load data, create epochs, & export (WashU)

% Find the patient folders in the data directory
% dataDir = '/Users/justincampbell/Library/CloudStorage/Box-Box/INMANLab/BCI2000/BLAES Aim 2.1/CCEPs/Data/WashU_Data'; % path on Justin's computer
dataDir = 'C:\Users\Justin\Box\INMANLab\BCI2000\BLAES Aim 2.1\CCEPs\Data\WashU_Data'; % path on INMAN Lab workstation
dirContents = dir(dataDir);
isDirectory = [dirContents.isdir] & ~ismember({dirContents.name}, {'.', '..'});
ptFolders = {dirContents(isDirectory).name};

for i = 1:length(ptFolders)
    pID = ptFolders{i};
    
    % Find .dat files
    ptDatFiles = {dir(fullfile(dataDir, pID, '*.dat')).name};
    
    % Find StimTimes.mat files
    ptStimTimeFiles = {dir(fullfile(dataDir, pID, '*StimTimes.mat')).name};
    
    % Calculate number of stim sessions (separate bipolar pairs)
    nStimSessions = size(ptDatFiles, 2);
    
    % Parse filename for stim chan pairs
    stimChanPairs = {};
    stimAmps = {};
    for ii = 1:nStimSessions
        splitString = strsplit(ptDatFiles{ii}, '_');
        stimChanPairs{ii} = splitString{2};
        stimAmps{ii} = splitString{3};
    end
    
    % Loop through each stim chan pair
    for ii = 1:length(stimChanPairs)
        chanPair = stimChanPairs{ii};
        stimAmp = stimAmps{ii};
    
        % Load .dat and .mat file
        ptDatFile = ptDatFiles{find(contains(ptDatFiles, chanPair))};
        ptStimTimeFile = ptStimTimeFiles{find(contains(ptStimTimeFiles, chanPair))};
        [signal, states, params] = load_bcidat(fullfile(dataDir, pID, ptDatFile)); % loads correct .dat file
        stimTimes = load(fullfile(dataDir, pID, ptStimTimeFile)); % loads correct stim time file
        stimTimes = stimTimes.StimulationTimestamps;
    
        % Create epochs
        fs = params.SamplingRate.NumericValue;
    
        % Loop through trials, grab epoch data
        epochData = cell(length(stimTimes),1);
        for iii = 1:length(stimTimes)
            stimTime = stimTimes{iii};
            epochPad = (fs / 1000) * 900; % 900 ms
            epochStart = stimTime - epochPad;
            epochEnd = stimTime + epochPad;
            epochIdxs = [epochStart:epochEnd];
            epochData{iii} = signal(epochIdxs, :);  
        end

        % Get channel labels
        chanNames  = params.ChannelNames.Value;
    
        epochData = cell2mat(reshape(epochData,1,1,[])); % time x channel x epoch   
    
        % Save epoched data & relevant file information
        saveVars = {'pID', 'chanPair', 'ptDatFile', 'ptStimTimeFile', 'fs', 'stimAmp', 'epochPad', 'epochData'};
        save(fullfile(dataDir, pID, strcat(pID, '_', chanPair, '_', stimAmp, '_StimEpochs.mat')), saveVars{:});
    end
end

clear all;

%% Load data, create epochs, & export (Utah)

clear all; clc;

% Find the patient folders in the data directory
% dataDir = '/Users/justincampbell/Library/CloudStorage/Box-Box/INMANLab/BCI2000/BLAES Aim 2.1/CCEPs/Data/Utah_Data'; % path on Justin's computer
dataDir = 'C:\Users\Justin\Box\INMANLab\BCI2000\BLAES Aim 2.1\CCEPs\Data\Utah_Data'; % path on INMAN Lab workstation
dirContents = dir(dataDir);
isDirectory = [dirContents.isdir] & ~ismember({dirContents.name}, {'.', '..'});
ptFolders = {dirContents(isDirectory).name};

for i = 1:length(ptFolders)
    pID = ptFolders{i};
    
     % Find .ns2 files
    ptNS2Files = {dir(fullfile(dataDir, pID, '*.ns2')).name};
    
    % Find CSMap files
    ptCSMapFiles = {dir(fullfile(dataDir, pID, 'CSMap*')).name};
    
    % Load .ns2 file
    [header, data] = fastNSxRead('File', fullfile(dataDir, pID, ptNS2Files{1}));
    
    % Load CSMap file
    CSMap = load(fullfile(dataDir, pID, ptCSMapFiles{1}));
    
    % Remove non-macroelectrode chans
    chanIdxs = CSMap.DepthElec;
    chanIdxs = chanIdxs(~ismember(chanIdxs, CSMap.MicroElec));
    chanNames = CSMap.ChanLabels(chanIdxs);

    % Parse trials to only include BLAES amygdala stim pairs
    BLAESStimFile = {dir(fullfile(dataDir, pID, '*_BLAESStimChans.xlsx')).name};
    BLAESStimPair = readtable(fullfile(dataDir, pID, BLAESStimFile{1}));
    BLAESStimPair = table2cell(BLAESStimPair);
    BLAESStimPair = sort(BLAESStimPair);
    
    stimElecs = CSMap.SEStr;
    BLAESStimTrials = [];
    for ii = 1:length(stimElecs)
        trialStimChans = stimElecs{ii};
        trialStimChans = sort(trialStimChans);
        if isequal(BLAESStimPair, trialStimChans)
            BLAESStimTrials = [BLAESStimTrials, ii];
        end
    end
    
    % Get stim times
    stimTimes = CSMap.SI(:,1); 
    BLAESStimTimes = stimTimes(BLAESStimTrials);
    BLAESStimTimes = BLAESStimTimes';
    
    % Create epochs
    epochData = cell(length(BLAESStimTimes),1);
    for ii = 1:length(BLAESStimTimes)
        stimTime = BLAESStimTimes(ii);
        epochPad = (CSMap.Fs / 1000) * 900; % 900 ms
        epochStart = stimTime - epochPad;
        epochEnd = stimTime + epochPad;
        epochIdxs = [epochStart:epochEnd];
        epochData{ii} = data(chanIdxs, epochIdxs);  
    end
    
    epochData = cell2mat(reshape(epochData,1,1,[]));
    epochData = permute(epochData, [2, 1, 3]); % time x channel x epoch  

    % Save epoched data & relevant file information
    fs = CSMap.Fs;
    stimAmp = strcat(string(CSMap.SL{1}(1)/1000), 'mA');
    chanPair = strcat(BLAESStimPair{1}, '-', BLAESStimPair{2});
    ptCSMapFile = ptCSMapFiles{1};
    ptNS2File = ptNS2Files{1};
    
    saveVars = {'pID', 'chanPair', 'ptCSMapFile', 'ptNS2File', 'fs', 'stimAmp', 'epochPad', 'epochData', 'BLAESStimTimes', 'chanNames'};
    save(fullfile(dataDir, pID, strcat(pID, '_', chanPair, '_', stimAmp, '_StimEpochs.mat')), saveVars{:});
end

