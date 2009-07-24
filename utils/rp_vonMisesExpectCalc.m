function outData = rp_vonMisesExpectCalc(varargin)
% Calculates an expectation error based on von Mises distributions across metric levels
% 
% outData = rp_vonMisesExpectCalc(inData,params)
% 
% INPUTS (tag/value pairs):
%         rp - a rhythm profiler struct
%   inputSig - the input signal to the resonator model (denv, sumDenv, or any
%              other signal)
%     params - the parameter structure of the rp
%              params.vmExpect.distResolution: The bin size of the
%                 von Mises distribution
%
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 04/23/2009

for iarg = 1:2:nargin
  switch varargin{iarg}
   case 'rp'
    rp = varargin{iarg+1};
   case 'inputSig'
    inputSig = varargin{iarg+1};
   case 'params'
    params = varargin{iarg+1};
  end
end

try
  params.vmExpect.distResolution = 50;
catch
  warning('von Mises distribution resolution not set. Setting to 50.');
  params.vmExpect.distResolution = 50;
end

distResolution = params.vmExpect.distResolution;
angleDistVector = [-pi:pi/distResolution:pi];
angleZeroIdx = find(angleDistVector == 0);

if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

expectErrorStruct = rp.expectationError;

peakFinderParams =  params.resonatorBank.peakFinder;
resonFreqs = rp.resonatorFreqs;
nResons = length(resonFreqs);
nBands = length(expectErrorStruct.onsetTimesSampsByBand);

for iBand = 1:nBands

  %we should probably be sending onsetExpectMtx as a cell array of
  %matrices instead of a big 3D matrix. This is why we need to
  %match actual onset times for this band to the 3D matrix.
  onsetTimesThisBand = expectErrorStruct.onsetTimesSampsByBand{iBand};

  if(length(onsetTimesThisBand) <=1)
    vmPredictionPerOnset{iBand} = [];
    vmViolationPerOnset{iBand} = [];
    vmAreaPerPeakList{iBand} = [];
    vmProportionsPerPeakList{iBand} = [];
    vmPeakFreqs{iBand} = [];
    vmK{iBand} = [];
    vmTimingDev{iBand} = [];
    vmDistPerPeakPerOnset = [];
    continue;
  end
    
  %were going to throw out the first onset because of spikes found
  %at the beginning of denv. This is going to have to be revisited at an earlier
  %processing stage (maybe even ANI)
  onsetTimesThisBand(1) = [];
  
  nOnsets = length(onsetTimesThisBand);
  
  %obtain the denv magnitudes at onset times
  denvAtOnsets = squeeze(inputSig(iBand,onsetTimesThisBand));
  denvThisBand = inputSig(iBand,:);

  
  %getting band peak info. This should have really been done from
  %rhythm_profiler
  mppThisBand = mean(squeeze(rp.resonatorBandEnergy(iBand,:,:)),2);
  bandPeakInfo = get_resonPeakInfo(mppThisBand,resonFreqs,peakFinderParams);
  
  
  bandPeakFreqs = bandPeakInfo.peakFreq;
  bandPeakIdxs = find(ismember(resonFreqs,bandPeakInfo.peakFreq));
  
  lowestResonPeriodSecs = 1./resonFreqs(bandPeakIdxs(1));
  lowestResonPeriodSamps = lowestResonPeriodSecs .* rp.Fs;
  denvEnergy = [];
  rEnergy = [];
   
  %calculating denvEnergy across time window range of
  %onsets. We should probably do this from the beginning, but we're
  %avoiding the spike mentioned above
  %timeLimVec = onsetTimesThisBand(1):onsetTimesThisBand(end);
  denvEnergy = sqrt(mean(denvThisBand.^2));

  adjDenvAtOnsets = denvAtOnsets ./ denvEnergy;
    
  for iOnset = 1:nOnsets
    
    thisComplexResonOut = expectErrorStruct.onsetExpectByBand{iBand}(:,iOnset);
    thisComplexResonMags = abs(thisComplexResonOut);
    thisComplexResonPhases = angle(thisComplexResonOut);
    
    peakFreqs = bandPeakInfo.peakFreq;
    peakWidths = bandPeakInfo.baseWidths/4;
    peakIdxs = bandPeakInfo.peakIdxs;
    peakHeights = bandPeakInfo.normHeight;
    peakPhases = angle(thisComplexResonOut(peakIdxs))';
    nPeaks = length(peakIdxs);

    clear variance vmDistThisPeak vmAreaPerPeak vmProbPerPeak vmAdjProbPerPeak vmAdjProbPerPeakTest metricLevel pwProportion;
    k = [];
    timingDev = [];
    for iPeak = 1:nPeaks
	
      pwProportion(iPeak) = peakWidths(iPeak)./ peakFreqs(iPeak)./peakHeights(iPeak);
      variance(iPeak) = pwProportion(iPeak);

      k(iPeak)  = 1./(variance(iPeak));
      vmDistThisPeak =  von_mises_pdf(angleDistVector,0,k(iPeak));
      diffAngle = peakPhases(iPeak) - angleDistVector;
      evalAngleIdx = find(abs(diffAngle) == min(abs(diffAngle)));
      
      weight = thisComplexResonMags(peakIdxs(iPeak))./nPeaks;
      vmProbPerPeak(iPeak) = vmDistThisPeak(evalAngleIdx).*weight;

      %find the indices to evaluate for the area of the von mises
      %dist (timing dev calc)
      if(angleZeroIdx >= evalAngleIdx)
	areaIdxs = evalAngleIdx:angleZeroIdx;
      else
	areaIdxs = angleZeroIdx:evalAngleIdx;
      end
      
      vmAreaPerPeak(iPeak) = sum(vmDistThisPeak(areaIdxs).*...
				 weight.*(pi/distResolution));
    
      vmDistPerPeak(iPeak,:) = vmDistThisPeak;
    end %for iPeak
    
    vmPredictionPerOnset{iBand}(iOnset) = sum(vmProbPerPeak);
    vmViolationPerOnset{iBand}(iOnset) = abs(adjDenvAtOnsets(iOnset) - sum(vmProbPerPeak));
    vmAreaPerPeakList{iBand,iOnset} = vmAreaPerPeak;
    vmProportionsPerPeakList{iBand,iOnset} = variance;
    vmK{iBand,iOnset} = k;
    vmTimingDev{iBand}(iOnset) = sum(vmAreaPerPeak);
    vmDistPerPeakPerOnset{iOnset} = vmDistPerPeak;
    
  end %for iOnset 
  
  vmPeakFreqs{iBand} = peakFreqs;
  
  
