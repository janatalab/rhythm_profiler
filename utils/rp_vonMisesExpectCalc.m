function outData = rp_vonMisesExpectCalc(inData,params)
% Calculates an expectation error based on von Mises distributions across metric levels
% 
% outData = rp_vonMisesExpectCalc(inData,params)
% 
% INPUTS:
% inData: a rhythm profile struct
%            
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 04/23/2009

params.vmExpect.distResolution = 50;
params.vmExpect.metricLevelToleranceMs = 100;
params.timeLimSecs = [0 20];


metricLevelToleranceSec = params.vmExpect.metricLevelToleranceMs./1000;

distResolution = params.vmExpect.distResolution;
angleDistVector = [-pi:pi/distResolution:pi];
angleZeroIdx = find(angleDistVector == 0);

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

timeLimSamps = round((params.timeLimSecs).*rp.Fs)+1;
%timeLimVec = timeLimSamps(1):timeLimSamps(2);

expectErrorStruct = rp.expectationError;

onsetExpectMtx = expectErrorStruct.onsetExpectMtx;
onsetTimesSamps = expectErrorStruct.onsetTimesSamps;
onsetTimesByBand = expectErrorStruct.onsetTimesByBank;

peakFinderParams =  params.resonatorBank.peakFinder;
resonFreqs = rp.resonatorFreqs;
nResons = length(resonFreqs);
nBands = size(onsetExpectMtx,1);

for iBand = 1:nBands

  %we should probably be sending onsetExpectMtx as a cell array of
  %matrices instead of a big 3D matrix. This is why we need to
  %match actual onset times for this band to the 3D matrix.
  onsetTimesThisBand = onsetTimesByBand{iBand};
  
  %were going to throw out the first onset because of spikes found
  %at the beginning of denv. This is going to have to be revisited at an earlier
  %processing stage (maybe even ANI)
  onsetTimesThisBand(1) = [];
  
  [dummy,onsetIdxsThisBand] = ismember(onsetTimesThisBand,onsetTimesSamps);
  nOnsets = length(onsetIdxsThisBand);
  onsetExpectThisBand = squeeze(onsetExpectMtx(iBand,:,onsetIdxsThisBand));

  %obtain the denv magnitudes at onset times
  denvAtOnsets = squeeze(rp.sumDenv(iBand,onsetTimesThisBand));
  denvThisBand = rp.sumDenv(iBand,:);

  
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
  %calculate sliding energy for onsets and for reson
  %for iOnset = 1:nOnsets
  %  endIdx = iOnset;
  %  endTime = onsetTimesThisBand(endIdx);
  %  startIdx = max(1,endTime - lowestResonPeriodSamps + 1);
    %startLim = endTime - lowestResonPeriodSamps;
    %onsetIdxs = find((onsetTimesThisBand > startLim) &( onsetTimesThisBand < endTime));
  %  denvEnergy(iOnset) = sqrt(mean(denvThisBand(startIdx:endTime).^2));
    %denvEnergy(iOnset) = sqrt(mean(denvAtOnsets(onsetIdxs).^2));
  %end
   
  %calculating denvEnergy across time window range of
  %onsets. We should probably do this from the beginning, but we're
  %avoiding the spike mentioned above
  timeLimVec = onsetTimesThisBand(1):onsetTimesThisBand(end);
  denvEnergy = sqrt(mean(denvThisBand(timeLimVec).^2));
  
  adjDenvAtOnsets = denvAtOnsets ./ denvEnergy;
    
  for iOnset = 1:nOnsets
    
    thisComplexResonOut = onsetExpectThisBand(:,iOnset);
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
    vmPeakFreqsPerOnset{iBand,iOnset} = peakFreqs;
    vmK{iBand,iOnset} = k;
    vmTimingDev{iBand}(iOnset) = sum(vmAreaPerPeak);
    vmDistPerPeakPerOnset{iOnset} = vmDistPerPeak;
    
  end %for iOnset 
  
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
expectationData.data{expDataCols.vmPeakFreqs} = vmPeakFreqsPerOnset;
expectationData.data{expDataCols.vmPredictionPerOnset} = vmPredictionPerOnset;
expectationData.data{expDataCols.vmViolationPerOnset} = vmViolationPerOnset;
expectationData.data{expDataCols.vmAreaPerPeak} = vmAreaPerPeakList;
expectationData.data{expDataCols.proportions} = vmProportionsPerPeakList;
expectationData.data{expDataCols.vmTimingDev} = vmTimingDev;
expectationData.data{expDataCols.vmDistPerOnset} = vmDistPerPeakPerOnset;
expectationData.data{expDataCols.vmK} = vmK;
expectationData.data{expDataCols.vmAngles} = angleDistVector;
outData = expectationData;

