%INMAN Laboratory
%% Created by Krista Wahlstrom 4/18/2023
%% Stimulation BEFORE image analysis for BLAES Aim 2.1
%Recognition-memory performance for images followed by stimulation
%relative to no-stimulation images that came after stimulation for each (for  both items and scenes).

%THIS SCRIPT REQUIRES THE TEST DATA.MAT FILE TO ALREADY EXIST FOR THE
%PATIENT (generated from the
%BLAES_Aim2_ItemScene_TestPhaseBehavioralAnalysis_Loglinear script)


clear;
close all;

%% Load participant's data


%% Manually enter patient info here
%Enter subject info
subjID         = 'BJH027';
imageset       = 'imageset1';



%% Load participant's Study Phase data

addpath(genpath(fullfile(cd,'BCI2000Tools')))


d = dir(fullfile(cd,'data',subjID,'Study',imageset,'*.dat'));



%Set this to true if patient is responding as you would expect during the
%presentation of the images during the Study phase. Set this to False, if patient did not respond
%during the presentation of the image (and instead made responses during
%the stimulation period 1501/1502 or the inter-trial ISI period 1801 or 
% during the fixation cross period 1601-1786) 
respondDuringImage = false;

%Create response string for saving separate figure files and .mat files based on which analysis is run 
if respondDuringImage == true
    ResponseString = '_RespondDurImage';
else
    ResponseString = '_RespondAftImage';
end


%Combine all .dat files for the study phase session into one matrix
iter2 = 1;
    for file = 1:size(d,1)
        
        [~, states, parameters] = load_bcidat(fullfile(d(file).folder,d(file).name));
        pause(1);

        SEQ = parameters.Sequence.NumericValue;
        KD = states.KeyDown;
        StimCode = states.StimulusCode;

        SEQ(SEQ < 101) = [];
        SEQ(SEQ > 800) = [];

        %Replaces the stimcode values that are not equal to a SEQ/image
        %stimulus code, with the previously shown image's stimulus code/SEQ
        %value if respondDuringImage is set to "false" so that keypresses
        %can be gathered from during the intertrial period
        if(~respondDuringImage)
            lastValidImage = -1;
            for i = 1:length(StimCode)
                if(lastValidImage ~= StimCode(i) && ismember(StimCode(i), SEQ))
                    lastValidImage = StimCode(i);
                elseif(lastValidImage ~= -1 && ~ismember(StimCode(i), SEQ))
                    StimCode(i) = lastValidImage;
                end
            end
        end

        %Create a copy of the keypresses file
        KDCopy = KD;
        KDCopy(KDCopy==0) = [];
        

        %Create keyPresses variable which lists the keypresses, the stimcode, and the stimcode index at which that key press occurred 
        cnt = 1;
        keyPresses = zeros(length(KDCopy), 3);
        for i = 1:length(KD)
            if(KD(i) ~= 0)
                keyPresses(cnt,1) = KD(i);
                keyPresses(cnt,2) = StimCode(i);
                keyPresses(cnt,3) = i;
                cnt = cnt + 1;
            end
        end

        %Create StudyData matrix of filename, stimulus code/image
        %code, image type (item/scene), key press
        for i = 1:length(SEQ)
            StudyData{iter2,1} = parameters.Stimuli.Value{6,SEQ(i)}; %filename
            StudyData{iter2,2} = SEQ(i); %stimulus code for image
            StudyData{iter2,3} = parameters.Stimuli.Value{9,SEQ(i)}; %item or scene or scrammbled image
            StudyData{iter2,4} = str2num(parameters.Stimuli.Value{8,SEQ(i)});%stimulation or no stimulation

            idx = ismember(keyPresses(:,2), SEQ(i));
            keyPressesForSeq = keyPresses(idx, :);

            pressForImage = 0;
            for j = 1: size(keyPressesForSeq)
                if(pressForImage == 0)
                    pressForImage = keyPressesForSeq(j, 1);
                elseif(keyPressesForSeq(j, 1) == 37 || keyPressesForSeq(j, 1) == 39)
                    pressForImage = keyPressesForSeq(j, 1);
                end
    
                if(pressForImage == 37 || pressForImage == 39)
                    break;
                end
            end

            if pressForImage == 37
                StudyData{iter2,5} = 'Dislike';%key press response
            elseif pressForImage == 39
                StudyData{iter2,5} = 'Like';
            else
                StudyData{iter2,5} = 'Non-Response Key';
            end

            StudyData{iter2, 6} = pressForImage;%key press ID number
            iter2 = iter2 + 1;
        end

    end



%% Reformat data to reflect stim BEFORE conditions instead of stim AFTER


%Duplicate StudyData variable
BLAES_StudySequence = StudyData;

