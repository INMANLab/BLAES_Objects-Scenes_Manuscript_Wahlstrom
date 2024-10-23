% Creates 3 sets of images for the items-vs-scenes task. Requires to have
% run "pick_source_images" first, or to already have a list of
% appropriately selected scenes and images.

%% Manually set:
temp_source_folder='/Users/lou.blanpain/Desktop/temp_largefiles'; %where temporarily stored source images

%% Set some directories:
fnames=struct();
fnames.temp_source_folder=temp_source_folder; %where will temporarily store source images
temp1=matlab.desktop.editor.getActiveFilename;
temp2=strfind(matlab.desktop.editor.getActiveFilename,filesep);
fnames.outputFolder=[temp1(1:temp2(end)) 'image_sets']; %where will store created image sets

fnames.Starklab_item_set=[fnames.temp_source_folder '/StarkLab-set_items']; %where will temporarily store StarkLab items
fnames.Starklab_item_set=[fnames.Starklab_item_set '/MST'];
fnames.Starklab_manual_bckground_masking=[temp1(1:temp2(end)) 'Starklab_set/manual-masking']; %where manually masked items are stored
fnames.Starklab_item_imtable=[temp1(1:temp2(end)) 'Starklab_set/item-list.csv']; %list of Starklab items

fnames.Places365_scene_set=[fnames.temp_source_folder '/Places365_scene_set']; %where will temporarily store source data for scenes (taken from http://places2.csail.mit.edu/download.html)
fnames.Places365stdval_scene_set=[fnames.Places365_scene_set '/val_large']; %the folder containing Places365 validation set images in high res
fnames.Places365stdval_scene_im_info=[fnames.Places365_scene_set '/filelist_places365-standard']; %assigns category to each image
fnames.Places365stdval_scene_hierarchy=[fnames.Places365_scene_set '/Scene hierarchy - Places365.csv']; %assigns feature (for ex, indoor/outdoor) to each category
fnames.Places365_scene_imtable=[temp1(1:temp2(end)) 'Places365_Set/scene-list.csv']; %list of Places365 selected scenes

nber_per_cat=124;

%% Check a few things
Places365stdval_scene_im_table=readtable(fnames.Places365_scene_imtable); %list of outside scenes we handpicked, to select from
Places365stdval_scene_hierarchy=readtable(fnames.Places365stdval_scene_hierarchy,'HeaderLines',1); %tells us which scene category is considered outside
Places365stdval_scene_hierarchy=Places365stdval_scene_hierarchy(:,{'category','indoor'}); %only keep these columns that we need
Places365stdval_scene_hierarchy.category=regexprep(Places365stdval_scene_hierarchy.category,'''',''); %remove extra '
Places365stdval_scene_code=readtable([fnames.Places365stdval_scene_im_info '/categories_places365.txt']); %tells us the scene codes
Places365stdval_scene_to_code=readtable([fnames.Places365stdval_scene_im_info '/places365_val.txt']); %tells us which scene code each image corresponds to

%check that there are no category name duplicates:
if length(unique(Places365stdval_scene_hierarchy.category))~=length(Places365stdval_scene_hierarchy.category)
    error('Found duplicate category names in the category sheet');
end

%check that the categories you've assigned to each image are correct:
for i=1:size(Places365stdval_scene_im_table,1)
    image_name=Places365stdval_scene_im_table{i,'name'};
    assigned_category=Places365stdval_scene_im_table{i,'category'};
    
    correct_scene_code=Places365stdval_scene_to_code{strcmp(Places365stdval_scene_to_code{:,1},image_name),2};
    correct_scene_name=Places365stdval_scene_code{Places365stdval_scene_code{:,2}==correct_scene_code,1};
    if ~strcmp(assigned_category,correct_scene_name)
        error('Found image for which we wrongly assigned category name.');
    end
end


%check that all the categories you have are indeed considered 'outside':
temp=unique(Places365stdval_scene_im_table.category);
temp=Places365stdval_scene_hierarchy{ismember(Places365stdval_scene_hierarchy.category,temp),'indoor'};
if ~all(temp==0)
    error('Found some picked categories that are not classified as ''outside''.');
end

%check that you have exactly 3 images of each category:
unique_categories=unique(Places365stdval_scene_im_table.category);
for i=1:length(unique_categories)
    if sum(strcmp(unique_categories{i},Places365stdval_scene_im_table.category))~=3
        error('Found a category that is NOT represented exactly 3 times.');
    end
end

%check that you have no duplicate images (by name of image):
if length(unique(Places365stdval_scene_im_table.name))~=length(Places365stdval_scene_im_table.name)
    error('We have duplicate images (by name).');
end

%ADD CODE TO CHECK FOR DUPLICATE IMAGES, BY LOOKING AT IMAGE CONTENT?


%% create metadata sheet for each image set, where we keep track of information about each image:
im_metadata={};

for image_set=1:3
    im_metadata{image_set}=table('Size',[nber_per_cat*5 10],'VariableNames',{'im_path','image_type','mean_luminance','mean_hue','origin','manual_bkg_mask','origin_cropped','resize','background','scramble_factor'},'VariableTypes',{'string','string','double','double','string','double','string','double','string','double'});
end


%% Make 3 sets of 123 outside scenes; no scene is repeated across sets, and each set has the same scene categories represented; modify the images so they all are squares with dimension 400x400 pixels
scene_cats=randsample(unique(Places365stdval_scene_im_table.category),nber_per_cat); %randomly pick 124 scene categories that we will use for the 3 image sets
Places365stdval_scene_im_table.set=zeros(size(Places365stdval_scene_im_table,1),1); %make column to determine which set a given image is assigned to

for image_set=1:3
    for i=1:length(scene_cats)
        temp=Places365stdval_scene_im_table(strcmp(Places365stdval_scene_im_table.category,scene_cats{i}) & Places365stdval_scene_im_table.set==0,:); %select scenes that are corresponding to that category, and have not been selected for an image set yet
        temp=randsample(temp.name,1); %pick 1 random image from that category, for that image set

        Places365stdval_scene_im_table{strcmp(Places365stdval_scene_im_table.name,temp),'set'}=image_set;
    end
end

%modify scenes and place them into respective set folders:
for image_set=1:3
    im_metadata_imnber=0;
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/scenes']); %create folder for image set, and subfolder for the scenes
    temp_name=Places365stdval_scene_im_table{Places365stdval_scene_im_table.set==image_set,'name'}; %get image names for this set
    for i=1:length(temp_name) %for each image
        current_scene=imread([fnames.Places365stdval_scene_set '/' temp_name{i}]); %read image
        
        im_metadata_imnber=im_metadata_imnber+1;
        im_metadata{image_set}(im_metadata_imnber,{'im_path','image_type','origin','manual_bkg_mask','background','scramble_factor'})...
                                            ={['/image_set' num2str(image_set) '/scenes/' temp_name{i}],'scene',['place365-val-large_' char(Places365stdval_scene_im_table{strcmp(Places365stdval_scene_im_table.name,temp_name{i}),'category'})],...
                                            nan,'na',nan};
        
        %check that this is a color image
        if ndims(current_scene)<3 %means we have a grayscale image
            error('Found a grayscale image');
        end
        
        %resize picture to a square if it is a rectangle (by removing pixels)
        temp_crop=[0 0 0 0]; %keep track of how many pixels cropped [left right up bottom]
        if size(current_scene,1)>size(current_scene,2) %more pixels in height than is width
            temp=size(current_scene,1)-size(current_scene,2);
            if temp==1 %means the difference is 1 pixel
                current_scene=current_scene(1:end-1,:,:);
                temp_crop(4)=1; %removed 1 pixel row in bottom
            else
                if mod(temp,2)==0 %if the difference is a multiple of 2
                    current_scene=current_scene(temp/2+1:end-temp/2,:,:); %remove half of begining of height, half of end of height
                    temp_crop([3 4])=temp/2;
                elseif mod(temp,2)~=0 %if the difference is not a multiple of 2
                    current_scene=current_scene(floor(temp/2)+1:end-(floor(temp/2)+1),:,:); %remove half of begining of height, half of end of height
                    temp_crop([3 4])=[floor(temp/2) floor(temp/2)+1];
                end
            end
        elseif size(current_scene,1)<size(current_scene,2) %more pixels in width than height
            temp=size(current_scene,2)-size(current_scene,1); %find how many extra pixels there are in width
            if temp==1 %means the difference is 1 pixel
                current_scene=current_scene(:,1:end-1,:); %remove last pixel in width
                temp_crop(2)=1;
            else %means difference is more than 1 pixel
                if mod(temp,2)==0 %if the difference is a multiple of 2
                    current_scene=current_scene(:,temp/2+1:end-temp/2,:); %remove half of begining of width, half of end of width
                    temp_crop([1 2])=temp/2;
                elseif mod(temp,2)~=0 %if the difference is not a multiple of 2
                    current_scene=current_scene(:,floor(temp/2)+1:end-(floor(temp/2)+1),:); %remove half of begining of width, half of end of width
                    temp_crop([1 2])=[floor(temp/2) floor(temp/2)+1];
                end
            end
        end
        
        im_metadata{image_set}(im_metadata_imnber,'origin_cropped')={num2str(temp_crop)};
        
        im_metadata{image_set}(im_metadata_imnber,'resize')={400/size(current_scene,1)};
        current_scene=imresize(current_scene,400/size(current_scene,1)); %resize scene so matches item pictures' dimensions (400x400)
        
        if size(current_scene,1)==401 %it seems that sometimes, can still get 1 extra pixel on each side after resizing the image (I think it has to do with division falling on very precise decimal number?)
            warning('Converted scene was 401x401- converting to 400x400');
            current_scene=current_scene(1:end-1,1:end-1,:); %remove last pixel in height and width
        end
        
        %make sure image is 400x400 pixels:
        temp_size_im=size(current_scene);
        if any(temp_size_im(1:2)~=400)
            error('An image is not 400x400 pixels, after checking and modifying...');
        end
        
        imwrite(current_scene,[fnames.outputFolder '/image_set' num2str(image_set) '/scenes/' temp_name{i}]);
    end
end

%% Pull 3 sets of 123 items, identify background, and modify the images so they all have dimension 400x400 pixels
item_table=readtable(fnames.Starklab_item_imtable); %read list of items, with column that indicates whether to consider item

%make sure your item list has all Stark images:
all_items=dir([fnames.Starklab_item_set '/*/*a.jpg']);
temp=regexprep({all_items.folder}',fnames.Starklab_item_set,'');
temp=arrayfun(@(x) any(strcmp(x,{'/Set C','/Set D','/Set E','/Set F'})),temp);
all_items=all_items(temp);
temp={all_items.folder};
temp=arrayfun(@(x) regexprep(x,fnames.Starklab_item_set,''),temp)'; %make list of paths to all pictures
all_items=string(strcat(temp,'/',{all_items.name}'));
if ~isequal(item_table.name,all_items)
    error('Item list does not have all of the Stark images ending in a.jpg!')
end

%exclude images we decided to exclude:
item_table=item_table(~item_table.exclude,:);

%randomly assign set number to images:
item_table.image_set=zeros(size(item_table,1),1);
Stark_set_names={'Set C','Set D','Set E','Set F'};
for image_set=1:3
    if image_set~=3
        image_group=find(startsWith(item_table.name,['/' Stark_set_names{image_set}])); %select images from given letter set
    elseif image_set==3
        %for image set 3, select as many images you can from set E, and the remaining from set F (because not enough non-excluded items in either)
        image_group=find(startsWith(item_table.name,['/' Stark_set_names{image_set}]));
        extra_images_setF=find(startsWith(item_table.name,'/Set F'));
        image_group=[image_group;randsample(extra_images_setF,nber_per_cat-length(image_group))];
    end
    image_group=randsample(image_group,nber_per_cat); %randomly sample a set of 124 items from that group
    item_table{image_group,'image_set'}=image_set;
end

%modify items and transfer them to respective image set folders:
temp_im_metadata_imnber=im_metadata_imnber;
for image_set=1:3
    im_metadata_imnber=temp_im_metadata_imnber;
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/temp/items']);
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/temp/bkgd-mask']);
    image_group=item_table{item_table.image_set==image_set,'name'}; %get set of items for this image set
    for i=1:length(image_group)
        current_image=imread([fnames.Starklab_item_set image_group{i}]); %load current item
        
        im_metadata_imnber=im_metadata_imnber+1;
        temp=regexp(image_group{i},'\.');
        temp=regexprep(image_group{i}(2:temp-1),'/| ','-');
        im_metadata{image_set}(im_metadata_imnber,{'im_path','image_type','origin'})...
                                            ={['/image_set' num2str(image_set) '/items-bgA/' temp '_scrambledA.jpg'],'item-scrambledA',['StarkLab-Set-' char(item_table{strcmp(item_table.name,image_group{i}),'Stark_set'})],...
                                            }; %create entry for item on bg A
        
        %check that this is a color image:
        if ndims(current_image)<3 
            error('Found a grayscale image');
        end
        
        %identify background of item image:
        set_name=[fnames.Starklab_item_set image_group{i}];
        temp=regexp(set_name,'/');
        image_name=set_name(temp(end)+1:end);
        set_name=set_name(temp(end)-1);
        if exist([fnames.Starklab_manual_bckground_masking '/Set ' set_name '/' image_name(1:end-4) '_masked.jpg'],'file') %check if we've manually masked the background for this image
            background_mask=imread([fnames.Starklab_manual_bckground_masking '/Set ' set_name '/' image_name(1:end-4) '_masked.jpg']); %read manually masked background
            im_metadata{image_set}(im_metadata_imnber,'manual_bkg_mask')={1};
            if ndims(background_mask)<3 %convert to color if we have B&W image
                background_mask=cat(3,background_mask,background_mask,background_mask);
            end
            background_mask=background_mask(:,:,1)<=128 & background_mask(:,:,2)<=128 & background_mask(:,:,3)<=128; %identify pixels likely to constitute the background (i.e. close to black)
        else %automatically mask background
            background_mask=current_image(:,:,1)>=240 & current_image(:,:,2)>=240 & current_image(:,:,3)>=240; %identify pixels likely to constitute the background (i.e. close to white)
            im_metadata{image_set}(im_metadata_imnber,'manual_bkg_mask')={0};
        end
        
        
        temp_size=size(current_image);
        
        %resize to 400 x 400 pixels:
        if any(temp_size(1:2)>400) %if image has higher dimensions than 400x400, resize so that length or width does not exceed 400 pixels
            warning('Found item image that is larger than 400x400- resizing...');
            im_metadata{image_set}(im_metadata_imnber,'resize')={400/max(size(current_image))};
            current_image=imresize(current_image,400/max(size(current_image))); %resize item
            background_mask=imresize(background_mask,400/max(size(background_mask))); %resize background
            temp_size=size(current_image);
        else
            im_metadata{image_set}(im_metadata_imnber,'resize')={1};
        end
        
        temp_crop=[0 0 0 0]; %keep track of how many pixels cropped [left right up bottom]
        if any(temp_size(1:2)<400) %if image is smaller than 400x400
            if temp_size(1)<400 %if height is smaller than 400 pixels
                if 400-temp_size(1)==1 %means the height is 399 instead of 400
                    current_image=cat(1,current_image,repmat(255,[1,temp_size(2),3])); %add 1 row of white pixels at the bottom
                    background_mask=cat(1,background_mask,repmat(1,[1,temp_size(2)])); %modify background mask accordingly
                    temp_crop(4)=-1;
                else %means height is more than 1 pixel difference from 400
                    if mod(400-temp_size(1),2)==0 %if difference is a multiple of 2
                        current_image=cat(1,repmat(255,[(400-temp_size(1))/2,temp_size(2),3]),current_image,repmat(255,[(400-temp_size(1))/2,temp_size(2),3])); %add white pixels, half to the top and half to the bottom of image, so get a height of 400
                        background_mask=cat(1,repmat(1,[(400-temp_size(1))/2,temp_size(2)]),background_mask,repmat(1,[(400-temp_size(1))/2,temp_size(2)])); %modify background mask accordingly
                        temp_crop([3 4])=-(400-temp_size(1))/2;
                    elseif mod(400-temp_size(1),2)~=0 %if difference is not a multiple of 2
                        current_image=cat(1,repmat(255,[floor((400-temp_size(1))/2),temp_size(2),3]),current_image,repmat(255,[floor((400-temp_size(1))/2)+1,temp_size(2),3])); %add white pixels, half to the top and half to the bottom of image, so get a height of 400
                        background_mask=cat(1,repmat(1,[floor((400-temp_size(1))/2),temp_size(2)]),background_mask,repmat(1,[floor((400-temp_size(1))/2)+1,temp_size(2)])); %modify background mask accordingly
                        temp_crop([3 4])=-[floor((400-temp_size(1))/2) floor((400-temp_size(1))/2)+1];
                    end
                end
                temp_size=size(current_image);
            end
            if temp_size(2)<400 %if width is smaller than 400
                if 400-temp_size(2)==1 %means the width is 399 instead of 400
                    current_image=cat(2,current_image,repmat(255,[temp_size(1),1,3])); %add 1 column of white pixels to the right
                    background_mask=cat(2,background_mask,repmat(1,[temp_size(1),1])); %modify background mask accordingly
                    temp_crop(2)=-1;
                else
                    if mod(400-temp_size(2),2)==0 %if difference is a multiple of 2
                        current_image=cat(2,repmat(255,[temp_size(1),(400-temp_size(2))/2,3]),current_image,repmat(255,[temp_size(1),(400-temp_size(2))/2,3])); %add white pixels, half to the left and half to the right of image, so get a width of 400
                        background_mask=cat(2,repmat(1,[temp_size(1),(400-temp_size(2))/2]),background_mask,repmat(1,[temp_size(1),(400-temp_size(2))/2])); %modify background mask accordingly
                        temp_crop([1 2])=-(400-temp_size(2))/2;
                    elseif mod(400-temp_size(2),2)~=0 %if difference is not a multiple of 2
                        current_image=cat(2,repmat(255,[temp_size(1),floor((400-temp_size(2))/2),3]),current_image,repmat(255,[temp_size(1),floor((400-temp_size(2))/2)+1,3])); %add white pixels, half to the left and half to the right of image, so get a width of 400
                        background_mask=cat(2,repmat(1,[temp_size(1),floor((400-temp_size(2))/2)]),background_mask,repmat(1,[temp_size(1),floor((400-temp_size(2))/2)+1])); %modify background mask accordingly
                        temp_crop([1 2])=-[floor((400-temp_size(2))/2) floor((400-temp_size(2))/2)+1];
                    end
                end
            end
        end
        
        im_metadata{image_set}(im_metadata_imnber,'origin_cropped')={num2str(temp_crop)};
        
        %make sure image and background mask are 400x400 pixels:
        temp_size_im=size(current_image);
        temp_size_bkg=size(background_mask);
        if any(temp_size_im(1:2)~=400) || any(temp_size_bkg(1:2)~=400)
            error('An image or background is not 400x400 pixels, after checking and modifying...');
        end
        
        %save image:
        imwrite(current_image,[fnames.outputFolder '/image_set' num2str(image_set) '/temp/items/' regexprep(image_group{i}(2:end),' |/','-')]);
        
        %save background mask:
        temp=regexprep(image_group{i},'\..+','');
        temp=regexprep(temp(2:end),' |/','-');
        save([fnames.outputFolder '/image_set' num2str(image_set) '/temp/bkgd-mask/' temp '_bg-mask.mat'],'background_mask');
    end
end


%% Produce items on scrambled backgrounds, scrambled items, and scrambled scenes:
%for phase scrambling used matlab function 'imscramble', found on http://martin-hebart.de/webpages/code/stimuli.html

scrambling_factor=1; %with lower factor of 0.9, started seeing a bit of the items for few pictures, for scrambled items on scrambled background. So picked max factor of 1.
temp_im_metadata_imnber=im_metadata_imnber;

for image_set=1:3
    im_metadata_imnber=temp_im_metadata_imnber;
    
    current_scene_set=dir([fnames.outputFolder '/image_set' num2str(image_set) '/scenes']); %get this set's scenes
    current_scene_set=current_scene_set(~ismember({current_scene_set.name},{'.','..','.DS_Store','Thumbs.db'})); %remove non-images
    current_scene_set={current_scene_set.name}';
    current_scene_set=current_scene_set(randperm(length(current_scene_set))); %randomize order in which we are going to pick scenes

    current_items_set=dir([fnames.outputFolder '/image_set' num2str(image_set) '/temp/items']); %get this set's items
    current_items_set=current_items_set(~ismember({current_items_set.name},{'.','..','.DS_Store','Thumbs.db'})); %remove non-images
    current_items_set={current_items_set.name}';
    current_items_set=current_items_set(randperm(length(current_items_set))); %randomize order in which we are going to pick items
        
    %make output subdirectories
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/scrambled-scenes']);
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/items-bgA']);
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/items-bgB']);
    mkdir([fnames.outputFolder '/image_set' num2str(image_set) '/scrambled-items']);
    
    for im=1:length(current_scene_set)
        
        current_scene=imread([fnames.outputFolder '/image_set' num2str(image_set) '/scenes/' current_scene_set{im}]); %read scene
        temp_scene=regexp(current_scene_set{im},'\.');
        current_item=imread([fnames.outputFolder '/image_set' num2str(image_set) '/temp/items/' current_items_set{im}]); %read item
        temp_item=regexp(current_items_set{im},'\.');
        temp=load([fnames.outputFolder '/image_set' num2str(image_set) '/temp/bkgd-mask/' current_items_set{im}(1:end-4) '_bg-mask.mat'],'background_mask'); %load background mask for that item
        current_background_mask=temp.background_mask;
        
        %produce and write scrambled scene (to use as 'baseline' stimulus):
        scrambled_scene=imscramble(current_scene,scrambling_factor); %scramble the scene
        im_metadata_imnber=im_metadata_imnber+1;
        im_metadata{image_set}(im_metadata_imnber,{'im_path','image_type','manual_bkg_mask','background','scramble_factor'})...
                                            ={['/image_set' num2str(image_set) '/scrambled-scenes/' current_scene_set{im}(1:temp_scene(end)-1) '_scrambled.jpg'],'scrambled-scene',nan,'na',scrambling_factor};
        im_metadata{image_set}(im_metadata_imnber,{'origin','origin_cropped','resize'})=im_metadata{image_set}(strcmp(im_metadata{image_set}{:,'im_path'},['/image_set' num2str(image_set) '/scenes/' current_scene_set{im}]),{'origin','origin_cropped','resize'});
        imwrite(scrambled_scene,[fnames.outputFolder '/image_set' num2str(image_set) '/scrambled-scenes/' current_scene_set{im}(1:temp_scene(end)-1) '_scrambled.jpg']); %write scrambled scene to file
        
        %transform background mask and item image to linear forms:
        current_background_mask=reshape(current_background_mask,[1,size(current_background_mask,1)*size(current_background_mask,2)]); %transform background mask to linear form
        current_item_linear=reshape(current_item,[size(current_item,1)*size(current_item,2),3]); %transform item image to linear form
        
        %create and write item on backgroundA:
        item_scrambled_backgroundA=imscramble(current_scene,scrambling_factor); %scramble the scene
        item_scrambled_backgroundA=reshape(item_scrambled_backgroundA,[size(item_scrambled_backgroundA,1)*size(item_scrambled_backgroundA,2),3]); %transform scrambled scene to linear form
        item_scrambled_backgroundA(~current_background_mask,:)=current_item_linear(~current_background_mask,:); %place item content (not background) into scrambled scene, using same position as in item image
        item_scrambled_backgroundA=reshape(item_scrambled_backgroundA,[size(current_item,1),size(current_item,2),3]); %transform back linear to regular image
        
        im_metadata{image_set}(strcmp(im_metadata{image_set}{:,'im_path'},['/image_set' num2str(image_set) '/items-bgA/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA.jpg']),{'background','scramble_factor'})=...
                                                                    {['/image_set' num2str(image_set) '/scenes/' current_scene_set{im}],scrambling_factor};
        imwrite(item_scrambled_backgroundA,[fnames.outputFolder '/image_set' num2str(image_set) '/items-bgA/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA.jpg']); %write item on scrambled background A to file
        
        %create and write item on background B:
        item_scrambled_backgroundB=imscramble(current_scene,scrambling_factor); %scramble the scene
        item_scrambled_backgroundB=reshape(item_scrambled_backgroundB,[size(item_scrambled_backgroundB,1)*size(item_scrambled_backgroundB,2),3]); %transform scrambled scene to linear form
        item_scrambled_backgroundB(~current_background_mask,:)=current_item_linear(~current_background_mask,:); %place item content (not background) into scrambled scene, using same position as in item image
        item_scrambled_backgroundB=reshape(item_scrambled_backgroundB,[size(current_item,1),size(current_item,2),3]); %transform back linear to regular image
        
        im_metadata_imnber=im_metadata_imnber+1;
        im_metadata{image_set}(im_metadata_imnber,{'im_path','image_type'})={['/image_set' num2str(image_set) '/items-bgB/' current_items_set{im}(1:temp_item(end)-1) '_scrambledB.jpg'],'item-scrambledB'};
        im_metadata{image_set}(im_metadata_imnber,{'origin','manual_bkg_mask','origin_cropped','resize','background','scramble_factor'})=im_metadata{image_set}(strcmp(im_metadata{image_set}{:,'im_path'},['/image_set' num2str(image_set) '/items-bgA/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA.jpg']),{'origin','manual_bkg_mask','origin_cropped','resize','background','scramble_factor'});
        imwrite(item_scrambled_backgroundB,[fnames.outputFolder '/image_set' num2str(image_set) '/items-bgB/' current_items_set{im}(1:temp_item(end)-1) '_scrambledB.jpg']); %write item to file
        
        %create and write scrambled item+scrambled background A (to use as 'baseline' stimulus):
        scrambled_item=imscramble(item_scrambled_backgroundA,scrambling_factor); %scramble item on backgroundA
        
        im_metadata_imnber=im_metadata_imnber+1;
        im_metadata{image_set}(im_metadata_imnber,{'im_path','image_type','scramble_factor'})={['/image_set' num2str(image_set) '/scrambled-items/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA-scrambled.jpg'],'scrambled-item',scrambling_factor};
        im_metadata{image_set}(im_metadata_imnber,{'origin','manual_bkg_mask','origin_cropped','resize','background'})=im_metadata{image_set}(strcmp(im_metadata{image_set}{:,'im_path'},['/image_set' num2str(image_set) '/items-bgA/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA.jpg']),{'origin','manual_bkg_mask','origin_cropped','resize','background'});
        imwrite(scrambled_item,[fnames.outputFolder '/image_set' num2str(image_set) '/scrambled-items/' current_items_set{im}(1:temp_item(end)-1) '_scrambledA-scrambled.jpg']); %write scrambled item to file
    end
    
end

%% add information about luminance and hue for each image, and save metadata table:

for image_set=1:3
    for im=1:size(im_metadata{image_set},1)
        current_im=imread(strcat(fnames.outputFolder,im_metadata{image_set}{im,'im_path'})); %read image
        
        im_metadata{image_set}(im,'mean_luminance')={mean2(rgb2gray(current_im))};
        
        temp=rgb2hsv(current_im); %converts RGB image to hue, saturation and value
        im_metadata{image_set}(im,'mean_hue')={mean2(temp(:,:,1))}; %calculates the mean hue
    end
    
    %save metadata table:
    writetable(im_metadata{image_set},[fnames.outputFolder '/image_set' num2str(image_set) '/metadata_image-set-' num2str(image_set) '.csv']);
end


%% check that luminance, hue and spatial frequency have similar mean and sd between the item and scene sets:
%to estimate whether 2 sets are significantly different in terms of spatial frequency, have used Aude Olivia's toolbox (https://www.sciencedirect.com/science/article/pii/S2352340915002784)

image_types={'item-scrambledA','item-scrambledB','scene','scrambled-item','scrambled-scene'}; %the image types we want to compare features' discributions of
image_types_folders={'items-bgA','items-bgB','scenes','scrambled-items','scrambled-scenes'};

for image_set=1:3
    figure('Units','normalized','Position',[0 0 1 1],'Name',['Image set ' num2str(image_set)]);
    tiledlayout(3,1);
    
    %analyze luminance:
    nexttile;
    hold on;
    temp_matrix=[im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{1}),'mean_luminance'},im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{2}),'mean_luminance'},...
                 im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{3}),'mean_luminance'},im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{4}),'mean_luminance'},...
                 im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{5}),'mean_luminance'}];
    boxplot(temp_matrix);
    temp=ones(1,size(temp_matrix,1)).*[1 2 3 4 5]';
    temp=reshape(temp',1,numel(temp));
    for n=1:length(temp)
        temp(n)=temp(n)+rand*0.5-0.25;
    end
    scatter(temp,reshape(temp_matrix,1,numel(temp_matrix)),'k','filled','MarkerFaceAlpha',0.5);
    
    xticklabels({[image_types{1} ': m=' num2str(round(mean(temp_matrix(:,1)),2)) ', sd=' num2str(round(std(temp_matrix(:,1)),2))],...
        [image_types{2} ': m=' num2str(round(mean(temp_matrix(:,2)),2)) ', sd=' num2str(round(std(temp_matrix(:,2)),2))],...
        [image_types{3} ': m=' num2str(round(mean(temp_matrix(:,3)),2)) ', sd=' num2str(round(std(temp_matrix(:,3)),2))],...
        [image_types{4} ': m=' num2str(round(mean(temp_matrix(:,4)),2)) ', sd=' num2str(round(std(temp_matrix(:,4)),2))],...
        [image_types{5} ': m=' num2str(round(mean(temp_matrix(:,5)),2)) ', sd=' num2str(round(std(temp_matrix(:,5)),2))]});
    ylabel('Mean luminance');
    
    title(['Luminance' newline '1-way anova p-val: ' num2str(round(anova1(temp_matrix,'','off'),2))],'Interpreter','none');
    
    %analyze hue:
    nexttile;
    hold on;
    temp_matrix=[im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{1}),'mean_hue'},im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{2}),'mean_hue'},...
                 im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{3}),'mean_hue'},im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{4}),'mean_hue'},...
                 im_metadata{image_set}{strcmp(im_metadata{image_set}.image_type,image_types{5}),'mean_hue'}];
    boxplot(temp_matrix);
    temp=ones(1,size(temp_matrix,1)).*[1 2 3 4 5]';
    temp=reshape(temp',1,numel(temp));
    for n=1:length(temp)
        temp(n)=temp(n)+rand*0.5-0.25;
    end
    scatter(temp,reshape(temp_matrix,1,numel(temp_matrix)),'k','filled','MarkerFaceAlpha',0.5);
    
    xticklabels({[image_types{1} ': m=' num2str(round(mean(temp_matrix(:,1)),2)) ', sd=' num2str(round(std(temp_matrix(:,1)),2))],...
        [image_types{2} ': m=' num2str(round(mean(temp_matrix(:,2)),2)) ', sd=' num2str(round(std(temp_matrix(:,2)),2))],...
        [image_types{3} ': m=' num2str(round(mean(temp_matrix(:,3)),2)) ', sd=' num2str(round(std(temp_matrix(:,3)),2))],...
        [image_types{4} ': m=' num2str(round(mean(temp_matrix(:,4)),2)) ', sd=' num2str(round(std(temp_matrix(:,4)),2))],...
        [image_types{5} ': m=' num2str(round(mean(temp_matrix(:,5)),2)) ', sd=' num2str(round(std(temp_matrix(:,5)),2))]});
    ylabel('Mean hue');
    
    title(['Hue' newline '1-way anova p-val: ' num2str(round(anova1(temp_matrix,'','off'),2))],'Interpreter','none');
    
    %analyze spatial frequency:
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{1} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{2} '/'],10,10:20:100,0);
    annotation('textbox', [1/11, 0.30, 0, 0], 'string', [image_types_folders{1} ' vs ' image_types_folders{2} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{1} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{3} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*2, 0.30, 0, 0], 'string', [image_types_folders{1} ' vs ' image_types_folders{3} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{1} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{4} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*3, 0.30, 0, 0], 'string', [image_types_folders{1} ' vs ' image_types_folders{4} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{1} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{5} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*4, 0.30, 0, 0], 'string', [image_types_folders{1} ' vs ' image_types_folders{5} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{2} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{3} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*5, 0.30, 0, 0], 'string', [image_types_folders{2} ' vs ' image_types_folders{3} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{2} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{4} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*6, 0.30, 0, 0], 'string', [image_types_folders{2} ' vs ' image_types_folders{4} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{2} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{5} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*7, 0.30, 0, 0], 'string', [image_types_folders{2} ' vs ' image_types_folders{5} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{3} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{4} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*8, 0.30, 0, 0], 'string', [image_types_folders{3} ' vs ' image_types_folders{4} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{3} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{5} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*9, 0.30, 0, 0], 'string', [image_types_folders{3} ' vs ' image_types_folders{5} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    [~, Ef_p, ~, Qhf_p] = CompareSpectraEnergy([fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{4} '/'], [fnames.outputFolder '/image_set' num2str(image_set) '/' image_types_folders{5} '/'],10,10:20:100,0);
    annotation('textbox', [1/11*10, 0.30, 0, 0], 'string', [image_types_folders{4} ' vs ' image_types_folders{5} newline newline 'Ef_p= ' num2str(Ef_p) newline newline 'Qhf_p= ' num2str(Qhf_p)],'FontSize',12,'FontWeight','bold','Interpreter','none');
    
    print(gcf,[fnames.outputFolder '/image_set' num2str(image_set) '/features_set' num2str(image_set)],'-deps');
    close(gcf);
    
end


%% manually check that resulting items on scrambled background, and scenes look good (i.e. not difficult to see, no weird cropping); moreover, image types are not statistically different in features (except for spatial feature)


