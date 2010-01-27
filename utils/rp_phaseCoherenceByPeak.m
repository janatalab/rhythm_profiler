function outData = rp_phaseCoherenceByPeak(inData)
% Calculates coherence among vectors close to important angles (0,pi,pi/2,pi/3,pi,4) etc.
% 
% outData = rp_phaseCoherence(inData,params)
% 
% INPUTS:
% inData: a rhythm profile struct
%            
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 04/30/2009


rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);
params = rp.params.rp;

onsetTimesSampsByBand = rp.onsetInfo.onsetTimesSampsByBand;
onsetExpectByBand = rp.complexExpectAtOnsets;

resonFreqs = rp.resonatorFreqs;
Fs = rp.Fs;

MMP = rp.meanResonatorEnergy;
MMPPeaks = rp.peakInfo.peakFreq;
MMPPeriods = 1./MMPPeaks;

nBands = size(rp.resonatorOut,1);

refVec = complex(1,0);

peakPhaseTolerances = pi/6;

nTimeSamps = size(rp.resonatorBandEnergy,3);
if(~isempty(params.timeLimSecs))
  timeStartSamps = round(params.timeLimSecs(1) * params.Fs) + 1;
  timeStopSamps = min(round(params.timeLimSecs(2) * params.Fs),nTimeSamps);
else
  timeStartSamps = 1;
  timeStopSamps = size(rp.resonatorOut,3);
end

for iBand = 1:nBands
  
  %recalculate MPP over specified time limit
  MPPThisBand = mean(squeeze(rp.resonatorBandEnergy(iBand,:,timeStartSamps:timeStopSamps)),2);
  fpParams = params.resonatorBank.peakFinder;
  peakIdxs = find_peaks(MPPThisBand,fpParams);
  peakHeights = peak_heights('signal',MPPThisBand,'peakIdxs',peakIdxs);
  if(isfield(fpParams,'minPeakHeight'))
    goodPeakMask = peakHeights >= fpParams.minPeakHeight;
    peakIdxs = peakIdxs(goodPeakMask);
    peakHeights = peakHeights(goodPeakMask);
  end

  peakFreqsPerBand{iBand} = resonFreqs(peakIdxs);
  nPeaks = length(peakIdxs);
  
  onsetTimesThisBand = onsetTimesSampsByBand{iBand};
  nOnsets = length(onsetTimesThisBand);
  onsetExpectThisBand = onsetExpectByBand{iBand};
  
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
  
  cohPerPeak{iBand} = [];
  keepPeaks = ones(nPeaks,1);
  for iPeak = 1:nPeaks    
    
    peakRefIdx = peakIdxs(iPeak);
    
    vecsThisPeak = squeeze(onsetExpectThisBand(peakRefIdx,find(mlAssign(iPeak,:))))';
    
    %we were throwing away first onset here, but this is now being done in 
    %rp_temporalExpectationError. The choice of whether or not to keep the 
    %first onset will need to be revisited. It is being thrown out now for
    %stims, since ANIs have been found with unusually high peaks.
    %vecsThisPeak(1) = [];
    
    %there have been a few instances where only the first onset was
    %assigned to a given peak. We are throwing these peaks out
    if(~isempty(vecsThisPeak))
      cohPerPeak{iBand}(end+1,1) = coherence(vecsThisPeak,refVec);
    else
      keepPeaks(iPeak) = 0;
      %peakHeights(iPeak) = [];
      %peakFreqsPerBand{iBand}(iPeak) = [];    
    end
    
  end %for iPeak
  
  peakHeights(~keepPeaks) = [];
  peakFreqsPerBand{iBand}(~keepPeaks) = [];
  peakHeightsPerBand{iBand,1} = peakHeights;
  
  
end %for iBand

cohStruct = ensemble_init_data_struct;
cohStruct.vars = {'peakFreqPerBand','cohPerPeakPerBand','peakHeightsPerBand'};
cohCols = set_var_col_const(cohStruct.vars);

cohStruct.data{cohCols.peakFreqPerBand} = peakFreqsPerBand;
cohStruct.data{cohCols.cohPerPeakPerBand} = cohPerPeak;
cohStruct.data{cohCols.peakHeightsPerBand} = peakHeightsPerBand;

outData = cohStruct;