%Shift all stimulation values down one row so that the 1 or 0 in any given row corresponds
%to whether a stimulation occurred before the image or not (this line
%shifts every single row down one, not just the stimulation column)
BLAES_StudySequence_StimShift = circshift(BLAES_StudySequence, [1 0]);

%Set the stimulation value for the first image to 0, since there is never
%stimulation before the first trial
BLAES_StudySequence_StimShift{1,4} = 0;


%Set all other rows back to their original values so that the only column
%rows that have shifted are the stimulation values
BLAES_StudySequence_StimShift(:,1) = BLAES_StudySequence(:, 1);
BLAES_StudySequence_StimShift(:,2) = BLAES_StudySequence(:, 2);
BLAES_StudySequence_StimShift(:,3) = BLAES_StudySequence(:, 3);
BLAES_StudySequence_StimShift(:,5) = BLAES_StudySequence(:, 5);
BLAES_StudySequence_StimShift(:,6) = BLAES_StudySequence(:, 6);



%Load the BCI2000 presentation sequence (image type, stim type, old/new)
%and participant keypresses from the Test phase
load(fullfile(cd,'data',subjID,'Test',imageset,strcat(subjID,'_Test_Data_',imageset,'.mat')))

%Duplicate collectData variable that has the Test phase responses
BLAES_TestSequence_StimShift = collectData;

%Create map with image stimulus code and stim/nostim BEFORE value from
%BLAES_StudySequence_StimShift
ImageStimMap = containers.Map(BLAES_StudySequence_StimShift(:, 2), BLAES_StudySequence_StimShift(:, 4));

%Create a new column (column 7) in the BLAES_TestSequence_StimShift matrix
%for the stim values from the study phase that are associated with what was happening before the
%present image (column 3 still has the original stim/nostim AFTER values, but
%column 7 are the stim/nostim BEFORE values)
for i = 1:size(BLAES_TestSequence_StimShift,1)
    imageStimCode = cell2mat(BLAES_TestSequence_StimShift(i,6));
    if isKey(ImageStimMap, imageStimCode)
        BLAES_TestSequence_StimShift(i,7) = num2cell(ImageStimMap(imageStimCode));
    else
        BLAES_TestSequence_StimShift(i,7) = BLAES_TestSequence_StimShift(i,3);
    end
end


%% Behavioral Analysis 

%Key press options
NoResponse     = [67 86];
YesResponse    = [78 66];
ResponseKeys   = [NoResponse, YesResponse]; % 67 sure no, 86 maybe no, 66 maybe yes, 78 sure yes

%All values assocaited with the stimulation category for both items and
%scenes remains the same from the original dprime/hit rate/FA rate
%analysis. But now the no stimulation category represents no-stimulation
%images that came after stimulation

% Calculate max possible hits for each image/stim category
TotalItemHitStim    = GetBA_MaxPossible(BLAES_TestSequence_StimShift, 'old', 'item',  1);
TotalItemHitNoStim  = GetBA_MaxPossibleBeforeStim(BLAES_TestSequence_StimShift, 'old', 'item',  0, 1);

TotalSceneHitStim   = GetBA_MaxPossible(BLAES_TestSequence_StimShift, 'old', 'scene', 1);
TotalSceneHitNoStim = GetBA_MaxPossibleBeforeStim(BLAES_TestSequence_StimShift, 'old', 'scene', 0, 1);
    
% Calculate max possible false alarms for each image category
TotalItemFA  = GetBA_MaxPossible(BLAES_TestSequence_StimShift, 'new', 'item',  0);
TotalSceneFA = GetBA_MaxPossible(BLAES_TestSequence_StimShift, 'new', 'scene', 0);


for i = 1:size(BLAES_TestSequence_StimShift,1)
    % Calculate if an item/scene was a hit or miss during stim or nostim
    % for old and new items during retreival test
        
    ItemHit_Stim(i,1)     = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'old', 'item',  1, YesResponse);
    ItemHit_NoStim(i,1)   = CheckBAConditionsBeforeStim(BLAES_TestSequence_StimShift(i,:), 'old', 'item',  0, YesResponse, 1);
    SceneHit_Stim(i,1)    = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'old', 'scene', 1, YesResponse);
    SceneHit_NoStim(i,1)  = CheckBAConditionsBeforeStim(BLAES_TestSequence_StimShift(i,:), 'old', 'scene', 0, YesResponse, 1);
        
    ItemMiss_Stim(i,1)    = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'old', 'item',  1, NoResponse);
    ItemMiss_NoStim(i,1)  = CheckBAConditionsBeforeStim(BLAES_TestSequence_StimShift(i,:), 'old', 'item',  0, NoResponse, 1);
    SceneMiss_Stim(i,1)   = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'old', 'scene', 1, NoResponse);
    SceneMiss_NoStim(i,1) = CheckBAConditionsBeforeStim(BLAES_TestSequence_StimShift(i,:), 'old', 'scene', 0, NoResponse, 1);
        
    ItemFalseAlarm(i,1)   = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'new', 'item',  0, YesResponse);
    SceneFalseAlarm(i,1)  = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'new', 'scene', 0, YesResponse);
        
    ItemRejection(i,1)    = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'new', 'item',  0, NoResponse);
    SceneRejection(i,1)   = CheckBAConditions(BLAES_TestSequence_StimShift(i,:), 'new', 'scene', 0, NoResponse);
        
