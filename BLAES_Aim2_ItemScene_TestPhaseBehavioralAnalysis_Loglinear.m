%INMAN Laboratory
%Krista Wahlstrom and James Swfit, 2023

%This is the behavioral analysis script for BLAES Aim 2.1 for the Test
%Phase (retreival) session. It includes a correction for Hit Rates and
%False Alarm rates that are 0 or 1 using the Loglinear (Hautus 1995)
%approach (0.5 added to the number of hits and 0.5 added to the number of false alarms 
% and 1 added to both the # of signal trials and # of noise trials. These corrections are
%made REGARDLESS if extreme 0 or 1 values are present for the False Alarm
%and Hit Rates). The corrections are made within the dprime figures,
%and False Alarm occurrences/Hit occurrences are not altered in their
%respective figures (still reflect the actual # of FAs or Hits the
%participant had).

function BLAES_Aim2_ItemScene_TestPhaseBehavioralAnalysis_Loglinear()

%% Load data

% Stimulus codes:
% Study/Encoding images:101-720 
% Image response period during Test/Retrieval phase:801-1420
% Stimulation:1501 (no stim), 1502 (stim)
% Fixation cross:1601-1786
% Instructions:1901-1905
% Sync pulse:1906        

clear;
close all;

addpath(genpath(fullfile(cd,'BCI2000Tools')))

%Enter the subject ID and session/imageset
subjID         = 'BJH027';
imageset       = 'imageset1';

%Modify these values if you'd only like to include the "sure" responses
%(i.e. 67 and 78)
NoResponse     = [67, 86]; % 67 sure no, 86 maybe no
YesResponse    = [78, 66]; % 66 maybe yes, 78 sure yes
ResponseKeys   = [NoResponse, YesResponse]; % 67 sure no, 86 maybe no, 66 maybe yes, 78 sure yes


%For file saving purposes (figure labels and file names)
if size(ResponseKeys,2) == 2
    SureResponseString = '_Sure';
else
    SureResponseString = '';
end

LoadStoredData = 1;
figsize        = [100 100 1200 800];


      
%% Get relevant .dat files
d = dir(fullfile(cd,'data','Aim2.1_Object-Scenes','Data',subjID,'Retrieval',imageset,'*.dat'));



%% Extract behavioral data
if LoadStoredData && exist(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,SureResponseString,'_Loglinear','.mat')))
    load(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,SureResponseString,'_Loglinear','.mat')))
else
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
        
        %% clean up sequence
        % select only image stimuli
        seq(seq<101) = [];
        seq(seq>800) = [];
        
        seqResponse(seqResponse<801)  = [];
        seqResponse(seqResponse>1500) = [];
        
        % ResponseStimCodeIdx is the "response period" period when the
        % image is onscreen, but the stimulus code is no longer that of the
        % image, but instead, a stimulus code between 801 and 1420, that
        % indicates the "response period" (this part of the script ensures
        % we can capture patient key presses during this response period
        % stimulus code)
        ResponseStimCodeIdx = {};
        for i = 1:size(seq,1)
            ResponseStimCodeIdx{i} = [find(StimCode==seq(i)); find(StimCode==seqResponse(i))];
        end
        



        %% clean up KeyDown
        % isolate keydown responses
        
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
            collectData{iter2,1} = param.Stimuli.Value{6,seq(i)};          % picture filename
            collectData{iter2,2} = param.Stimuli.Value{9,seq(i)};          % item or scene
            collectData{iter2,3} = str2num(param.Stimuli.Value{8,seq(i)}); % stim or no stim
            collectData{iter2,4} = param.Stimuli.Value{10,seq(i)};         % old or new
            collectData{iter2,5} = KD(i);                                  % key press
            collectData{iter2,6} = seq(i);  %stimulus code for image
            iter2 = iter2 + 1;
        end
        
    end
    
    %save(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,SureResponseString,'_Loglinear','.mat')),'collectData')
end


%% Behavioral Analysis
% hit/miss/false alarm/rejection
% SURE NO        MAYBE NO       MAYBE YES      SURE YES
% KeyDown == 67  KeyDown == 86  KeyDown == 66  KeyDown == 78

% Get total number of possible HITS for each category (old, item, stim/old,
% item, no stim/old, scene, stim/old, scene, no stim) ---total possible
% HITS and total possible MISSES are the same
TotalItemHitStim    = GetBA_MaxPossible(collectData, 'old', 'item',  1);
TotalItemHitNoStim  = GetBA_MaxPossible(collectData, 'old', 'item',  0);
TotalSceneHitStim   = GetBA_MaxPossible(collectData, 'old', 'scene', 1);
TotalSceneHitNoStim = GetBA_MaxPossible(collectData, 'old', 'scene', 0);

% Get total number of possible FALSE ALARMS for each category
% (new,item/new,scene -- new images are always no stim = 0)
% Total number of possibnle false alarms and rejections is the same
TotalItemFA  = GetBA_MaxPossible(collectData, 'new', 'item',  0);
TotalSceneFA = GetBA_MaxPossible(collectData, 'new', 'scene', 0);

