

%Stark lab image set fetched from https://github.com/celstark/MST (sets C,
%D and E)

StarkLab_ImageSets='/Users/lou.blanpain/Desktop/StarkLab_ImageSets';

for item_set={'Set C','Set D','Set E'}
    current_items_set=dir([StarkLab_ImageSets '/' item_set{:} '/*a.jpg']);
    current_items_set=current_items_set(~ismember({current_items_set.name},{'.','..','.DS_Store','Thumbs.db'})); %get this set's items
    current_items_set={current_items_set.name}';

    mkdir([StarkLab_ImageSets '/' item_set{:} '/background_masking_performance']);
    mkdir([StarkLab_ImageSets '/' item_set{:} '/manual_background_masking']);
    for im=1:length(current_items_set)
        current_item=imread([StarkLab_ImageSets '/' item_set{:} '/' current_items_set{im}]); %read image
        if ndims(current_item)<3 %means we have a grayscale image
            current_item=cat(3,current_item,current_item,current_item); %convert to RGB image
        end
        background_mask=~(current_item(:,:,1)>=240 & current_item(:,:,2)>=240 & current_item(:,:,3)>=240); %identify pixels likely to constitute the background (i.e. close to white)

        %show how well we identified background:
        f=figure;
        subplot(1,3,1)
        imshow(current_item);
        subplot(1,3,2)
        imshow(current_item);
        hold on;
        h=imshow(background_mask);
        set(h,'AlphaData',0.5);
        subplot(1,3,3)
        imshow(background_mask);
        
        %save performance of code for masking background:
        print('-djpeg', [StarkLab_ImageSets '/' item_set{:} '/background_masking_performance/' current_items_set{im}(1:end-4) '.jpg']);
        close (f);
    end
end