end


%% Figures

figsize        = [100 100 1200 800];

%% HIT RATE
% break out item and scene (hit rate out of total images)
labelstring = {'NoStim Item','Stim Item','NoStim Scene','Stim Scene'};
textStartY = 0.75;
textStepY  = 0.05;


HitRateStimBEFORE = figure('Position',figsize);
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
text(2.8,textStartY-1*textStepY,strcat(num2str(sum(ItemHit_NoStim)),' (out of ',num2str(TotalItemHitNoStim), ')'),'FontSize',18)
text(2.8,textStartY-2*textStepY,strcat(num2str(sum(ItemHit_Stim)),' (out of ',num2str(TotalItemHitStim), ')'),'FontSize',18)
text(2.8,textStartY-3*textStepY,strcat(num2str(sum(SceneHit_NoStim)),' (out of ',num2str(TotalSceneHitNoStim), ')'),'FontSize',18)
text(2.8,textStartY-4*textStepY,strcat(num2str(sum(SceneHit_Stim)),' (out of ',num2str(TotalSceneHitStim), ')'),'FontSize',18)
set(gca,'XTick',[1 2],'XTickLabel',{'item','scene'})
ylabel('Occurrences (% of Total)')
set(gca,'YTick',0:0.25:1,'YTickLabel',100*round(0:0.25:1,2))
set(gca,'FontName','Arial','FontSize',24,'LineWidth',2,'Box','off')
axis([0.5 3.0 0 1])
title([subjID, ' ', imageset ' Hit Rate StimBEFORE (out of total images)'])

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
savefile = fullfile(cd, 'figures', subjID, imageset, 'StimBEFOREAnalysis', strcat(subjID, '_', imageset,  '_HitRate_StimBEFORE.png'));

saveas(HitRateStimBEFORE, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')


%% FALSE ALARM RATE

labelstring = {'Item','Scene'};
textStartY = 0.75;
textStepY  = 0.05;

FARateStimBEFORE = figure('Position',figsize);
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
title([subjID, ' ', imageset ' False Alarm Rate StimBEFORE (out of total images)'])

fprintf('Saving novel images Figure...\n')
savefile = fullfile(cd, 'figures', subjID, imageset, 'StimBEFOREAnalysis', strcat(subjID, '_', imageset,  '_FARate_StimBEFORE.png'));


saveas(FARateStimBEFORE, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')


%% Dprime (Sure & Maybe - Loglinear)

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

dprimefig_StimBEFORE = figure('Position',figsize);
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
title([subjID, ' ', imageset ' DiscriminationIndex StimBEFORE (out of total images)'])

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
savefile = fullfile(cd, 'figures', subjID, imageset, 'StimBEFOREAnalysis', strcat(subjID, '_', imageset,  '_dprime_StimBEFORE.png'));

saveas(dprimefig_StimBEFORE, [savefile(1:end-4) '.png'],'png');
fprintf('Done\n')





%% BeforeStim Check (includes check for whether an image was preceded by stim during the Study phase)
function output = CheckBAConditionsBeforeStim(data,novelty,type,stim,KeyDownPressed,beforestim)

if strcmp(data{4},novelty) && data{3} == stim && contains(data{2},type) && data{7} == beforestim && any(ismember(KeyDownPressed,data{5})) % (data{5} == KeyDownPressed(1) || data{5} == KeyDownPressed(2))
    output = 1;
else
    output = 0;
end

end

function [TotalNoveltyTypeStimBeforeStim] = GetBA_MaxPossibleBeforeStim(data,novelty,type,stim,beforestim)

for i = 1:size(data,1)
    NoveltyPossible(i) = contains(data{i,4},novelty);

    TypePossible(i)  = contains(data{i,2},type);
    
    StimPossible(i)   = isequal(data{i,3},stim);

    BeforeStimPossible(i) = isequal(data{i,7},beforestim);
end

NoveltyTypeStimPossibleBeforeStim  = NoveltyPossible.*TypePossible.*StimPossible.*BeforeStimPossible;
TotalNoveltyTypeStimBeforeStim     = sum(NoveltyTypeStimPossibleBeforeStim);

end


%% Original check (identical to the original dprime analysis from the BLAES_Aim2_ItemScene_TestPhaseBehavioralAnalysis_Loglinear script)
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


