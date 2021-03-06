% Open locs Ch1 and Ch2

clear,clc, close all

nameC2 = 'Z:\Christian-Sieben\data_HTP\2018-03-08_humanCent_3C_Sas6_Cep152_Centrin\locResults\Cep152_DL755_1_1/humanCent_Cep57_Sas6_DL755_4_1_MMStack_1_Localizations.csv';
nameC1 = '/Users/christian/Documents/Arbeit/MatLab/SPARTAN_gui/example_data/humanCent_STILL_A647_4_1_MMStack_1_Localizations.csv';

[filepath_Ch1,name_Ch1,ext_Ch1] = fileparts(nameC1);
[filepath_Ch2,name_Ch2,ext_Ch2] = fileparts(nameC2);

% Load file first channel

locs_Ch1 = dlmread([name_Ch1 ext_Ch1],',',1,0);
locs_Ch2 = dlmread([name_Ch2 ext_Ch2],',',1,0);

locs_Ch1(:,end+1) = 1; % Channel ID
locs_Ch2(:,end+1) = 2; % Channel ID

% Load the header and find the right Columns

file = fopen(nameC1);
line = fgetl(file);
h = regexp( line, ',', 'split' );

xCol      = strmatch('x [nm]',h);
yCol      = strmatch('y [nm]',h);
frameCol  = strmatch('frame',h);
deltaXCol = size(locs_Ch1,2)+1;
deltaYCol = size(locs_Ch1,2)+2;

%% Apply Affine to Ch2 dataset

T1 = load('Global_LWMtrans_2017-09-07_images.mat');

moving = []; moving = locs_Ch2(:,xCol:yCol);

corrected_moving = transformPointsInverse(T1.T_lwm,moving);

locs_Ch2(:,xCol) = corrected_moving(:,1);
locs_Ch2(:,yCol) = corrected_moving(:,2);

% Filter out of bound points

locs_Ch2_filtered = [];
locs_Ch2_filtered = locs_Ch2(locs_Ch2(:,xCol)<1e5,1:end);
locs_Ch2          = locs_Ch2_filtered;

%% Combine Channels and select fiducials from Image

allLocs = vertcat(locs_Ch1,locs_Ch2);

pxlsize = 600;

heigth  = round((max(allLocs(:,yCol))-min(allLocs(:,yCol)))/pxlsize);
width   = round((max(allLocs(:,xCol))-min(allLocs(:,xCol)))/pxlsize);
im      = hist3([allLocs(:,xCol),allLocs(:,yCol)],[width heigth]); % heigth x width

% Select rectangles

rect = []; rect2 = [];

figure('Position',[100 200 400 400])
f = imagesc(imrotate(im,90),[(max(locs_Ch1(:,frameCol))+max(locs_Ch2(:,frameCol)))*0.6 max(locs_Ch1(:,frameCol))+max(locs_Ch2(:,frameCol))]);
colormap('parula'); colorbar;

while isvalid(f)

  try  rect = getrect;

       rect2 = vertcat(rect2,rect); 
       
  catch continue
  end

end


fprintf('\n -- ROI selected --\n')

% Plot fiducials and average curve rectangles

% Select ROI for both channels

Fid_Ch1 = []; Fid_Ch2 = [];

for i = 1:size(rect2,1);
    
xmin = min(allLocs(:,xCol))+ rect2(i,1)*pxlsize;
ymin = max(allLocs(:,yCol)) - rect2(i,2)*pxlsize - (rect2(i,4)*pxlsize) ;
xmax = xmin + (rect2(i,3)* pxlsize);
ymax = ymin + rect2(i,4) * pxlsize;

vx      = find(allLocs(:,xCol)>xmin & allLocs(:,xCol)<xmax);
subset1 = allLocs(vx,1:end);

vy      = find(subset1(:,yCol)>ymin & subset1(:,yCol)<ymax);
subset2 = subset1(vy,1:end);

subset2(:,end+1)=i; % Region ID

Fid_Ch1 = vertcat(Fid_Ch1,subset2(subset2(:,end-1)==1,1:end));
Fid_Ch2 = vertcat(Fid_Ch2,subset2(subset2(:,end-1)==2,1:end));

end

% Plot the fiducials

close all