for i = 1:size(collectData,1)
    
    % Get counts for all patient responses (hits, misses, false alarms,
    % rejections)
    
    ItemHit_Stim(i,1)     = CheckBAConditions(collectData(i,:), 'old', 'item',  1, YesResponse);
    ItemHit_NoStim(i,1)   = CheckBAConditions(collectData(i,:), 'old', 'item',  0, YesResponse);
    SceneHit_Stim(i,1)    = CheckBAConditions(collectData(i,:), 'old', 'scene', 1, YesResponse);
    SceneHit_NoStim(i,1)  = CheckBAConditions(collectData(i,:), 'old', 'scene', 0, YesResponse);
    
    ItemMiss_Stim(i,1)    = CheckBAConditions(collectData(i,:), 'old', 'item',  1, NoResponse);
    ItemMiss_NoStim(i,1)  = CheckBAConditions(collectData(i,:), 'old', 'item',  0, NoResponse);
    SceneMiss_Stim(i,1)   = CheckBAConditions(collectData(i,:), 'old', 'scene', 1, NoResponse);
    SceneMiss_NoStim(i,1) = CheckBAConditions(collectData(i,:), 'old', 'scene', 0, NoResponse);
    
    ItemFalseAlarm(i,1)   = CheckBAConditions(collectData(i,:), 'new', 'item',  0, YesResponse);
    SceneFalseAlarm(i,1)  = CheckBAConditions(collectData(i,:), 'new', 'scene', 0, YesResponse);
    
    ItemRejection(i,1)    = CheckBAConditions(collectData(i,:), 'new', 'item',  0, NoResponse);
    SceneRejection(i,1)   = CheckBAConditions(collectData(i,:), 'new', 'scene', 0, NoResponse);
    
end


%% Plot Figures

%% Hit rate for no stim and stim
%  Hit rate for no stim and stim images (combined items and scenes)
labelstring = {'NoStim','Stim'};
textStartY = 0.75;
textStepY  = 0.05;

TrainedImagesCombinedResultsFig = figure('Position',figsize);
b = bar([sum(ItemHit_NoStim + SceneHit_NoStim)/(TotalItemHitNoStim + TotalSceneHitNoStim),...
    sum(ItemHit_Stim + SceneHit_Stim)/(TotalItemHitStim + TotalSceneHitStim)]);
b(1).FaceColor = [0.4940 0.1840 0.5560]; % purple
text(2.45,textStartY,'number of hits:','FontSize',18,'fontweight','bold')
for i = 1:size(labelstring,2)
    text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
end
text(2.8,textStartY-1*textStepY,num2str(sum(ItemHit_NoStim + SceneHit_NoStim)),'FontSize',18)
text(2.8,textStartY-2*textStepY,num2str(sum(ItemHit_Stim + SceneHit_Stim)),'FontSize',18)
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
title([subjID, ' ', imageset ' Hit Rate - Combined Item/Scene'])
set(gca,'XTick',1:2,'XTickLabel',{'No Stim','Stim'})
axis([0.5 3.0 0 1])

