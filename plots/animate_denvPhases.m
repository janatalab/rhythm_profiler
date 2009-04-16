function outData = animate_rhythmPhaseAngles(inData,params)
%
% quick animation of expectancy phase angles. This might turn into
% a more fleshed out function
%
% S.T. 4/1/09

params.frameRate = 30;
params.frameDir = '/data2/groove/rmgc/animations/fh1_onsets';
params.useReson = 'summed';

useReson = params.useReson;
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

summedExpectationData = squeeze(sum(onsetExpectMtx,2));

summedResonatorBandEnergy = sum(rp.resonatorBandEnergy,3);
maxValPerBand =  max(summedResonatorBandEnergy,[],2);
[bankIdx,maxFiltPerBand] = find(summedResonatorBandEnergy == repmat(maxValPerBand,1,nResons));

maxFiltPerBand(bankIdx) = maxFiltPerBand;


figure(1);
set(1,'position',[100 100 768 576]); %[100 100 1400 1050]);
set(gcf,'inverthardcopy','off');

nSamps = size(rp.sumDenv,2);
timeVector = [0:1:nSamps-1]/Fs;

for iFrame = 1:nFrames

  frameStartTime = iFrame/frameRate;
  frameEndTime = (iFrame+1)/frameRate;
  
  frameNeedleSec = (frameEndTime-frameStartTime)/2 + frameStartTime;

  for iBank = 1:nBanks

    
    switch(useReson)
      
     case 'maxFilt'
      maxFilt = maxFiltPerBand(iBank);
      onsetIdxs = find(onsetExpectMtx(iBank,maxFilt,:)  ~= 0);
      onsetAngles = squeeze(angle(onsetExpectMtx(iBank,maxFilt,onsetIdxs)));
      onsetMags = squeeze(abs(onsetExpectMtx(iBank,maxFilt,onsetIdxs)));
      
     case 'summed'
      onsetIdxs = find(summedExpectationData(iBank,:) ~= 0);
      onsetAngles = angle(summedExpectationData(iBank,onsetIdxs));
      onsetMags = abs(summedExpectationData(iBank,onsetIdxs));
    end

    %compassBottom = 0.8026 - (.8026 - .1119)/4*(iBank-1);
    %axes('position',[0.01 compassBottom .1 .1]);
    %axis square;
    %thisOnsetIdx = find( (onsetTimesSamps(onsetIdxs) >= frameStartTime) & ...
    %			      (onsetTimesSamps(onsetIdxs) < frameEndTime),1,'last');
    %    compass(onsetExpectMtx(iBank,maxFilt,onsetIdxs(thisOnsetIdx)));

    %    camroll(90);
    
    subplot(nBanks,2,iBank*2-1);
 
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
   
    onsetTimesPlot = onsetTimesSamps(onsetIdxs)/Fs;

    errorMargin = 1/10*pi;
    
    zeroOnsets = find(abs(onsetAngles) < errorMargin);
    deg90Onsets = find(abs(onsetAngles - pi/2) < errorMargin);
    deg180Onsets = find(abs(onsetAngles - pi) < errorMargin);
    deg270Onsets = find(abs(onsetAngles - pi*3/2) < errorMargin);
    
    deg0H = plot(onsetTimesPlot(zeroOnsets),repmat(.6,size(onsetTimesPlot(zeroOnsets))),'*r');
    deg90H = plot(onsetTimesPlot(deg90Onsets),repmat(.6,size(onsetTimesPlot(deg90Onsets))),'*c');   
    deg180H = plot(onsetTimesPlot(deg180Onsets),repmat(.6,size(onsetTimesPlot(deg180Onsets))),'*m');
    deg270H = plot(onsetTimesPlot(deg270Onsets),repmat(.6,size(onsetTimesPlot(deg270Onsets))),'*g');    
 
    %legend
    if(iBank == nBanks)
      legend([deg0H deg90H deg180H deg270H],{'0 deg','90 deg','180 deg','270 deg'},...
	     'location',[0.01 0.01 .33 .05],'orientation','horizontal');
      legend boxoff;
    end
    
    
    %right subplots
    subplot(nBanks,2,iBank*2);
    hold off;
    bar(onsetTimesPlot,onsetMags',1,'w');
    
    ylim(1) = 0;
    
    switch(useReson)
     case 'maxfilt'
      ylim(2) = max(max(max(abs(onsetExpectMtx(:,maxFiltPerBand,:)))));
     case 'summed'
      ylim(2) = max(abs(summedExpectationData(:)));
    end
    
    set(gca,'xlim',xlim);
    set(gca,'ylim',ylim);
    hold on;
    plot([frameNeedleSec frameNeedleSec],ylim,'y');
    set(gca,'color',[0 0 0]);  
   
  end
  

  
  fname = fullfile(params.frameDir,sprintf('frame%0.4d',iFrame));
  print(fname,'-djpeg','-cmyk');
  
  
  
end

outData = [];