for i = 1:max(Fid_Ch1(:,end));
    
    figure('Position',[100 200 400 400])  
    scatter(Fid_Ch1(Fid_Ch1(:,end)==i,frameCol),Fid_Ch1(Fid_Ch1(:,end)==i,yCol),1,'green');hold on;
    scatter(Fid_Ch2(Fid_Ch2(:,end)==i,frameCol),Fid_Ch2(Fid_Ch2(:,end)==i,yCol),1,'red');
    legend('Ch1','Ch2');
    
end

%% Select the fiducials and Normalize them to their center of mass

close all;

selectedFid = [1,2,4];

Avg_Ch1x = []; Avg_Ch1y = []; Avg_Ch1 = []; Avg_Ch1frame = [];Avg_Ch1ID = [];

for i = selectedFid;
    
    target  = find(Fid_Ch1(:,9)==i & Fid_Ch1(:,frameCol)<1000);
    offsetX = median(Fid_Ch1(target,xCol)); offsetY = median(Fid_Ch1(target,yCol)); % median of the first 1000 frames 
    
    Avg_Ch1x        = vertcat(Avg_Ch1x,Fid_Ch1(Fid_Ch1(:,9)==i,xCol)-offsetX);
    Avg_Ch1y        = vertcat(Avg_Ch1y,Fid_Ch1(Fid_Ch1(:,9)==i,yCol)-offsetY);
    Avg_Ch1frame    = vertcat(Avg_Ch1frame,Fid_Ch1(Fid_Ch1(:,9)==i,frameCol));
    Avg_Ch1ID       = vertcat(Avg_Ch1ID,Fid_Ch1(Fid_Ch1(:,9)==i,9)); % Region ID
    
end

Avg_Ch1      = Avg_Ch1x;
Avg_Ch1(:,2) = Avg_Ch1y;
Avg_Ch1(:,3) = Avg_Ch1frame;
Avg_Ch1(:,4) = Avg_Ch1ID; % Region ID

clear Avg_Ch1x Avg_Ch1y Avg_Ch1frame Avg_Ch1ID


Avg_Ch2x = []; Avg_Ch2y = []; Avg_Ch2 = []; Avg_Ch2frame = [];Avg_Ch2ID = [];

for i = selectedFid;
    
    target = find(Fid_Ch2(:,9)==i & Fid_Ch2(:,frameCol)<1000);
    offsetX = median(Fid_Ch2(target,xCol)); offsetY = median(Fid_Ch2(target,yCol));
    
    Avg_Ch2x        = vertcat(Avg_Ch2x,Fid_Ch2(Fid_Ch2(:,9)==i,xCol)-offsetX);
    Avg_Ch2y        = vertcat(Avg_Ch2y,Fid_Ch2(Fid_Ch2(:,9)==i,yCol)-offsetY);
    Avg_Ch2frame    = vertcat(Avg_Ch2frame,Fid_Ch2(Fid_Ch2(:,9)==i,frameCol));
    Avg_Ch2ID       = vertcat(Avg_Ch2ID,Fid_Ch2(Fid_Ch2(:,9)==i,9)); % Region ID
    
end

Avg_Ch2      = Avg_Ch2x;
Avg_Ch2(:,2) = Avg_Ch2y;
Avg_Ch2(:,3) = Avg_Ch2frame;
Avg_Ch2(:,4) = Avg_Ch2ID; % Region ID

clear Avg_Ch2x Avg_Ch2y Avg_Ch2frame Avg_Ch2ID

figure('Position', [200 200 400 500])
subplot(2,1,1)
scatter(Avg_Ch1(:,3),Avg_Ch1(:,1),1,'g'); hold on;
scatter(Avg_Ch1(:,3),Avg_Ch1(:,2),1,'r'); hold on;
title('Channel 1'); box on;
legend('X drift', 'Y Drift');

subplot(2,1,2)
scatter(Avg_Ch2(:,3),Avg_Ch2(:,1),1,'g'); hold on;
scatter(Avg_Ch2(:,3),Avg_Ch2(:,2),1,'r'); hold on;
title('Channel 2'); box on;
legend('X drift', 'Y Drift');

%% Average the fiducial tracks 

close all;

% Channel 1

Avg_Ch1_new = []; count = 1;

for i = min(Avg_Ch1(:,frameCol)):max(Avg_Ch1(:,frameCol));      % For all frames

   target = find(Avg_Ch1(:,frameCol) == i);                     % find all fiducials in frame i
   
   if isempty(target);
   else    
   
   Avg_Ch1_new(i,1) = i; % frame
   Avg_Ch1_new(i,2) = mean(Avg_Ch1(target,xCol));               % mean x of all fiducials in frame i
   Avg_Ch1_new(i,3) = mean(Avg_Ch1(target,yCol));               % mean x of all fiducials in frame i
   
   cont = count +1;
   end
   