fprintf('Saving trained images - combined item/scene figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString, '_TrainedImagesCombinedResults.png'));

saveas(TrainedImagesCombinedResultsFig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')

%%  Total hits across all categories
% combining item and scene and combine stim and no stim
labelstring = {'NoStim + Stim'};
textStartY = 0.75;
textStepY  = 0.05;

TrainedImagesCombinedResultsCombinedStimFig = figure('Position',figsize);
b = bar(sum(ItemHit_NoStim + SceneHit_NoStim + ItemHit_Stim + SceneHit_Stim)/...
    (TotalItemHitNoStim + TotalSceneHitNoStim + TotalItemHitStim+TotalSceneHitStim));
b(1).FaceColor = [0.4940 0.1840 0.5560]; % purple
text(1.55,textStartY,'number of hits:','FontSize',18,'fontweight','bold')
text(1.55,textStartY-1*textStepY,labelstring,'FontSize',18)
text(1.8,textStartY-1*textStepY,num2str(sum(ItemHit_NoStim + SceneHit_NoStim + ItemHit_Stim + SceneHit_Stim)),'FontSize',18)
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
title([subjID, ' ', imageset ' Hit Rate - Combined Item/Scene - Combined Stim/NoStim'])
set(gca,'XTick',1,'XTickLabel',{'Item/Scene/Stim/NoStim'})
axis([0.5 2.0 0 1])

fprintf('Saving trained images - combined item/scene with combined stim figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString, '_TrainedImagesCombinedResultsCombinedStim.png'));

saveas(TrainedImagesCombinedResultsCombinedStimFig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')

%% Hit rate for items no stim, items stim, scenes nostim, scenes stim
% break out item and scene and stim and nostim (hit rate out of total images in each category)
labelstring = {'NoStim Item','Stim Item','NoStim Scene','Stim Scene'};
textStartY = 0.75;
textStepY  = 0.05;


TrainedImagesFig = figure('Position',figsize);
b = bar([sum(ItemHit_NoStim)/TotalItemHitNoStim,    sum(ItemHit_Stim)/TotalItemHitStim;
      sum(SceneHit_NoStim)/TotalSceneHitNoStim,  sum(SceneHit_Stim)/TotalSceneHitStim]);
b(1).FaceColor = [0 0 1]; % blue
b(2).FaceColor = [1 0 0]; % red

%Add hatches to bars
hatchfill2(b(1),'single','HatchAngle',45, 'HatchDensity',60,'hatchcolor',[0 0 1]);
hatchfill2(b(2),'cross','HatchAngle',45,'HatchDensity',40,'hatchcolor',[1 0 0]);
for c = 1:numel(b)
    b(c).FaceColor = 'none';
end


text(2.45,textStartY,'number of hits:','FontSize',18,'fontweight','bold')
for i = 1:size(labelstring,2)
    text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
end
text(2.8,textStartY-1*textStepY,num2str(sum(ItemHit_NoStim)),'FontSize',18)
text(2.8,textStartY-2*textStepY,num2str(sum(ItemHit_Stim)),'FontSize',18)
text(2.8,textStartY-3*textStepY,num2str(sum(SceneHit_NoStim)),'FontSize',18)
text(2.8,textStartY-4*textStepY,num2str(sum(SceneHit_Stim)),'FontSize',18)
set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 3.0 0 1])
title([subjID, ' ', imageset ' Hit Rate (out of total images)'])

%Create Legend
legendData = {'No Stim', 'Stim'};
[legend_h, object_h, plot_h, text_str] = legendflex(b, legendData, 'Padding', [2, 2, 10], 'FontSize', 18, 'Location', 'NorthEast');
% object_h(1) is the first bar's text
% object_h(2) is the second bar's text
% object_h(3) is the first bar's patch
% object_h(4) is the second bar's patch
%
% Set the two patches within the legend
hatchfill2(object_h(3), 'single','HatchAngle',45, 'HatchDensity',60/4,'hatchcolor',[0 0 1]);
hatchfill2(object_h(4), 'cross','HatchAngle',45,'HatchDensity',40/4,'hatchcolor',[1 0 0]);


fprintf('Saving trained images figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,  '_TrainedImages.png'));

saveas(TrainedImagesFig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')

%% Hit rate for items no stim, items stim, scenes nostim, scenes stim 
% (ACTUAL hit rate -- Sure only for total number of "sure" images)

%This analysis/figure only runs when the two "sure" key responses are given
%in lines 22/23
if size(ResponseKeys,2) == 2

    labelstring = {'NoStim Item','Stim Item','NoStim Scene','Stim Scene'};
    textStartY = 0.75;
    textStepY  = 0.05;
    
    
    ActualHitRateSureFig = figure('Position',figsize);
    b = bar([sum(ItemHit_NoStim)/(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim)),    sum(ItemHit_Stim)/(sum(ItemHit_Stim) + sum(ItemMiss_Stim));
          sum(SceneHit_NoStim)/(sum(SceneHit_NoStim) + sum(SceneMiss_NoStim)),  sum(SceneHit_Stim)/(sum(SceneHit_Stim) + sum(SceneMiss_Stim))]);
    b(1).FaceColor = [0 0 1]; % blue
    b(2).FaceColor = [1 0 0]; % red
    
    %Add hatches to bars
    hatchfill2(b(1),'single','HatchAngle',45, 'HatchDensity',60,'hatchcolor',[0 0 1]);
    hatchfill2(b(2),'cross','HatchAngle',45,'HatchDensity',40,'hatchcolor',[1 0 0]);
    for c = 1:numel(b)
        b(c).FaceColor = 'none';
    end
    
    
    text(2.45,textStartY,'number of hits:','FontSize',18,'fontweight','bold')
    for i = 1:size(labelstring,2)
        text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
    end
    text(2.8,textStartY-1*textStepY,strcat(num2str(sum(ItemHit_NoStim)),' (out of ',num2str(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim)), ')'),'FontSize',18)
    text(2.8,textStartY-2*textStepY,strcat(num2str(sum(ItemHit_Stim)),' (out of ',num2str(sum(ItemHit_Stim) + sum(ItemMiss_Stim)), ')'),'FontSize',18)
    text(2.8,textStartY-3*textStepY,strcat(num2str(sum(SceneHit_NoStim)),' (out of ',num2str(sum(SceneHit_NoStim) + sum(SceneMiss_NoStim)), ')'),'FontSize',18)
    text(2.8,textStartY-4*textStepY,strcat(num2str(sum(SceneHit_Stim)),' (out of ',num2str(sum(SceneHit_Stim) + sum(SceneMiss_Stim)), ')'),'FontSize',18)
    set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
    ylabel('Occurrences (% of Sure)')
    set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
    set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
    axis([0.5 3.0 0 1])
    title([subjID, ' ', imageset ' Actual Hit Rate (out of sure only responses)'])
    
    %Create Legend
    legendData = {'No Stim', 'Stim'};
    [legend_h, object_h, plot_h, text_str] = legendflex(b, legendData, 'Padding', [2, 2, 10], 'FontSize', 18, 'Location', 'NorthEast');
    % object_h(1) is the first bar's text
    % object_h(2) is the second bar's text
    % object_h(3) is the first bar's patch
    % object_h(4) is the second bar's patch
    %
    % Set the two patches within the legend
    hatchfill2(object_h(3), 'single','HatchAngle',45, 'HatchDensity',60/4,'hatchcolor',[0 0 1]);
    hatchfill2(object_h(4), 'cross','HatchAngle',45,'HatchDensity',40/4,'hatchcolor',[1 0 0]);
    
    
    fprintf('Saving trained images figure...\n')
    savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,  '_ActualHitRateSURE.png'));
    
    saveas(ActualHitRateSureFig, [savefile(1:end-4) '.png'],'png');
    fprintf('Done\n')

end

%% Hit rate for items vs. scenes (combined stim and no stim)
% break out item and scene - combine stim and no stim
labelstring = {'NoStim +Stim Item','NoStim + Stim Scene'};
textStartY = 0.75;
textStepY  = 0.05;

TrainedImagesCombinedStimFig = figure('Position',figsize);
 bar([sum(ItemHit_NoStim + ItemHit_Stim)/(TotalItemHitNoStim + TotalItemHitStim);
      sum(SceneHit_NoStim + SceneHit_Stim)/(TotalSceneHitNoStim + TotalSceneHitStim)])
text(2.45,textStartY,'number of hits:','FontSize',18,'fontweight','bold')
for i = 1:size(labelstring,2)
    text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
end
text(3.1,textStartY-1*textStepY,num2str(sum(ItemHit_NoStim + ItemHit_Stim)),'FontSize',18)
text(3.1,textStartY-2*textStepY,num2str(sum(SceneHit_NoStim + SceneHit_Stim)),'FontSize',18)
set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 3.5 0 1])
title([subjID, ' ', imageset ' Hit Rate - Combined Stim/NoStim'])

