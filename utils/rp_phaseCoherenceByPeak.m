function outData = rp_phaseCoherenceByPeak(inData,params)
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

%hard coding params here. If this becomes a useful function, params
%can be abstracted out


TEST_ANGLES = 0;

params.metricLevelToleranceMs = 100;

%probably shouldn't have time limit here, but this is necessary for
%now
%timeLimSec = [0 20];

mlToleranceSec = params.metricLevelToleranceMs./1000;

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

expectErrorStruct = rp.expectationError;
onsetExpectMtx = expectErrorStruct.onsetExpectMtx;
onsetTimesSamps = expectErrorStruct.onsetTimesSamps;
inputHeightList = expectErrorStruct.onsetHeightByBank{1};
resonFreqs = rp.resonatorFreqs;
Fs = rp.Fs;

MMP = rp.meanResonatorEnergy;
MMPPeaks = rp.peakInfo.peakFreq;
MMPPeriods = 1./MMPPeaks;

nOnsets = size(onsetExpectMtx,3);
nPeaks = length(MMPPeaks);
nBands = size(rp.resonatorOut,1);

refVec = complex(1,0);

peakPhaseTolerances = pi/6;

for iBand = 1:nBands
  
  %NEED TO GET PEAKS FOR EACH BAND.

  %MMPThisBand = mean(squeeze(rp.resonatorBandEnergy(iBand,:,:)),2);
  %fpParams = params.ipem.rp.resonatorBank.peakFinder;
  %peakIdxs = find_peaks(MMPThisBand,fpParams);
  %peakHeights = peak_heights('signal',meanEnergy,'peakIdxs',peakIdxs);
  %if(isfield(fpParams,'minPeakHeight'))
  %  goodPeakMask = peakHeights >= fpParams.minPeakHeight;
  %  peakIdxs = peakIdxs(goodPeakMask,1);
  %  peakHeights = peakHeights(goodPeakMask);
  %end

  [dummy,peakIdxs] = ismember(MMPPeaks,resonFreqs);
  
  for iOnset = 1:nOnsets
  
    peakPhases = angle(onsetExpectMtx(iBand,peakIdxs,iOnset));

    %assigning onset to metric levels
    %if there aren't any metric levels within tolerance, assign the
    %ml with the smallest phase angle
    mlMask = abs(peakPhases) <= peakPhaseTolerances;
    if(~any(mlMask))
      mlMask = (abs(peakPhases) == min(abs(peakPhases)));
    end
    
    mlAssign(1:nPeaks,iOnset) = mlMask;
    
  end
  
  for iPeak = 1:nPeaks    
    
    peakRefIdx = peakIdxs(iPeak);
    
    vecsThisPeak = squeeze(onsetExpectMtx(iBand,peakRefIdx,mlAssign(iPeak,:)))';
    %get rid of the first onset since there really should be on
    %expectation here
    vecsThisPeak(1) = [];
    
    cohPerPeak(iPeak,1) = coherence(vecsThisPeak,refVec);
    
  end
  
end

cohStruct = ensemble_init_data_struct;
cohStruct.vars = {'peakFreqPerBand','cohPerPeakPerBand'};
cohCols = set_var_col_const(cohStruct.vars);

cohStruct.data{cohCols.peakFreqPerBand} = {MMPPeaks};
cohStruct.data{cohCols.cohPerPeakPerBand} = {cohPerPeak};

inData.vars = {inData.vars{:} 'coherence'};
inDataCols = set_var_col_const(inData.vars);
inData.data{inDataCols.coherence} = cohStruct;
outData = inData;

