% adapted from rp_phaseCoherenceByPeak for the SMPC 09 talk
%illustrates the coherence calculation on RPs. 
% 
% % Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 07/28/2009

close all

%change mat file here to load data from a different trial
dataPath = '/data2/rhythm/rhythmic_tapping_v2/project_data/resp_rp2';
loadData = load(fullfile(dataPath,'03daj88201_2774_trial_9.mat'));


plotBand = 1;
setXLimSecs = [10 14];
Fs = 100;
setXLims = setXLimSecs.*Fs;
setYLims = [-2 2];
timeTicks = setXLims(1):Fs:setXLims(2);
timeTickLabels = sprintf('%d|',timeTicks./Fs);


params.metricLevelToleranceMs = 100;
mlToleranceSec = params.metricLevelToleranceMs./1000;


tCols = set_var_col_const(loadData.thisTrialStruct.vars);
rp_ensemble_struct = loadData.thisTrialStruct.data{tCols.rp}{1};

rp = ensemble_datastruct2tree(rp_ensemble_struct);

expectErrorStruct = rp.expectationError;
onsetTimesSampsByBand = expectErrorStruct.onsetTimesSampsByBand;
onsetExpectByBand = expectErrorStruct.onsetExpectByBand;
onsetHeightByBand = expectErrorStruct.onsetHeightByBand;

resonFreqs = rp.resonatorFreqs;



MPP = rp.meanResonatorEnergy;
MPPPeaks = rp.peakInfo.peakFreq;
MPPPeriods = 1./MPPPeaks;

nBands = size(rp.resonatorOut,1);

refVec = complex(1,0);

peakPhaseTolerances = pi/6;

MPPThisBand = mean(squeeze(rp.resonatorBandEnergy(plotBand,:,:)),2);
resonOutThisBand = squeeze(rp.resonatorOut(plotBand,:,:));

bandPeakInfo = rp.peakInfo.bandPeakInfo{plotBand};
peakIdxs = bandPeakInfo.peakIdxs;
peakHeights = bandPeakInfo.peakHeight;
peakFreqsPerBand{plotBand} = resonFreqs(peakIdxs);
nPeaks = length(peakIdxs);
  
onsetTimesThisBand = onsetTimesSampsByBand{plotBand};
nOnsets = length(onsetTimesThisBand);
onsetExpectThisBand = onsetExpectByBand{plotBand};

audCols = set_var_col_const(loadData.thisTrialStruct.data{tCols.resp_aud}{1}.vars);
inputThisBand = loadData.thisTrialStruct.data{tCols.resp_aud}{1}.data{audCols.wvf};



mlMask = [];
mlAssign = [];
for iOnset = 1:nOnsets
  peakPhases = angle(onsetExpectThisBand(peakIdxs,iOnset));
  
  %assigning onset to metric levels
  %if there aren't any metric levels within tolerance, assign the
  %ml with the smallest phase angle
  mlMask = abs(peakPhases) <= peakPhaseTolerances;
  if(~any(mlMask))
    mlMask = (abs(peakPhases) == min(abs(peakPhases)));
  end
    
  mlAssign(1:nPeaks,iOnset) = mlMask;
  
end %for iOnset  
  
%PLOT THE MPP
figure;
set(gcf,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);
topAxH = axes('position',[0.1 0.6 0.65 0.34]);

params.plot.showResonTickLabels = 1;
params.plot.perform = {'plotPeaks'};
params.plot.color = 1;
params.plot.numResonTicks = 8;
plot_rpMeanResonEnergy(topAxH,rp_ensemble_struct,params.plot);
xlabel('Resonator Frequency (Hz)');
%rotateticklabel(topAxH);

ylabel('Amplitude');


%PLOT THE PEAK RESON TIME SERIES WITH ONSETS SUPERIMPOSED
for iPeak = 1:nPeaks
  
  bottomPos = 0.4 - (iPeak-1)*0.16;
  axes('position',[0.1 bottomPos 0.65 0.15]);
  plot(resonOutThisBand(peakIdxs(iPeak),:));
  hold on;
  
  onsetMask = mlAssign(iPeak,:);
  onsetSigThisPeak = zeros(size(inputThisBand));
  onsetTimesThisPeak = onsetTimesThisBand(logical(onsetMask'));
  
  onsetSigThisPeak(onsetTimesThisPeak) = inputThisBand(onsetTimesThisPeak);
  plot(onsetSigThisPeak,'r');

  
  
  if(iPeak == nPeaks)
    set(gca,'xtick',timeTicks,'xticklabels',timeTickLabels,'ytick',[],'xlim',setXLims,'ylim',setYLims); 
    xlabel('Time (s)');
    ylabel('Amplitude');
  else
    set(gca,'xtick',[],'ytick',[],'xlim',setXLims,'ylim',setYLims);
  end

  ylims = get(gca,'ylim');
  xlims = setXLims;
  resonLabel = sprintf('%.2f Hz',resonFreqs(peakIdxs(iPeak)));
  text(0.005*diff(xlims)+xlims(1),0.87*diff(ylims)+ylims(1),resonLabel);

end



figure;
set(gcf,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);

cohPerPeak{plotBand} = [];
keepPeaks = ones(nPeaks,1);
for iPeak = 1:nPeaks    
    
  peakRefIdx = peakIdxs(iPeak);
  
  vecsThisPeak = squeeze(onsetExpectThisBand(peakRefIdx,find(mlAssign(iPeak,:))))';
  %get rid of the first onset since there really should be no
  %expectation here
  vecsThisPeak(1) = [];
  
  %there have been a few instances where only the first onset was
  %assigned to a given peak. We are throwing these peaks out
  if(~isempty(vecsThisPeak))
    cohPerPeak{plotBand}(end+1,1) = coherence(vecsThisPeak,refVec);
  else
    keepPeaks(iPeak) = 0;
  end
    
  subplot(nPeaks,1,iPeak);
  
  %uncomment the following two lines to use a white vector to set
  %the max radius of the plot
  %compass(-1.5+0*i,'w');
  %hold on;
  
  compass(vecsThisPeak);
  %hold on;
  %compass(1,'r');
  
  camorbit(90,180);
  
  axPos = get(gca,'position');
  labelAxPos=[.2 axPos(2) .1 axPos(4)];
  labelAx = axes('position',labelAxPos,'visible','off');
  resonLabel = sprintf('%.2f Hz',resonFreqs(peakIdxs(iPeak)));
  text(0.5,0.5,resonLabel,'fontsize',12,'fontweight','bold');
  
end %for iPeak
  