fprintf('Saving trained images with combined stim figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,  '_TrainedImagesCombinedStim.png'));

saveas(TrainedImagesCombinedStimFig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')

%% False Alarm Rate
% Items vs. scenes (out of total images shown for each category)
labelstring = {'Item','Scene'};
textStartY = 0.75;
textStepY  = 0.05;

NovelImagesFig = figure('Position',figsize);
b = bar([sum(ItemFalseAlarm)/TotalItemFA; sum(SceneFalseAlarm)/TotalSceneFA],'FaceColor','Flat');
b(1).FaceColor = [0.5 0.5 0.5];
text(2.45,textStartY,'number of FAs:','FontSize',18,'fontweight','bold')
for i = 1:size(labelstring,2)
    text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
end
text(2.8,textStartY-1*textStepY,num2str(sum(ItemFalseAlarm)),'FontSize',18)
text(2.8,textStartY-2*textStepY,num2str(sum(SceneFalseAlarm)),'FontSize',18)
set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 3.0 0 1])
title([subjID, ' ', imageset ' False Alarm (out of total images)'])

fprintf('Saving novel images Figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString, '_NovelImages.png'));

saveas(NovelImagesFig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')

%% False alarm rate (ACTUAL FA rate -- Sure only for total number of "sure" images)

%This analysis/figure only runs when the two "sure" key responses are given
%in lines 22/23
if size(ResponseKeys,2) == 2

    labelstring = {'Item','Scene'};
    textStartY = 0.75;
    textStepY  = 0.05;
    
    ActualFARateSureFig = figure('Position',figsize);
    b = bar([sum(ItemFalseAlarm)/(sum(ItemFalseAlarm) + sum(ItemRejection)); sum(SceneFalseAlarm)/(sum(SceneFalseAlarm)+ sum(SceneRejection))],'FaceColor','Flat');
    b(1).FaceColor = [0.5 0.5 0.5];
    text(2.45,textStartY,'number of FAs:','FontSize',18,'fontweight','bold')
    for i = 1:size(labelstring,2)
        text(2.45,textStartY-i*textStepY,labelstring(i),'FontSize',18)
    end
    text(2.8,textStartY-1*textStepY,strcat(num2str(sum(ItemFalseAlarm)),' (out of ',num2str(sum(ItemFalseAlarm) + sum(ItemRejection)), ')'),'FontSize',18)
    text(2.8,textStartY-2*textStepY,strcat(num2str(sum(SceneFalseAlarm)),' (out of ',num2str(sum(SceneFalseAlarm) + sum(SceneRejection)), ')'),'FontSize',18)
    set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
    ylabel('Occurrences (% of Sure)')
    set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
    set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
    axis([0.5 3.0 0 1])
    title([subjID, ' ', imageset ' Actual False Alarm (out of sure only responses)'])
    
    fprintf('Saving novel images Figure...\n')
    savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString, '_ActualFArateSure.png'));
    
    saveas(ActualFARateSureFig, [savefile(1:end-4) '.png'],'png');
    fprintf('Done\n')
end

%% d prime (loglinear correction)
% Breakout items, scenes, stim, no stim
[dp(1,1), c(1)] = dprime_simple((sum(ItemHit_NoStim) + 0.5)/(TotalItemHitNoStim + 1),(sum(ItemFalseAlarm) + 0.5)/(TotalItemFA + 1));         % nostim item
[dp(1,2), c(2)] = dprime_simple((sum(ItemHit_Stim) + 0.5)/(TotalItemHitStim + 1),(sum(ItemFalseAlarm) + 0.5)/(TotalItemFA + 1));             % stim item
[dp(2,1), c(3)] = dprime_simple((sum(SceneHit_NoStim) + 0.5)/(TotalSceneHitNoStim + 1),(sum(SceneFalseAlarm) + 0.5)/(TotalSceneFA + 1));     % nostim scene
[dp(2,2), c(4)] = dprime_simple((sum(SceneHit_Stim) + 0.5)/(TotalSceneHitStim + 1),(sum(SceneFalseAlarm) + 0.5)/(TotalSceneFA + 1));         % stim scene
[dp(3,1), c(5)] = dprime_simple((sum(ItemHit_NoStim+SceneHit_NoStim) + 0.5)/(TotalItemHitNoStim+TotalSceneHitNoStim + 1),... % nostim overall
                    (sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/(TotalItemFA+TotalSceneFA + 1)); 
[dp(3,2), c(6)] = dprime_simple((sum(ItemHit_Stim+SceneHit_Stim) + 0.5)/(TotalItemHitStim+TotalSceneHitStim + 1),...         % stim overall
                    (sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/(TotalItemFA+TotalSceneFA + 1)); 

dp(isinf(dp)) = NaN;

%For y axis limit locked at 4.0
ylim = [min([min(dp,[],'omitnan'),0])-0.1 max(4.0)];

%For variable y axis limit
%ylim = [min([min(dp,[],'omitnan'),0])-0.1 max([max(dp,[],'omitnan'),0])+0.1];

          
clabelstring    = {'item nostim', 'item stim', 'scene nostim', 'scene stim', 'overall nostim', 'overall stim'};
textStartY = max(max(dp,[],'omitnan')) - 0.15*max(max(dp,[],'omitnan'));
textStepY  = max(max(dp,[],'omitnan'))/20;

dprimefig = figure('Position',figsize);
b = bar(dp);
b(1).FaceColor = [0 0 1]; % blue
b(2).FaceColor = [1 0 0]; % red
text(3.5,3.0,'Criterion:','FontSize',18,'fontweight','bold')
text(3.5,2.3,'Dprime:','FontSize',18,'fontweight','bold')

%Plot dprime values
DText1 = {'Item NoStim: '};
DText1a = {strcat('  ',num2str(dp(1,1),3))};
DText2 = {'Item Stim: '};
DText2a = {strcat('  ',num2str(dp(1,2),3))};
DText3 = {'Scene NoStim: '};
DText3a = {strcat('  ',num2str(dp(2,1),3))};
DText4 = {'Scene Stim: '};
DText4a = {strcat('  ',num2str(dp(2,2),3))};
DText5 = {'Overall NoStim: '};
DText5a = {strcat('  ',num2str(dp(3,1),3))};
DText6 = {'Overall Stim: '};
DText6a = {strcat('  ',num2str(dp(3,2),3))};


text(3.5, 2.2, DText1,'FontSize',15)
text(4.0, 2.2, DText1a,'FontSize',15)
text(3.5, 2.1, DText2,'FontSize',15)
text(4.0, 2.1, DText2a,'FontSize',15)
text(3.5, 2.0, DText3,'FontSize',15)
text(4.0, 2.0, DText3a,'FontSize',15)
text(3.5, 1.9, DText4,'FontSize',15)
text(4.0, 1.9, DText4a,'FontSize',15)
text(3.5, 1.8, DText5,'FontSize',15)
text(4.0, 1.8, DText5a,'FontSize',15)
text(3.5, 1.7, DText6,'FontSize',15)
text(4.0, 1.7, DText6a,'FontSize',15)





%Plot Criterion text for when yaxis is locked at dprime of 4.0
Text1 = {'Item NoStim: '};
Text1a = {strcat('  ',num2str(c(1),3))};
Text2 = {'Item Stim: '};
Text2a = {strcat('  ',num2str(c(2),3))};
Text3 = {'Scene NoStim: '};
Text3a = {strcat('  ',num2str(c(3),3))};
Text4 = {'Scene Stim: '};
Text4a = {strcat('  ',num2str(c(4),3))};
Text5 = {'Overall NoStim: '};
Text5a = {strcat('  ',num2str(c(5),3))};
Text6 = {'Overall Stim: '};
Text6a = {strcat('  ',num2str(c(6),3))};


text(3.5, 2.9, Text1,'FontSize',15)
text(4.0, 2.9, Text1a,'FontSize',15)
text(3.5, 2.8, Text2,'FontSize',15)
text(4.0, 2.8, Text2a,'FontSize',15)
text(3.5, 2.7, Text3,'FontSize',15)
text(4.0, 2.7, Text3a,'FontSize',15)
text(3.5, 2.6, Text4,'FontSize',15)
text(4.0, 2.6, Text4a,'FontSize',15)
text(3.5, 2.5, Text5,'FontSize',15)
text(4.0, 2.5, Text5a,'FontSize',15)
text(3.5, 2.4, Text6,'FontSize',15)
text(4.0, 2.4, Text6a,'FontSize',15)

%Plot criterion text if you have yaxis changing based on dprime vaues and
%not locked
% for i = 1:numel(c)
%     text(3.35,textStartY-i*textStepY,clabelstring(i),'FontSize',18)
%     if c(i)<0
%     	text(3.965,textStartY-i*textStepY,num2str(c(i),3),'FontSize',18)
%     else
%         text(4,textStartY-i*textStepY,num2str(c(i),3),'FontSize',18)
%     end
% end


set(gca,'XTick',[1:3],'XTickLabel',{'item','scenes','overall'})
ylabel('dprime')
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 4.5 ylim])
legend('No Stim','Stim')
title([subjID, ' ', imageset ' Discrimination Index (out of total images)'])

