%INMAN Laboratory
%Krista Wahlstrom, 6/30/23

%This is the reaction time/response time script for BLAES Aim 2.1
%Objects/Scenes for the retrieval test

function BLAES_Aim2_ItemScene_ResponseTime()

%% Load data

% Stimulus codes:
% practice images:1-8 
% study images:101-720 
% Image response period during Test phase:801-1420
% stimulation:1501 (no stim)-1502 (stim)
% fixation:1601-1786
% ISI (not used in the Test phase):1801
% instructions:1901-1905
% sync pulse:1906        

clear;
close all;

addpath(genpath(fullfile(cd,'BCI2000Tools')))

%Enter the subject ID and session/imageset
subjID         = 'BJH027';
imageset       = 'imageset1';

%Valid response keys
NoResponse     = [67 86];
YesResponse    = [78 66];
ResponseKeys   = [NoResponse, YesResponse]; % 67 sure no, 86 maybe no, 66 maybe yes, 78 sure yes

%% Get relevant .dat files
d = dir(fullfile(cd,'data',subjID,'Test',imageset,'*.dat'));

%% Extract behavioral data
iter2 = 1;
for file = 1:size(d,1)
    
    [~, states, param] = load_bcidat(fullfile(d(file).folder,d(file).name));
    pause(1);
    
    seq         = param.Sequence.NumericValue;
    seqResponse = seq;
    KD          = states.KeyDown;
    StimCode    = states.StimulusCode;
    KD          = double(KD);
    StimCode    = double(StimCode);
    
    %clean up sequence
    % select only image stimuli
    seq(seq<101) = [];
    seq(seq>800) = [];
    
    seqResponse(seqResponse<801)  = [];
    seqResponse(seqResponse>1500) = [];
    
    % ResponseStimCodeIdx is the "response period" period when the
    % image is onscreen, and the stimulus code is either that of the image
    % or a stimulus code between 801 and 1420, that
    % indicates the "response period"
    ResponseStimCodeIdx = {};
    for i = 1:size(seq,1)
        ResponseStimCodeIdx{i} = [find(StimCode==seq(i)); find(StimCode==seqResponse(i))];
    end
    
    
    
    
    %Get reaction time for first valid keypress after image onset
    iter = 1;
    ResponseTime = [];
    lastWindowPresses = [];
    for i = 1:length(KD)
        if ismember(KD(i), ResponseKeys) && iter <= size(ResponseStimCodeIdx,2) && ismember(i,ResponseStimCodeIdx{1,iter})
            ResponseTime(iter,1) = ((i - ResponseStimCodeIdx{1,iter}(1))/2); % reaction time in milliseconds 
            iter = iter + 1;
        end
        
    end



    %Isolate Key Presses
    
    % find key press events during the image stimulus code and during
    % the response period stimulus code (both periods when the image
    % is onscreen)
    
    % Take the second key press response if the patient responds too
    % quickly during the intial "no response" period and has to respond
    % again to advance the image
    KD_cell = [];
    for i = 1:size(seq,1)
        KD_cell{i} = KD(ResponseStimCodeIdx{i});
        KD_cell{i}(KD_cell{i}==0) = [];
        if length(KD_cell{i}) > 1
            KD_cell{i} = KD_cell{i}(end);
        end
    end
    
    % swap out for a double version of KD
    clear KD
    for i = 1:size(KD_cell,2)
        KD(i) = KD_cell{i};
    end
    clear KD_cell
    
    % Remove any key presses that were not the response keys
    % This shouldn't ever do anything because I always take the second key down event, which should also meet
    % the EarlyOffsetExpression and advance to the fixation cross
    BadKD = [];
    iter = 1;
    for i = 1:length(KD)
        if ~any(ismember(ResponseKeys,KD(i)))
            BadKD(iter) = i;
            iter = iter + 1;
        end
    end
    
    KD(BadKD) = 0;
    
    
    
%% Compile data into single matrix
    for i = 1:length(seq)
        collectRTData{iter2,1} = param.Stimuli.Value{6,seq(i)};          % picture filename
        collectRTData{iter2,2} = param.Stimuli.Value{9,seq(i)};          % item or scene
        collectRTData{iter2,3} = str2num(param.Stimuli.Value{8,seq(i)}); % stim or no stim
        collectRTData{iter2,4} = param.Stimuli.Value{10,seq(i)};         % old or new
        collectRTData{iter2,5} = seq(i);  % stimulus code for image
        collectRTData{iter2,6} = KD(i); % Key Press
        collectRTData{iter2,7} = ResponseTime(i);% reaction time from image onset to first valid key press
        iter2 = iter2 + 1;
    end
    
end

%% Analysis

%Separate reaction times into separate variables based on item/scene,
%old/new, stim/nostim
iter = 1;
item_nostim_RTs = [];
item_stim_RTs = [];
scene_nostim_RTs = [];
scene_stim_RTs = [];
item_new_RTs = [];
scene_new_RTs = [];