end

Avg_Ch1_new(1:min(Avg_Ch1(:,frameCol))-1,:) = [];

% Channel 2

Avg_Ch2_new = []; count = 1;

for i = min(Avg_Ch2(:,frameCol)):max(Avg_Ch2(:,frameCol));      % For all frames

   target = find(Avg_Ch2(:,frameCol) == i);                     % find all fiducials in frame i
   
   if isempty(target);
   else    
   
   Avg_Ch2_new(i,1) = i; % frame
   Avg_Ch2_new(i,2) = mean(Avg_Ch2(target,xCol));               % mean x of all fiducials in frame i
   Avg_Ch2_new(i,3) = mean(Avg_Ch2(target,yCol));               % mean x of all fiducials in frame i
   
   cont = count +1;
   end
   
end

Avg_Ch2_new(1:min(Avg_Ch2(:,frameCol))-1,:) = [];

figure('Position', [200 200 400 500])
subplot(2,1,1)
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,2),1,'g'); hold on;
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,3),1,'r'); hold on;
title('Channel 1'); box on;
legend('X drift', 'Y Drift');

subplot(2,1,2)
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,2),1,'g'); hold on;
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,3),1,'r'); hold on;
title('Channel 2'); box on;
legend('X drift', 'Y Drift');

%% Spline fit average 

close all

%%%%%

NbrBins             = 100;
radius              = 200; % Radius around the fiducial center
smoothingFactor     = 100;
startFrame          = 1000;

%%%%%

% Channel 1

[splineResX,AvgCurveX,pX] = splineFit(Avg_Ch1_new(:,1),Avg_Ch1_new(:,2),NbrBins,radius,smoothingFactor); % (xData,yData,NbrBins,radius,smoothingFactor);
[splineResY,AvgCurveY,pY] = splineFit(Avg_Ch1_new(:,1),Avg_Ch1_new(:,3),NbrBins,radius,smoothingFactor);

figure('Position', [200 200 700 500],'NumberTitle', 'off', 'Name', 'Drift correction Ch1')
subplot(2,3,1)
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,2),2,'b'), hold on;
plot(splineResX(:,1),splineResX(:,2),'r.'), hold on;
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on

subplot(2,3,2)
plot(AvgCurveX(:,1),AvgCurveX(:,2),'o'); hold on;
fnplt(csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/smoothingFactor),'r--')
legend('noisy data','smoothing spline'), hold off
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on

subplot(2,3,4)
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,3),2,'b'), hold on;
plot(splineResY(:,1),splineResY(:,2),'r.'), hold on;
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on

subplot(2,3,5)
plot(AvgCurveY(:,1),AvgCurveY(:,2),'o'); hold on;
fnplt(csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/smoothingFactor),'r--')
legend('noisy data','smoothing spline'), hold off
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on

% Correct Channel 1 Averages Tracks

Avg_Ch1_new(:,4) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, Avg_Ch1_new(:,1)); % spline fit of the X Ch1
Avg_Ch1_new(:,5) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, Avg_Ch1_new(:,1)); % spline fit of the Y Ch1

Avg_Ch1_new(1:startFrame,4) = 0;
Avg_Ch1_new(1:startFrame,5) = 0;

Avg_Ch1_new(:,4) = Avg_Ch1_new(:,4)-Avg_Ch1_new(startFrame,4); % deltaX
Avg_Ch1_new(:,5) = Avg_Ch1_new(:,5)-Avg_Ch1_new(startFrame,5); % deltaY

% Correct Channel 1 Fiducial Tracks

Fid_Ch1(:,deltaXCol+1) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, Fid_Ch1(:,frameCol));
Fid_Ch1(:,deltaYCol+1) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, Fid_Ch1(:,frameCol));

Fid_Ch1(1:startFrame,deltaXCol+1) = 0;
Fid_Ch1(1:startFrame,deltaYCol+1) = 0;

Fid_Ch1(:,deltaXCol+1) = Fid_Ch1(:,deltaXCol+1)-Fid_Ch1(startFrame,deltaXCol+1); % deltaX
Fid_Ch1(:,deltaYCol+1) = Fid_Ch1(:,deltaYCol+1)-Fid_Ch1(startFrame,deltaYCol+1); % deltaY

