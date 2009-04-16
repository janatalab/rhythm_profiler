function outData = animate_rhythmPhaseAngles(inData,params)
%
% quick animation of expectancy phase angles. This might turn into
% a more fleshed out function
%
% S.T. 4/1/09

params.frameRate = 30;
params.frameDir = '/data2/groove/rmgc/animations/fh1';
params.groupMode = 'mean';

groupMode = params.groupMode;

rp = inData{1};
rp = ensemble_datastruct2tree(rp);
Fs = rp.Fs;

expectationData = rp.expectationError;
onsetExpectMtx = expectationData.onsetExpectMtx;
onsetTimesSamps = expectationData.onsetTimesSamps;
onsetTimesSecs = onsetTimesSamps/Fs;


frameRate = params.frameRate;
nSamples = size(rp.resonatorOut,3);
nResons = size(rp.resonatorOut,2);
nBanks = size(rp.resonatorOut,1);

timeSeries = 1:nSamples;
nFrames = floor(nSamples/Fs*frameRate);

timeVector = [0:1:nSamples-1]/Fs;

hsvMap = hsv(64);
colorMap = zeros(nResons,3);
slowFreqIdxs = find(rp.resonatorFreqs < 0.6);
fastFreqIdxs = find(rp.resonatorFreqs > 4);
midFreqIdxs = setdiff([1:nResons],union(slowFreqIdxs,fastFreqIdxs));
colorMap(slowFreqIdxs,:) = repmat([.6 .6 .6],length(slowFreqIdxs),1);
colorMap(fastFreqIdxs,:) =  repmat([.3 .3 .3],length(fastFreqIdxs),1);
colorMap(midFreqIdxs,:) = hsvMap(end:-1:end-length(midFreqIdxs)+1,:);


%threshold onsetExpectMtx. 
onsetExpectMtx(abs(onsetExpectMtx) < 0.4) = 0;

%find the maximum radius to plot
maxRadius = max(abs(onsetExpectMtx(:)));

figure(1);
set(gcf,'inverthardcopy','off');
set(1,'position',[100 100 768 576]);
frameInfoH = axes('position',[.8 0 .2 .05]);
cmapLegendH = axes('position',[.05 0.97 0.9 .02]);
image(1:nResons,'parent',cmapLegendH);
colormap(cmapLegendH,colorMap);
resonTicks = 1:10:nResons;
resonTickLabels = sprintf('%.2f|',rp.resonatorFreqs(resonTicks));
set(cmapLegendH,'ytick',[],'xtick',resonTicks,'xticklabel',resonTickLabels);

%setting up for first frame and frames before any onsets
for iBank = 1:nBanks
  
  axesBottom = 0.45 - floor(iBank/4)*0.45;
  axH(iBank) = axes('position',[.33*(mod(iBank-1,3)) axesBottom .33 .5]);
  axis(axH(iBank),'square');
  compass(0);
 
  extentRadius = maxRadius;
 
  extentVectorH = compass(complex(extentRadius*cos(1/100*pi),extentRadius*sin(1/100*pi)),'w');
  set(extentVectorH,'visible','off');
  camroll(90);
  
  %set up the denv axes
  denvBottom = .5 - (iBank)*0.08;
  denvH(iBank) = axes('position',[0.66 denvBottom 0.33 0.06]);
  
end

sumVectors = zeros(5,1);
sumAllVector = 0;