end % for iBand

expectationData = ensemble_init_data_struct;
expectationData.vars{end+1} = 'vmAngles';
expectationData.vars{end+1} = 'vmPeakFreqs';
expectationData.vars{end+1} = 'vmPredictionPerOnset';
expectationData.vars{end+1} = 'vmAreaPerPeak';
expectationData.vars{end+1} = 'vmViolationPerOnset';
expectationData.vars{end+1} = 'vmTimingDev';
expectationData.vars{end+1} = 'vmK';
expectationData.vars{end+1} = 'proportions';
expectationData.vars{end+1} = 'vmDistPerOnset';
expectationData.vars{end+1} = 'vmAngles';
expDataCols = set_var_col_const(expectationData.vars);
expectationData.data{expDataCols.vmAngles} = angleDistVector';
expectationData.data{expDataCols.vmPeakFreqs} = vmPeakFreqs;
expectationData.data{expDataCols.vmPredictionPerOnset} = vmPredictionPerOnset;
expectationData.data{expDataCols.vmViolationPerOnset} = vmViolationPerOnset;
expectationData.data{expDataCols.vmAreaPerPeak} = vmAreaPerPeakList;
expectationData.data{expDataCols.proportions} = vmProportionsPerPeakList;
expectationData.data{expDataCols.vmTimingDev} = vmTimingDev;
expectationData.data{expDataCols.vmDistPerOnset} = vmDistPerPeakPerOnset;
expectationData.data{expDataCols.vmK} = vmK;
expectationData.data{expDataCols.vmAngles} = angleDistVector;
outData = expectationData;

