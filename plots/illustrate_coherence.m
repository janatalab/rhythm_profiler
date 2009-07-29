% adapted from rp_phaseCoherenceByPeak for illustrating the
% coherence calculation
% 
% outData = rp_phaseCoherence(inData,params)
% 
% INPUTS:
% inData: a rhythm profile struct
%            
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 07/28/2009


plotBand = 1;



params.metricLevelToleranceMs = 100;
mlToleranceSec = params.metricLevelToleranceMs./1000;


loadData = load('03daj88201_2774_trial_9.mat');

tCols = set_var_col_const(loadData.thisTrialStruct.vars);
rp_ensemble_struct = loadData.thisTrialStruct.data{tCols.rp}{1};

rp = ensemble_datastruct2tree(rp_ensemble_struct);

expectErrorStruct = rp.expectationError;
onsetTimesSampsByBand = expectErrorStruct.onsetTimesSampsByBand;
onsetExpectByBand = expectErrorStruct.onsetExpectByBand;
onsetHeightByBand = expectErrorStruct.onsetHeightByBand;

resonFreqs = rp.resonatorFreqs;
Fs = rp.Fs;

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
figParams.axLocs = {'rectPlot_top'};
[figH,axHList] = rp_figure(figParams);
topAxH = get_axhandle(axHList,'rectPlot_top');
params.plot.showResonTickLabels = 1;
params.plot.perform = {'plotPeaks'};
params.plot.color = 1;
params.plot.numResonTicks = 15;
plot_rpMeanResonEnergy(topAxH,rp_ensemble_struct,params.plot);
rotateticklabel(topAxH);



%PLOT THE PEAK RESON TIME SERIES WITH ONSETS SUPERIMPOSED
figure;
set(gcf,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);
for iPeak = 1:nPeaks
  subplot(nPeaks,1,iPeak);
  plot(resonOutThisBand(peakIdxs(iPeak),:));
  hold on;
  
  onsetMask = mlAssign(iPeak,:);
  onsetSigThisPeak = zeros(size(inputThisBand));
  onsetTimesThisPeak = onsetTimesThisBand(logical(onsetMask'));
  
  onsetSigThisPeak(onsetTimesThisPeak) = inputThisBand(onsetTimesThisPeak);
  plot(onsetSigThisPeak,'r');
  
end





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
    %peakHeights(iPeak) = [];
    %peakFreqsPerBand{iBand}(iPeak) = [];    
  end
    
end %for iPeak
  
peakHeights(~keepPeaks) = [];
peakFreqsPerBand{plotBand}(~keepPeaks) = [];
peakHeightsPerBand{plotBand,1} = peakHeights;

cohStruct = ensemble_init_data_struct;
cohStruct.vars = {'peakFreqPerBand','cohPerPeakPerBand','peakHeightsPerBand'};
cohCols = set_var_col_const(cohStruct.vars);

cohStruct.data{cohCols.peakFreqPerBand} = peakFreqsPerBand;
cohStruct.data{cohCols.cohPerPeakPerBand} = cohPerPeak;
cohStruct.data{cohCols.peakHeightsPerBand} = peakHeightsPerBand;

outData = cohStruct;