% Test it
% scatter(Fid_Ch1(:,frameCol),Fid_Ch1(:,xCol)-Fid_Ch1(:,deltaXCol),1,'k');hold on;
% scatter(Fid_Ch1(:,frameCol),Fid_Ch1(:,yCol)-Fid_Ch1(:,deltaYCol),1,'r');

% Correct Channel 1 locs

locs_Ch1(:,deltaXCol) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, locs_Ch1(:,frameCol));
locs_Ch1(:,deltaYCol) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, locs_Ch1(:,frameCol));

locs_Ch1(1:startFrame,deltaXCol) = 0;
locs_Ch1(1:startFrame,deltaYCol) = 0;

locs_Ch1(:,deltaXCol) = locs_Ch1(:,deltaXCol)-locs_Ch1(startFrame,deltaXCol); % deltaX
locs_Ch1(:,deltaYCol) = locs_Ch1(:,deltaYCol)-locs_Ch1(startFrame,deltaYCol); % deltaY

locs_Ch1(:,xCol) = locs_Ch1(:,xCol)-locs_Ch1(:,deltaXCol); % substract deltaX from X Col
locs_Ch1(:,yCol) = locs_Ch1(:,yCol)-locs_Ch1(:,deltaYCol); % substract deltaY from Y Col


subplot(2,3,3)
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,2)-Avg_Ch1_new(:,4),1,'b'), hold on;
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on
title('X trajectory after correction');

subplot(2,3,6)
scatter(Avg_Ch1_new(:,1),Avg_Ch1_new(:,3)-Avg_Ch1_new(:,5),1,'b'), hold on;
axis([0 max(Avg_Ch1_new(:,1)) -radius radius])
axis square; box on
title('Y trajectory after correction'); 

% Channel 2

[splineResX,AvgCurveX,pX] = splineFit(Avg_Ch2_new(:,1),Avg_Ch2_new(:,2),NbrBins,radius,smoothingFactor);
[splineResY,AvgCurveY,pY] = splineFit(Avg_Ch2_new(:,1),Avg_Ch2_new(:,3),NbrBins,radius,smoothingFactor);

figure('Position', [200 200 700 500],'NumberTitle', 'off', 'Name', 'Drift correction Ch2')
subplot(2,3,1)
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,2),2,'b'), hold on;
plot(splineResX(:,1),splineResX(:,2),'r.'), hold on;
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on
title('X trajectory before correction');

subplot(2,3,2)
plot(AvgCurveX(:,1),AvgCurveX(:,2),'o'); hold on;
fnplt(csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/smoothingFactor),'--')
legend('noisy data','smoothing spline'), hold off
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on

subplot(2,3,4)
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,3),2,'b'), hold on;
plot(splineResY(:,1),splineResY(:,2),'r.'), hold on;
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on
title('Y trajectory before correction');

subplot(2,3,5)
plot(AvgCurveY(:,1),AvgCurveY(:,2),'o'); hold on;
fnplt(csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/smoothingFactor),'--')
legend('noisy data','smoothing spline'), hold off
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on

% Correct Channel 2 X Averages

Avg_Ch2_new(:,4) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, Avg_Ch2_new(:,1)); % spline fit of the X Ch1
Avg_Ch2_new(:,5) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, Avg_Ch2_new(:,1)); % spline fit of the Y Ch1

Avg_Ch2_new(1:startFrame,4) = 0;
Avg_Ch2_new(1:startFrame,5) = 0;

Avg_Ch2_new(:,4) = Avg_Ch2_new(:,4)-Avg_Ch2_new(startFrame,4); % deltaX
Avg_Ch2_new(:,5) = Avg_Ch2_new(:,5)-Avg_Ch2_new(startFrame,5); % deltaY

% Correct Channel 2 Fiducial Tracks

Fid_Ch2(:,deltaXCol+1) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, Fid_Ch2(:,frameCol));
Fid_Ch2(:,deltaYCol+1) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, Fid_Ch2(:,frameCol));

Fid_Ch2(1:startFrame,deltaXCol+1) = 0;
Fid_Ch2(1:startFrame,deltaYCol+1) = 0;