for iFrame = 1:nFrames
  
  frameStartTime = iFrame/frameRate;
  frameEndTime = (iFrame+1)/frameRate;
  frameNeedleSec = (frameEndTime-frameStartTime)/2 + frameStartTime;

  onsetTimeIdxsThisFrame = find(onsetTimesSecs >= frameStartTime & onsetTimesSecs < frameEndTime);

  for iBank = 1:nBanks

    onsetExpectMtxNow = onsetExpectMtx(iBank,:,onsetTimeIdxsThisFrame);
    
    %if there isn't any data for this frame and bank, skip plotting
    if(~any(abs(onsetExpectMtxNow(:))))
      doPlot = false;
    else
      doPlot = true;
    end
    
    if(doPlot)      
      
      %Sum across time if applicable. This will be used to
      %indentify reson filters that have any energy in this frame
      if(size(onsetExpectMtxNow,3) > 1)
	onsetExpectMtxNowSum = sum(onsetExpectMtxNow,3);
	onsetExpectMtxNow = squeeze(onsetExpectMtxNow);
      else
	onsetExpectMtxNowSum = squeeze(onsetExpectMtxNow);
	onsetExpectMtxNow = squeeze(onsetExpectMtxNow)';
      end
      
      %obtain the reson indexes with any energy in them
      resonIdxs = find(abs(onsetExpectMtxNowSum));
      resonIdxSpacing = [1 diff(resonIdxs)];
      nLiveResons = length(resonIdxs);
      %iterate through all the resons and assign them group indices
      iGroup = 1;
      resonGroupID = [];
      for iReson = 1:nLiveResons
	if(resonIdxSpacing(iReson) > 1)
	  iGroup = iGroup + 1;
	end
	resonGroupID(iReson) = iGroup;
      end
      nGroups = iGroup;
      meanGroupIdxs = [];
      groupVectors = [];
      for iGroup = 1:nGroups
	idxsThisGroup = resonIdxs(find(resonGroupID == iGroup));
	vectorsThisGroup = onsetExpectMtxNow(idxsThisGroup,:);
	vectorsThisGroup = vectorsThisGroup(:);

	switch(groupMode)
	 case 'mean'
	   groupVectors(iGroup) = mean(vectorsThisGroup);
	   meanGroupIdxs(iGroup) = floor(mean(idxsThisGroup));
	 case 'max'
	   maxIdxThisGroup = find(abs(vectorsThisGroup) == max(abs(vectorsThisGroup)),1,'last');
	   groupVectors(iGroup) = vectorsThisGroup(maxIdxThisGroup);
	   %find the index of the reson that has the highest magnitude
	   [maxResonIdx,dummy] = find(abs(onsetExpectMtxNow) == abs(vectorsThisGroup(maxIdxThisGroup)));
	   meanGroupIdxs(iGroup) = maxResonIdx;
	end
      end
      
      figure(1);
      axes(axH(iBank));
      hold off;
      extentRadius = maxRadius;
      extentVectorH = compass(complex(extentRadius*cos(1/50*pi),extentRadius*sin(1/50*pi)),'w');
      set(extentVectorH,'visible','off');
      hold on;
      for iGroup = 1:nGroups
	colorSpec = colorMap(meanGroupIdxs(iGroup),:);
	vecH = compass(groupVectors(iGroup));
	set(vecH,'color',colorSpec,'linewidth',2);
      end
      xlim = get(gca,'xlim');
      ylim = get(gca,'ylim');
      text(xlim(1),ylim(2),sprintf('%d',iBank),'fontweight','bold');
      camroll(90);
    end

    %plot denv for each bank
    axes(denvH(iBank));
    hold off;
    plot(timeVector,rp.sumDenv(iBank,:),'w');
    
    if(frameNeedleSec < 1.5)
      xlim = [0 3];
    elseif((max(timeVector) - frameNeedleSec < 1.5))
      xlim = [(max(timeVector) - 3) max(timeVector)];
    else
      xlim(1) = frameNeedleSec - 1.5;
      xlim(2) = frameNeedleSec + 1.5;
    end
    
    ylim = [0 0.7];
    
    set(gca,'xlim',xlim);
    set(gca,'ylim',ylim);
    hold on;
    plot([frameNeedleSec frameNeedleSec],ylim,'y','linewidth',0.8);
    set(gca,'color',[0 0 0]);   
    set(gca,'xtick',[],'ytick',[]);
    
  end %for iBank


  
  
  
  
  
  axes(frameInfoH);
  cla;
  set(gca,'visible','off');
  text(0,.2,sprintf('Frame # %d',iFrame),'fontsize',8);
  text(.5,.2,sprintf('Time: %.2f',frameStartTime),'fontsize',8);
     
  fname = fullfile(params.frameDir,sprintf('frame%0.4d',iFrame));
  print(fname,'-djpeg');

end % for iFrame

outData = [];