%Create plot text that lists the difference in dprime for stim vs. nostim
plottext1 = {'Item Diff: '};
plottext2 = {strcat('  ',num2str(abs(dprime_simple((sum(ItemHit_NoStim) + 0.5)/(TotalItemHitNoStim + 1),(sum(ItemFalseAlarm) + 0.5)/(TotalItemFA + 1))-dprime_simple((sum(ItemHit_Stim) + 0.5)/(TotalItemHitStim + 1),(sum(ItemFalseAlarm) + 0.5)/(TotalItemFA + 1))),3))};
plottext3 = {'Scene Diff: '};
plottext4 = {strcat('  ',num2str(abs(dprime_simple((sum(SceneHit_NoStim) + 0.5)/(TotalSceneHitNoStim + 1),(sum(SceneFalseAlarm) + 0.5)/(TotalSceneFA + 1))-dprime_simple((sum(SceneHit_Stim) + 0.5)/(TotalSceneHitStim + 1),(sum(SceneFalseAlarm) + 0.5)/(TotalSceneFA + 1))),3))};
plottext5 = {'Overall Diff: '};
plottext6 = {strcat('  ',num2str(abs(dprime_simple((sum(ItemHit_NoStim+SceneHit_NoStim) + 0.5)/(TotalItemHitNoStim+TotalSceneHitNoStim + 1),(sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/(TotalItemFA+TotalSceneFA + 1))-dprime_simple((sum(ItemHit_Stim+SceneHit_Stim) + 0.5)/(TotalItemHitStim+TotalSceneHitStim + 1),(sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/(TotalItemFA+TotalSceneFA + 1))),3))};

%Set the positioning of the above text
text(0.8, 3.8, plottext1,'FontSize',19)
text(0.8, 3.6, plottext2,'FontSize',19)

text(1.8, 3.8, plottext3,'FontSize',19)
text(1.8, 3.6, plottext4,'FontSize',19)

text(2.8, 3.8, plottext5,'FontSize',19)
text(2.8, 3.6, plottext6,'FontSize',19)



fprintf('Saving d prime figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,'_Loglinear', '_dprime.png'));

saveas(dprimefig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')


%% d prime (ACTUAL dprime -- Sure only for total number of "sure" images) - loglinear correction

%This analysis/figure only runs when the two "sure" key responses are given
%in lines 22/23
if size(ResponseKeys,2) == 2

    [dp(1,1), c(1)] = dprime_simple((sum(ItemHit_NoStim) + 0.5)/(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim) + 1),(sum(ItemFalseAlarm) + 0.5) /(sum(ItemFalseAlarm) + sum(ItemRejection) + 1));         % nostim item
    [dp(1,2), c(2)] = dprime_simple((sum(ItemHit_Stim) + 0.5)/(sum(ItemHit_Stim) + sum(ItemMiss_Stim) + 1),(sum(ItemFalseAlarm) + 0.5)/(sum(ItemFalseAlarm) + sum(ItemRejection) + 1));             % stim item
    [dp(2,1), c(3)] = dprime_simple((sum(SceneHit_NoStim) + 0.5)/(sum(SceneHit_NoStim) + sum(SceneMiss_NoStim) + 1),(sum(SceneFalseAlarm) + 0.5)/(sum(SceneFalseAlarm)+ sum(SceneRejection) + 1));     % nostim scene
    [dp(2,2), c(4)] = dprime_simple((sum(SceneHit_Stim) + 0.5)/(sum(SceneHit_Stim) + sum(SceneMiss_Stim) + 1),(sum(SceneFalseAlarm) + 0.5)/(sum(SceneFalseAlarm)+ sum(SceneRejection) + 1));         % stim scene
    [dp(3,1), c(5)] = dprime_simple((sum(ItemHit_NoStim+SceneHit_NoStim) + 0.5)/(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim) + sum(SceneHit_NoStim) + sum(SceneMiss_NoStim) + 1),... % nostim overall
                        (sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/((sum(ItemFalseAlarm) + sum(ItemRejection) + sum(SceneFalseAlarm)+ sum(SceneRejection) + 1))); 
    [dp(3,2), c(6)] = dprime_simple((sum(ItemHit_Stim+SceneHit_Stim) + 0.5)/(sum(ItemHit_Stim) + sum(ItemMiss_Stim) + sum(SceneHit_Stim) + sum(SceneMiss_Stim) + 1),...         % stim overall
                        (sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/((sum(ItemFalseAlarm) + sum(ItemRejection) + sum(SceneFalseAlarm)+ sum(SceneRejection) + 1))); 
    
    dp(isinf(dp)) = NaN;
    
    %For y axis limit locked at 4.0
    ylim = [min([min(dp,[],'omitnan'),0])-0.1 max(4.0)];
    
    %For variable y axis limit
    %ylim = [min([min(dp,[],'omitnan'),0])-0.1 max([max(dp,[],'omitnan'),0])+0.1];
    
              
    clabelstring    = {'item nostim', 'item stim', 'scene nostim', 'scene stim', 'overall nostim', 'overall stim'};
    textStartY = max(max(dp,[],'omitnan')) - 0.15*max(max(dp,[],'omitnan'));
    textStepY  = max(max(dp,[],'omitnan'))/20;
    
    Actualdprimefig = figure('Position',figsize);
    b = bar(dp);
    b(1).FaceColor = [0 0 1]; % blue
    b(2).FaceColor = [1 0 0]; % red
    text(3.5,3.0,'Criterion:','FontSize',18,'fontweight','bold')
    text(3.5,2.3,'Dprime:','FontSize',18,'fontweight','bold')
    
    %Plot dprime values
    DText1 = {'Item NoStim: '};
    DText1a = {strcat('  ',num2str(dp(1,1),3))};
    DText2 = {'Item Stim: '};
    DText2a = {strcat('  ',num2str(dp(1,2),3))};
    DText3 = {'Scene NoStim: '};
    DText3a = {strcat('  ',num2str(dp(2,1),3))};
    DText4 = {'Scene Stim: '};
    DText4a = {strcat('  ',num2str(dp(2,2),3))};
    DText5 = {'Overall NoStim: '};
    DText5a = {strcat('  ',num2str(dp(3,1),3))};
    DText6 = {'Overall Stim: '};
    DText6a = {strcat('  ',num2str(dp(3,2),3))};
    
    
    text(3.5, 2.2, DText1,'FontSize',15)
    text(4.0, 2.2, DText1a,'FontSize',15)
    text(3.5, 2.1, DText2,'FontSize',15)
    text(4.0, 2.1, DText2a,'FontSize',15)
    text(3.5, 2.0, DText3,'FontSize',15)
    text(4.0, 2.0, DText3a,'FontSize',15)
    text(3.5, 1.9, DText4,'FontSize',15)
    text(4.0, 1.9, DText4a,'FontSize',15)
    text(3.5, 1.8, DText5,'FontSize',15)
    text(4.0, 1.8, DText5a,'FontSize',15)
    text(3.5, 1.7, DText6,'FontSize',15)
    text(4.0, 1.7, DText6a,'FontSize',15)
    
    
    
    
    
    %Plot Criterion text for when yaxis is locked at dprime of 4.0
    Text1 = {'Item NoStim: '};
    Text1a = {strcat('  ',num2str(c(1),3))};
    Text2 = {'Item Stim: '};
    Text2a = {strcat('  ',num2str(c(2),3))};
    Text3 = {'Scene NoStim: '};
    Text3a = {strcat('  ',num2str(c(3),3))};
    Text4 = {'Scene Stim: '};
    Text4a = {strcat('  ',num2str(c(4),3))};
    Text5 = {'Overall NoStim: '};
    Text5a = {strcat('  ',num2str(c(5),3))};
    Text6 = {'Overall Stim: '};
    Text6a = {strcat('  ',num2str(c(6),3))};
    
    
    text(3.5, 2.9, Text1,'FontSize',15)
    text(4.0, 2.9, Text1a,'FontSize',15)
    text(3.5, 2.8, Text2,'FontSize',15)
    text(4.0, 2.8, Text2a,'FontSize',15)
    text(3.5, 2.7, Text3,'FontSize',15)
    text(4.0, 2.7, Text3a,'FontSize',15)
    text(3.5, 2.6, Text4,'FontSize',15)
    text(4.0, 2.6, Text4a,'FontSize',15)
    text(3.5, 2.5, Text5,'FontSize',15)
    text(4.0, 2.5, Text5a,'FontSize',15)
    text(3.5, 2.4, Text6,'FontSize',15)
    text(4.0, 2.4, Text6a,'FontSize',15)
    
    %Plot criterion text if you have yaxis changing based on dprime vaues and
    %not locked
    % for i = 1:numel(c)
    %     text(3.35,textStartY-i*textStepY,clabelstring(i),'FontSize',18)
    %     if c(i)<0
    %     	text(3.965,textStartY-i*textStepY,num2str(c(i),3),'FontSize',18)
    %     else
    %         text(4,textStartY-i*textStepY,num2str(c(i),3),'FontSize',18)
    %     end
    % end
    
    
    set(gca,'XTick',[1:3],'XTickLabel',{'item','scenes','overall'})
    ylabel('dprime (sure only)')
    set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
    axis([0.5 4.5 ylim])
    legend('No Stim','Stim')
    title([subjID, ' ', imageset ' Actual Discrimination Index (out of sure only responses)'])
    
    %Create plot text that lists the difference in dprime for stim vs. nostim
    plottext1 = {'Item Diff: '};
    plottext2 = {strcat('  ',num2str(abs(dprime_simple((sum(ItemHit_NoStim) + 0.5)/(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim) + 1),(sum(ItemFalseAlarm) + 0.5) /(sum(ItemFalseAlarm) + sum(ItemRejection) + 1))-dprime_simple((sum(ItemHit_Stim) + 0.5)/(sum(ItemHit_Stim) + sum(ItemMiss_Stim) + 1),(sum(ItemFalseAlarm) + 0.5)/(sum(ItemFalseAlarm) + sum(ItemRejection) + 1))),3))};
    plottext3 = {'Scene Diff: '};
    plottext4 = {strcat('  ',num2str(abs(dprime_simple((sum(SceneHit_NoStim) + 0.5)/(sum(SceneHit_NoStim) + sum(SceneMiss_NoStim) + 1),(sum(SceneFalseAlarm) + 0.5)/(sum(SceneFalseAlarm)+ sum(SceneRejection) + 1))-dprime_simple((sum(SceneHit_Stim) + 0.5)/(sum(SceneHit_Stim) + sum(SceneMiss_Stim) + 1),(sum(SceneFalseAlarm) + 0.5)/(sum(SceneFalseAlarm)+ sum(SceneRejection) + 1))),3))};
    plottext5 = {'Overall Diff: '};
    plottext6 = {strcat('  ',num2str(abs(dprime_simple((sum(ItemHit_NoStim+SceneHit_NoStim) + 0.5)/(sum(ItemHit_NoStim) + sum(ItemMiss_NoStim) + sum(SceneHit_NoStim) + sum(SceneMiss_NoStim) + 1),(sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/((sum(ItemFalseAlarm) + sum(ItemRejection) + sum(SceneFalseAlarm)+ sum(SceneRejection) + 1)))-dprime_simple((sum(ItemHit_Stim+SceneHit_Stim) + 0.5)/(sum(ItemHit_Stim) + sum(ItemMiss_Stim) + sum(SceneHit_Stim) + sum(SceneMiss_Stim) + 1),(sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/((sum(ItemFalseAlarm) + sum(ItemRejection) + sum(SceneFalseAlarm)+ sum(SceneRejection) + 1)))),3))};
    
    %Set the positioning of the above text
    text(0.8, 3.8, plottext1,'FontSize',19)
    text(0.8, 3.6, plottext2,'FontSize',19)
    
    text(1.8, 3.8, plottext3,'FontSize',19)
    text(1.8, 3.6, plottext4,'FontSize',19)
    
    text(2.8, 3.8, plottext5,'FontSize',19)
    text(2.8, 3.6, plottext6,'FontSize',19)
    
    
    
    fprintf('Saving d prime figure...\n')
    savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,'_Loglinear', '_ActualSuredprime.png'));
    
    saveas(Actualdprimefig, [savefile(1:end-4) '.png'],'png');
    fprintf('Done\n')

end

%% d prime - combined stim and no stim - loglinear correction
[dp_CombinedStim(1,1), c_CombinedStim(1)] = dprime_simple((sum(ItemHit_NoStim + ItemHit_Stim) + 0.5)/...
                                                (TotalItemHitNoStim + TotalItemHitStim + 1),(sum(ItemFalseAlarm) + 0.5)/(TotalItemFA + 1));           % item
[dp_CombinedStim(2,1), c_CombinedStim(2)] = dprime_simple((sum(SceneHit_NoStim + SceneHit_Stim) + 0.5)/...
                                                (TotalSceneHitNoStim + TotalSceneHitStim + 1),(sum(SceneFalseAlarm) + 0.5)/(TotalSceneFA + 1));       % scene
[dp_CombinedStim(3,1), c_CombinedStim(3)] = dprime_simple((sum(ItemHit_NoStim + SceneHit_NoStim + ItemHit_Stim + SceneHit_Stim) + 0.5)/...
                                                (TotalItemHitNoStim + TotalSceneHitNoStim + TotalItemHitStim + TotalSceneHitStim + 1),... % nostim overall
                                                    (sum(ItemFalseAlarm + SceneFalseAlarm) + 0.5)/(TotalItemFA + TotalSceneFA + 1)); 
                                                
dp_CombinedStim(isinf(dp_CombinedStim)) = NaN;

ylim = [min([min(dp_CombinedStim,[],'omitnan'),0])-0.1 max([max(dp_CombinedStim,[],'omitnan'),0])+0.1];
                                                
clabelstring    = {'item','scene','overall'};
textStartY = max(max(dp_CombinedStim,[],'omitnan')) - 0.15*max(max(dp_CombinedStim,[],'omitnan'));
textStepY  = max(max(dp_CombinedStim,[],'omitnan'))/20;

dprimeCombinedStimfig = figure('Position',figsize);
b = bar(dp_CombinedStim);
b(1).FaceColor = [0.3010 0.7450 0.9330]; % blue
text(3.5,textStartY,'criterion:','FontSize',18,'fontweight','bold')
for i = 1:numel(c_CombinedStim)
    text(3.5,textStartY-i*textStepY,clabelstring(i),'FontSize',18)
    if c_CombinedStim(i)<0
    	text(3.965,textStartY-i*textStepY,num2str(c_CombinedStim(i)),'FontSize',18)
    else
        text(4,textStartY-i*textStepY,num2str(c_CombinedStim(i)),'FontSize',18)
    end
end
set(gca,'XTick',[1:3],'XTickLabel',{'item','scenes','overall'})
ylabel('dprime')
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 4.5 ylim])
title([subjID, ' ', imageset ' Discrimination Index - Combined Stim/NoStim (out of total images)'])

fprintf('Saving d prime with combined stim figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,'_Loglinear', '_dprimeCombinedStim.png'));

saveas(dprimeCombinedStimfig, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')


%% d prime - combined stim and no stim (ACTUAL dprime -- Sure only for total number of "sure" images) - loglinear correction

%This analysis/figure only runs when the two "sure" key responses are given
%in lines 22/23
if size(ResponseKeys,2) == 2

    [dp_CombinedStim(1,1), c_CombinedStim(1)] = dprime_simple((sum(ItemHit_NoStim + ItemHit_Stim) + 0.5)/...
                                                    (sum(ItemHit_NoStim + ItemHit_Stim) + sum(ItemMiss_NoStim + ItemMiss_Stim) + 1),(sum(ItemFalseAlarm) + 0.5)/(sum(ItemFalseAlarm) + sum(ItemRejection) + 1));           % item
    [dp_CombinedStim(2,1), c_CombinedStim(2)] = dprime_simple((sum(SceneHit_NoStim + SceneHit_Stim) + 0.5)/...
                                                    (sum(SceneHit_NoStim + SceneHit_Stim) + sum(SceneMiss_NoStim + SceneMiss_Stim) + 1),(sum(SceneFalseAlarm) + 0.5)/(sum(SceneFalseAlarm) + sum(SceneRejection) + 1));       % scene
    [dp_CombinedStim(3,1), c_CombinedStim(3)] = dprime_simple((sum(ItemHit_NoStim+SceneHit_NoStim + ItemHit_Stim + SceneHit_Stim) + 0.5)/...
                                                    (sum(ItemHit_NoStim + ItemHit_Stim + ItemMiss_NoStim + ItemMiss_Stim + SceneHit_NoStim + SceneHit_Stim + SceneMiss_NoStim + SceneMiss_Stim) + 1),... % nostim overall
                                                        (sum(ItemFalseAlarm+SceneFalseAlarm) + 0.5)/(sum(ItemFalseAlarm + ItemRejection + SceneFalseAlarm + SceneRejection) + 1)); 
                                                    
    dp_CombinedStim(isinf(dp_CombinedStim)) = NaN;
    
    ylim = [min([min(dp_CombinedStim,[],'omitnan'),0])-0.1 max([max(dp_CombinedStim,[],'omitnan'),0])+0.1];
                                                    
    clabelstring    = {'item','scene','overall'};
    textStartY = max(max(dp_CombinedStim,[],'omitnan')) - 0.15*max(max(dp_CombinedStim,[],'omitnan'));
    textStepY  = max(max(dp_CombinedStim,[],'omitnan'))/20;
    
    ActualdprimeCombinedStimfig = figure('Position',figsize);
    b = bar(dp_CombinedStim);
    b(1).FaceColor = [0.3010 0.7450 0.9330]; % blue
    text(3.5,textStartY,'criterion:','FontSize',18,'fontweight','bold')
    for i = 1:numel(c_CombinedStim)
        text(3.5,textStartY-i*textStepY,clabelstring(i),'FontSize',18)
        if c_CombinedStim(i)<0
    	    text(3.965,textStartY-i*textStepY,num2str(c_CombinedStim(i)),'FontSize',18)
        else
            text(4,textStartY-i*textStepY,num2str(c_CombinedStim(i)),'FontSize',18)
        end
    end
    set(gca,'XTick',[1:3],'XTickLabel',{'item','scenes','overall'})
    ylabel('dprime (sure only)')
    set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
    axis([0.5 4.5 ylim])
    title([subjID, ' ', imageset ' Actual Discrimination Index - Combined Stim/NoStim (out of sure only responses)'])
    
    fprintf('Saving d prime with combined stim figure...\n')
    savefile = fullfile(cd, 'figures', subjID, imageset, strcat(subjID, '_', imageset, SureResponseString,'_Loglinear', '_ActualSuredprimeCombinedStim.png'));
    
    saveas(ActualdprimeCombinedStimfig, [savefile(1:end-4) '.png'],'png');
    fprintf('Done\n')

end


end


%% Categorize key press responses in the context of image type and stimulation condition
function output = CheckBAConditions(data,novelty,type,stim,KeyDownPressed)

if strcmp(data{4},novelty) && data{3} == stim && contains(data{2},type) && any(ismember(KeyDownPressed,data{5})) % (data{5} == KeyDownPressed(1) || data{5} == KeyDownPressed(2))
    output = 1;
else
    output = 0;
end

end

function [TotalNoveltyTypeStim] = GetBA_MaxPossible(data,novelty,type,stim)

for i = 1:size(data,1)
    NoveltyPossible(i) = contains(data{i,4},novelty);

    TypePossible(i)  = contains(data{i,2},type);
    
    StimPossible(i)   = isequal(data{i,3},stim);
end

NoveltyTypeStimPossible  = NoveltyPossible.*TypePossible.*StimPossible;
TotalNoveltyTypeStim     = sum(NoveltyTypeStimPossible);


end