Fid_Ch2(:,deltaXCol+1) = Fid_Ch2(:,deltaXCol+1)-Fid_Ch2(startFrame,deltaXCol+1); % deltaX
Fid_Ch2(:,deltaYCol+1) = Fid_Ch2(:,deltaYCol+1)-Fid_Ch2(startFrame,deltaYCol+1); % deltaY

% Test it
% scatter(Fid_Ch2(:,frameCol),Fid_Ch2(:,xCol)-Fid_Ch2(:,deltaXCol+1),1,'k');hold on;
% scatter(Fid_Ch2(:,frameCol),Fid_Ch2(:,yCol)-Fid_Ch2(:,deltaYCol+1),1,'r');

% Correct Channel 2 locs

locs_Ch2(:,deltaXCol) = csaps(AvgCurveX(:,1),AvgCurveX(:,2),pX/100, locs_Ch2(:,frameCol));
locs_Ch2(:,deltaYCol) = csaps(AvgCurveY(:,1),AvgCurveY(:,2),pY/100, locs_Ch2(:,frameCol));

locs_Ch2(1:startFrame,deltaXCol) = 0;
locs_Ch2(1:startFrame,deltaYCol) = 0;

locs_Ch2(:,deltaXCol) = locs_Ch2(:,deltaXCol)-locs_Ch2(startFrame,deltaXCol); % deltaX
locs_Ch2(:,deltaYCol) = locs_Ch2(:,deltaYCol)-locs_Ch2(startFrame,deltaYCol); % deltaY

locs_Ch2(:,xCol) = locs_Ch2(:,xCol)-locs_Ch2(:,deltaXCol); % substract deltaX from X Col
locs_Ch2(:,yCol) = locs_Ch2(:,yCol)-locs_Ch2(:,deltaYCol); % substract deltaY from Y Col


subplot(2,3,3)
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,2)-Avg_Ch2_new(:,4),1,'b'), hold on;
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on
title('X trajectory after correction');

subplot(2,3,6)
scatter(Avg_Ch2_new(:,1),Avg_Ch2_new(:,3)-Avg_Ch2_new(:,5),1,'b'), hold on;
axis([0 max(Avg_Ch2_new(:,1)) -radius radius])
axis square; box on
title('Y trajectory after correction');

%% Calculate delta and subtract from locs
% 
% close all
% 
% minFrame = 2000;
% 
% % Correct the Fiducial Curves
% 
% splineRes(:,1) = xData;
% splineRes(:,2) = csaps(AvgCurve(:,1),AvgCurve(:,2),p/100, splineRes(:,1));
% 
% 
% Avg_Ch1_new(:,4) = polyval(fit_Ch1x,Avg_Ch1(:,frameCol));
% Avg_Ch1_new(:,5) = polyval(fit_Ch1y,Avg_Ch1(:,frameCol));
% 
% % Calculate delta for locs
% 
% deltaX = zeros(length(locs_Ch1),1);
% deltaX = zeros(length(locs_Ch1),1);
% 
% vx = find(locs_Ch1(:,frameCol)>minFrame);
% 
% deltaX(vx,1)       = polyval(fit_Ch1x,locs_Ch1(vx,frameCol));
% deltaY(vx,1)       = polyval(fit_Ch1y,locs_Ch1(vx,frameCol));
% 
% locs_Ch1(:,deltaXCol) = deltaX;
% locs_Ch1(:,deltaYCol) = deltaY;
% 
% locs_Ch1(:,xCol) = locs_Ch1(:,xCol)-deltaX;
% locs_Ch1(:,yCol) = locs_Ch1(:,yCol)-deltaY;
% 
% subplot(2,1,1)
% scatter(Avg_Ch1(:,3),Avg_Ch1(:,1)-Avg_Ch1(:,4),1,'g'); hold on;
% title 
% subplot(2,1,2)
% scatter(Avg_Ch1(:,3),Avg_Ch1(:,2)-Avg_Ch1(:,5),1,'g'); hold on;