for i = 1:size(collectRTData,1)
    if contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old')
        item_nostim_RTs(size(item_nostim_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old')
        item_stim_RTs(size(item_stim_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old')
        scene_nostim_RTs(size(scene_nostim_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old')
        scene_stim_RTs(size(scene_stim_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'new')
        item_new_RTs(size(item_new_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'new')
        scene_new_RTs(size(scene_new_RTs,1)+1,1) = collectRTData{iter,7};
    end

    iter = iter +1;
end



%Separate reaction times into separate variables based hits, misses, false
%alarms, or correct rejections
iter = 1;
Hit_RTs = [];
Miss_RTs = [];
FA_RTs = [];
CR_RTs = [];


for i = 1:size(collectRTData,1)
    if contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Hit_RTs(size(Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Miss_RTs(size(Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        FA_RTs(size(FA_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        CR_RTs(size(CR_RTs,1)+1,1) = collectRTData{iter,7};
    end

    iter = iter +1;
end



%Separate reaction times into separate variables based item/scene and hits, misses, false
%alarms, or correct rejections
iter = 1;
Item_Hit_RTs = [];
Item_Miss_RTs = [];
Item_FA_RTs = [];
Item_CR_RTs = [];
Scene_Hit_RTs = [];
Scene_Miss_RTs = [];
Scene_FA_RTs = [];
Scene_CR_RTs = [];


for i = 1:size(collectRTData,1)
    if contains(collectRTData{iter,2},'item-') && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Item_Hit_RTs(size(Item_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Item_Miss_RTs(size(Item_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Item_FA_RTs(size(Item_FA_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Item_CR_RTs(size(Item_CR_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Scene_Hit_RTs(size(Scene_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Scene_Miss_RTs(size(Scene_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Scene_FA_RTs(size(Scene_FA_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && contains(collectRTData{iter,4},'new') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Scene_CR_RTs(size(Scene_CR_RTs,1)+1,1) = collectRTData{iter,7};
    end

    iter = iter +1;
end



%Separate reaction times into separate variables based item/scene,
%stim/nostim, old/new, yes/no
iter = 1;
Item_Nostim_Hit_RTs = [];
Item_Stim_Hit_RTs = [];
Item_Nostim_Miss_RTs = [];
Item_Stim_Miss_RTs = [];
Scene_Nostim_Hit_RTs = [];
Scene_Stim_Hit_RTs = [];
Scene_Nostim_Miss_RTs = [];
Scene_Stim_Miss_RTs = [];



for i = 1:size(collectRTData,1)
    if contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Item_Nostim_Hit_RTs(size(Item_Nostim_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Item_Stim_Hit_RTs(size(Item_Stim_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Item_Nostim_Miss_RTs(size(Item_Nostim_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'item-') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Item_Stim_Miss_RTs(size(Item_Stim_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Scene_Nostim_Hit_RTs(size(Scene_Nostim_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 78 || collectRTData{iter,6} == 66)
        Scene_Stim_Hit_RTs(size(Scene_Stim_Hit_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 0 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Scene_Nostim_Miss_RTs(size(Scene_Nostim_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    elseif contains(collectRTData{iter,2},'scene') && collectRTData{iter,3} == 1 && contains(collectRTData{iter,4},'old') && (collectRTData{iter,6} == 67 || collectRTData{iter,6} == 86)
        Scene_Stim_Miss_RTs(size(Scene_Stim_Miss_RTs,1)+1,1) = collectRTData{iter,7};
    end

    iter = iter +1;
end

%% Save Output
%Response Matrix
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_ResponseTime_Data_',imageset,'.mat')),'collectRTData')

%Item/Scene + Old/New + Stim/NoStim
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_item_new_RTs_',imageset,'.mat')),'item_new_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_item_nostim_RTs_',imageset,'.mat')),'item_nostim_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_item_stim_RTs_',imageset,'.mat')),'item_stim_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_scene_new_RTs_',imageset,'.mat')),'scene_new_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_scene_nostim_RTs_',imageset,'.mat')),'scene_nostim_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_scene_stim_RTs_',imageset,'.mat')),'scene_stim_RTs')

%Hits, Misses, False Alarms, Correct Rejections
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Hit_RTs_',imageset,'.mat')),'Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Miss_RTs_',imageset,'.mat')),'Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_FA_RTs_',imageset,'.mat')),'FA_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_CR_RTs_',imageset,'.mat')),'CR_RTs')

%Item/Scene + Old/New + Yes/No
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Hit_RTs_',imageset,'.mat')),'Item_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Miss_RTs_',imageset,'.mat')),'Item_Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_FA_RTs_',imageset,'.mat')),'Item_FA_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_CR_RTs_',imageset,'.mat')),'Item_CR_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Hit_RTs_',imageset,'.mat')),'Scene_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Miss_RTs_',imageset,'.mat')),'Scene_Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_FA_RTs_',imageset,'.mat')),'Scene_FA_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_CR_RTs_',imageset,'.mat')),'Scene_CR_RTs')


%Item/Scene + Old/New + Stim/NoStim Yes/No
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Nostim_Hit_RTs_',imageset,'.mat')),'Item_Nostim_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Stim_Hit_RTs_',imageset,'.mat')),'Item_Stim_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Nostim_Miss_RTs_',imageset,'.mat')),'Item_Nostim_Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Item_Stim_Miss_RTs_',imageset,'.mat')),'Item_Stim_Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Nostim_Hit_RTs_',imageset,'.mat')),'Scene_Nostim_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Stim_Hit_RTs_',imageset,'.mat')),'Scene_Stim_Hit_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Nostim_Miss_RTs_',imageset,'.mat')),'Scene_Nostim_Miss_RTs')
save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Scene_Stim_Miss_RTs_',imageset,'.mat')),'Scene_Stim_Miss_RTs')




end