%% Polynomial for each fiducial
% 
% Avg_Ch1x = []; Avg_Ch1y = []; selectedFid = [];
% 
% for i = 1:max(Fid_Ch1(:,end)); % For all fiducials
% 
% selectedFid = [];    
% selectedFid(:,1) = Fid_Ch1(Fid_Ch1(:,9)==i,xCol)-mean(Fid_Ch1(Fid_Ch1(:,9)==i,xCol));
% selectedFid(:,2) = Fid_Ch1(Fid_Ch1(:,9)==i,yCol)-mean(Fid_Ch1(Fid_Ch1(:,9)==i,yCol));
% selectedFid(:,3) = Fid_Ch1(Fid_Ch1(:,9)==i,frameCol);
% 
% filter = 500;
% 
% vx = find(selectedFid(:,1)<filter & selectedFid(:,1)> -filter);
% vy = find(selectedFid(:,2)<filter & selectedFid(:,2)> -filter);
% 
% factor = 10;
% 
% fit_Ch1x = polyfit(selectedFid(vx,3),selectedFid(vx,1),factor);
% fit_Ch1y = polyfit(selectedFid(vy,3),selectedFid(vy,2),factor);
% 
% Fid_Ch1(:,5) = polyval(fit_Ch1x,Fid_Ch1(:,3));
% Fid_Ch1(:,6) = polyval(fit_Ch1y,Fid_Ch1(:,3));   
% 
% Avg_Ch1x(:,i) = polyval(fit_Ch1x,locs_Ch1(:,3));
% Avg_Ch1y(:,i) = polyval(fit_Ch1y,locs_Ch1(:,3));
% 
% end
% 
% % Average the fiducial tracks
% 
% Avg_Ch1(:,1) = mean(Avg_Ch1x,2);
% Avg_Ch1(:,2) = mean(Avg_Ch1y,2);

%% Polynomial of overlay

% close all
% 
% filter = 500; factor = 15;
% 
% vx = find(Avg_Ch1(:,1)<filter & Avg_Ch1(:,1)> -filter);
% vy = find(Avg_Ch1(:,2)<filter & Avg_Ch1(:,2)> -filter);
% 
% fit_Ch1x = polyfit(Avg_Ch1(vx,3),Avg_Ch1(vx,1),factor);
% fit_Ch1y = polyfit(Avg_Ch1(vy,3),Avg_Ch1(vy,2),factor);
% 
% subplot(2,1,1)
% scatter(Avg_Ch1(vx,3),Avg_Ch1(vx,1),1,'k'); hold on;
% scatter(Avg_Ch1(vx,3),polyval(fit_Ch1x,Avg_Ch1(vx,3)),5,'r');
% subplot(2,1,2)
% scatter(Avg_Ch1(vy,3),Avg_Ch1(vy,2),1,'k'); hold on;
% scatter(Avg_Ch1(vy,3),polyval(fit_Ch1y,Avg_Ch1(vy,3)),5,'r');

%%  Substract Avg from Fid and Locs

% close all
% 
% minFrame = 2000;
% 
% % Correct the Fiducial Curves
% 
% Avg_Ch1(:,4) = polyval(fit_Ch1x,Avg_Ch1(:,frameCol));
% Avg_Ch1(:,5) = polyval(fit_Ch1y,Avg_Ch1(:,frameCol));
% 
% % Calculate delta for locs
% 
% deltaX = zeros(length(locs_Ch1),1);
% deltaX = zeros(length(locs_Ch1),1);
% 
% vx = find(locs_Ch1(:,frameCol)>minFrame);
% 
% deltaX(vx,1)       = polyval(fit_Ch1x,locs_Ch1(vx,frameCol));
% deltaY(vx,1)       = polyval(fit_Ch1y,locs_Ch1(vx,frameCol));
% 
% locs_Ch1(:,deltaXCol) = deltaX;
% locs_Ch1(:,deltaYCol) = deltaY;
% 
% locs_Ch1(:,xCol) = locs_Ch1(:,xCol)-deltaX;
% locs_Ch1(:,yCol) = locs_Ch1(:,yCol)-deltaY;
% 
% subplot(2,1,1)
% scatter(Avg_Ch1(:,3),Avg_Ch1(:,1)-Avg_Ch1(:,4),1,'g'); hold on;
% title 
% subplot(2,1,2)
% scatter(Avg_Ch1(:,3),Avg_Ch1(:,2)-Avg_Ch1(:,5),1,'g'); hold on;

%% Save DC files

NameCorrected = [nameC1 '_DC.csv'];

fileID = fopen(NameCorrected,'w');
fprintf(fileID,[[line,',dx [nm],dy [nm]'] ' \n']);
dlmwrite(NameCorrected,locs_Ch1,'-append');
fclose('all');

fprintf('\n -- Saved Ch1 --\n');

NameCorrected = [nameC2 '_DC.csv'];

fileID = fopen(NameCorrected,'w');
fprintf(fileID,[[line,',dx [nm],dy [nm]'] ' \n']);
dlmwrite(NameCorrected,locs_Ch2,'-append');
fclose('all');

fprintf('\n -- Saved Ch2 --\n');


%% Find CoM of Fiducials and substract from Ch2

close all;

center_Ch1 = [];center_Ch2 = [];

RegionID = 9;


for i = selectedFid;
    
    center_Ch1(i+1,1) = median(Fid_Ch1(Fid_Ch1(:,RegionID)==i,xCol));
    center_Ch1(i+1,2) = median(Fid_Ch1(Fid_Ch1(:,RegionID)==i,yCol));
    
end

for i = selectedFid;;
    
    center_Ch2(i+1,1) = median(Fid_Ch2(Fid_Ch2(:,RegionID)==i,xCol));
    center_Ch2(i+1,2) = median(Fid_Ch2(Fid_Ch2(:,RegionID)==i,yCol));
    
end


% Delete NaNs

center_Ch1_noNan = [];
center_Ch2_noNan = [];

for i = 1:size(center_Ch1,1);
    
    if isnan(center_Ch1(i,1))==1;
        
    else
    center_Ch1_noNan(i,1) = center_Ch1(i,1);
    center_Ch1_noNan(i,2) = center_Ch1(i,2);

    end
    
end

center_Ch1 = [];
center_Ch1(:,1) = nonzeros(center_Ch1_noNan(:,1));
center_Ch1(:,2) = nonzeros(center_Ch1_noNan(:,2));


for i = 1:size(center_Ch2,1);
    
    if isnan(center_Ch2(i,1))==1;
        
    else
    center_Ch2_noNan(i,1) = center_Ch2(i,1);
    center_Ch2_noNan(i,2) = center_Ch2(i,2);

    end
    
end

center_Ch2 = [];
center_Ch2(:,1) = nonzeros(center_Ch2_noNan(:,1));
center_Ch2(:,2) = nonzeros(center_Ch2_noNan(:,2));

figure('Position',[200 200 300 300])
scatter(Fid_Ch1(:,xCol),Fid_Ch1(:,yCol),10,'g','filled');hold on;
scatter(Fid_Ch2(:,xCol),Fid_Ch2(:,yCol),10,'r','filled');
scatter(center_Ch1(:,1),center_Ch1(:,2),20,'bo');hold on;
scatter(center_Ch2(:,1),center_Ch2(:,2),20,'bx');hold on;
box on; axis equal;
title('Indentified Fiducial Centers');

fprintf('\n -- CoM identified --\n')

%% Extract and Save linear Transformation

deltaXY = [];

for i = 1:size(center_Ch1,1);
    
    deltaXY(i,1) = center_Ch1(i,1) - center_Ch2(i,1);
    deltaXY(i,2) = center_Ch1(i,2) - center_Ch2(i,2);
    
end

center_Ch2_corr = [];
center_Ch2_corr(:,1) = center_Ch2(:,1) + mean(deltaXY(:,1));
center_Ch2_corr(:,2) = center_Ch2(:,2) + mean(deltaXY(:,2));

TRE = [];

for i = 1:size(center_Ch1,1);
    
TRE(:,i) = sqrt((center_Ch1(i,1)-center_Ch2_corr(i,1))^2 + (center_Ch1(i,2)-center_Ch2_corr(i,2))^2);

end

figure
scatter(center_Ch1(:,1),center_Ch1(:,2),10,'g','filled');hold on;
scatter(center_Ch2(:,1) + mean(deltaXY(:,1)),center_Ch2(:,2) + mean(deltaXY(:,2)),10,'r','filled');  
box on; axis equal;
title(['Fid After 2nd trans TRE = ', num2str(mean(TRE))]);

fprintf('\n -- Linear Transformation extracted and saved --\n')

%% Apply Linear Translation and Save Data again

locs_Ch2(:,xCol) = locs_Ch2(:,xCol) + mean(deltaXY(:,1));
locs_Ch2(:,yCol) = locs_Ch2(:,yCol) + mean(deltaXY(:,2));

NameCorrected = [nameC2 '_DC_corrected.csv'];

fileID = fopen(NameCorrected,'w');
fprintf(fileID,[[line,',dx [nm],dy [nm]'] ' \n']);
dlmwrite(NameCorrected,locs_Ch2,'-append');
fclose('all');

fprintf('\n -- Saved Ch2 --\n');


