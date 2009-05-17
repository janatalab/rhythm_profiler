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

pwParams.runMode = 'width_half_height';

metricLevelToleranceSec = params.vmExpect.metricLevelToleranceMs./1000;

distResolution = params.vmExpect.distResolution;
angleDistVector = [-pi:pi/distResolution:pi];
angleZeroIdx = find(angleDistVector == 0);

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

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
  [dummy,onsetIdxsThisBand] = ismember(onsetTimesThisBand,onsetTimesSamps);
  nOnsets = length(onsetIdxsThisBand);
  onsetExpectThisBand = squeeze(onsetExpectMtx(iBand,:,onsetIdxsThisBand));

  %obtain the denv magnitudes at onset times
  denvAtOnsets = squeeze(rp.sumDenv(iBand,onsetTimesThisBand));
  denvThisBand = rp.sumDenv(iBand,:);

  bandPeakFreqs = rp.peakInfo.bandPeakInfo{iBand}.peakFreq;
  bandPeakIdxs = find(ismember(resonFreqs,rp.peakInfo.bandPeakInfo{1}.peakFreq));
  
  lowestResonPeriodSecs = 1./resonFreqs(bandPeakIdxs(1));
  lowestResonPeriodSamps = lowestResonPeriodSecs .* rp.Fs;
  denvEnergy = [];
  rEnergy = [];
  %calculate sliding energy for onsets and for reson
  for iOnset = 1:nOnsets
    endIdx = iOnset;
    endTime = onsetTimesThisBand(endIdx);
    startIdx = max(1,endTime - lowestResonPeriodSamps + 1);
    %startLim = endTime - lowestResonPeriodSamps;
    %onsetIdxs = find((onsetTimesThisBand > startLim) &( onsetTimesThisBand < endTime));
    denvEnergy(iOnset) = sqrt(mean(denvThisBand(startIdx:endTime).^2));
    %denvEnergy(iOnset) = sqrt(mean(denvAtOnsets(onsetIdxs).^2));
  end
    
  %set zero values to realmin in order to avoid division by zero
  %rEnergy(rEnergy == 0) = realmin;
  adjDenvAtOnsets = denvAtOnsets ./ denvEnergy;
    
  for iOnset = 1:nOnsets
    
    thisComplexResonOut = onsetExpectThisBand(:,iOnset);
    thisComplexResonMags = abs(thisComplexResonOut);
    thisComplexResonPhases = angle(thisComplexResonOut);
    
    %find the peak locations of the reson filter corresponding to this onset time
    %thresholding this might be a little tricky. Revisit this if we
    %are losing peaks (or have too many)
    peakIdxs = find_peaks(thisComplexResonMags,peakFinderParams)';
    peakHeights = peak_heights('signal',thisComplexResonMags,'peakIdxs',peakIdxs); 
    goodPeakMask = peakHeights >= peakFinderParams.minPeakHeight;
    peakIdxs = peakIdxs(goodPeakMask,1);
    peakHeights = peakHeights(goodPeakMask);
  
    %throwing out peaks detected at edges for now. These should
    %generally not be found except possibly at the beginning of
    %the signal
    if((~isempty(peakIdxs)) && (peakIdxs(1) == 1))
      peakIdxs(1) = [];
      peakHeights(1) = [];
    end
  
    if((~isempty(peakIdxs)) && (peakIdxs(end) == length(resonFreqs)))
      peakIdxs(end) = [];
      peakHeights(end) = [];
    end
        
    if(~isempty(peakIdxs))
      
  
      peakFreqs = resonFreqs(peakIdxs);
      peakWidths = peak_widths('signal',thisComplexResonMags,'peakIdxs',peakIdxs,'params',pwParams);
      peakPhases = angle(thisComplexResonOut(peakIdxs))';
      
      nPeaks = length(peakIdxs);
  
      clear vmDistThisPeak vmAreaPerPeak vmProbPerPeak vmAdjProbPerPeak vmAdjProbPerPeakTest metricLevel pwProportion;
      k = [];
      timingDev = [];
      for iPeak = 1:nPeaks
	
	borders = [peakWidths(iPeak*2-1) peakWidths(iPeak*2)];
	if(diff(borders) ~= 0)
	  pwProportion(iPeak) = abs(diff(resonFreqs(borders)))./ peakFreqs(iPeak)./peakHeights(iPeak);
	else
	  %taking care of super small peaks when reson sampling is sparse
	  borders = [(borders(1)-1) (borders(2)+1)];
	  pwProportion(iPeak) = abs(diff(resonFreqs(borders)))./ peakFreqs(iPeak)./peakHeights(iPeak);
	  %pwProportion(iPeak) = pwProportion(iPeak) ./2;
	end
	  
	%assuming that half of pwProportion is equivalent to variance
	variance = pwProportion(iPeak).*pi;
	%dispersion, k, is roughly equivalent to 1./variance 
	k(iPeak)  = 1./(variance);
	
	%vmDistThisPeak =  von_mises_pdf(angleDistVector,peakPhases(iPeak),k(iPeak));
	vmDistThisPeak =  von_mises_pdf(angleDistVector,0,k(iPeak));
	
	diffAngle = peakPhases(iPeak) - angleDistVector;
	evalAngleIdx = find(abs(diffAngle) == min(abs(diffAngle)));
	
	
	%weight = thisComplexResonMags(peakIdxs(iPeak))./nPeaks;
	weight = thisComplexResonMags(peakIdxs(iPeak));
	
	vmProbPerPeak(iPeak) = vmDistThisPeak(evalAngleIdx).*weight;
	
	
	if(angleZeroIdx >= evalAngleIdx)
	  areaIdxs = evalAngleIdx:angleZeroIdx;
	else
	  areaIdxs = angleZeroIdx:evalAngleIdx;
	end
	
	vmAreaPerPeak(iPeak) = sum(vmDistThisPeak(areaIdxs).*...
				   weight.*(pi/distResolution));
	
	%vmAdjProbPerPeak(iPeak) = vmDistThisPeak(angleDistVector == 0) ...
	%    .* thisAdjComplexResonMags(peakIdxs(iPeak));

	%constructing an overall distribution matrix
%{	
if(iPeak == 1)
	  clear metricLevel;
	  basePeriod = 1./resonFreqs(peakIdxs(1));
	  baseMetricLevel = vmDistThisPeak;
	  metricLevel(1,:) = baseMetricLevel .* ...
	      thisComplexResonMags(peakIdxs(1));
	  numSamps = size(metricLevel,2);
	else
	  thisPeriod = 1./peakFreqs(iPeak);
	  periodRatio = basePeriod/thisPeriod;
	  numPeriodsBegin = -periodRatio/2;
	  numPeriodsEnd = periodRatio/2;
	  angleBegin = numPeriodsBegin*2*pi;
	  angleEnd = numPeriodsEnd*2*pi;
	  evalDist = [angleBegin:pi/distResolution:angleEnd];
	  distThisPeak = von_mises_pdf(evalDist,peakPhases(iPeak),k(iPeak));
	  distThisPeak = (distThisPeak - min(distThisPeak)) ./ ...
	      (max(distThisPeak) - min(distThisPeak));
	  resampDist = angleBegin:(angleEnd-angleBegin)/(numSamps-1):angleEnd;
	  distThisPeakResamp = spline(evalDist,distThisPeak,resampDist);
	  metricLevel(iPeak,:) = distThisPeakResamp .* thisComplexResonMags(peakIdxs(iPeak));
      end
      %}
	
      end %for iPeak
    
    %find the timing devation from the closest peak. This is our
    %timing error
    %sumMetricDist = sum(metricLevel,1);
    %smdPeakIdxs = find_peaks(sumMetricDist,[]);
    %smdPeakHeights = peak_heights('signal',sumMetricDist,'peakIdxs',smdPeakIdxs);
    %smdPeakIdxs = smdPeakIdxs(smdPeakHeights >= 0.1);
    %smdBorder1 = find(angleDistVector == 0);
    %if we just happen to be smack in the middle of two peaks, take
    %the later one (negative dir)
    %smdBorder2 = ...
%	smdPeakIdxs(find(abs(angleDistVector(smdPeakIdxs)) == min(abs(angleDistVector(smdPeakIdxs))),1,'first'));
%    smdMin = min(smdBorder1,smdBorder2);
%    smdMax = max(smdBorder1,smdBorder2);
    %each slice is pi/distResolution wide
%    smdArea = sum(sumMetricDist(smdMin:smdMax).*(pi/distResolution));
    
    vmFulfillPerOnset{iBand}(iOnset) = sum(vmProbPerPeak);
    %vmViolationPerOnset{iBand}(iOnset) = sum(1 - vmProbPerPeak);
    vmAdjViolPerOnset{iBand}(iOnset) = adjDenvAtOnsets(iOnset) - sum(vmProbPerPeak);
    %vmMetricLevelProb{iBand,iOnset} = metricLevel;
    vmAreaPerPeakList{iBand,iOnset} = vmAreaPerPeak;
    vmPeakFreqsPerOnset{iBand,iOnset} = peakFreqs;
    vmK{iBand,iOnset} = k;
    vmTimingDev{iBand}(iOnset) = sum(vmAreaPerPeak);
  end  % if(~isempty(peakIdxs))
  
  end %for iOnset 
  
  
end % for iBand

expectationData = ensemble_init_data_struct;
expectationData.vars{end+1} = 'vmAngles';
expectationData.vars{end+1} = 'vmPeakFreqs';
expectationData.vars{end+1} = 'vmFulfillPerOnset';
expectationData.vars{end+1} = 'vmAreaPerPeak';
%expectationData.vars{end+1} = 'vmViolationPerOnset';
expectationData.vars{end+1} = 'vmAdjViolPerOnset';
expectationData.vars{end+1} = 'vmMetricLevelProb';
expectationData.vars{end+1} = 'vmTimingDev';
expectationData.vars{end+1} = 'vmK';
expDataCols = set_var_col_const(expectationData.vars);
expectationData.data{expDataCols.vmAngles} = angleDistVector';
expectationData.data{expDataCols.vmPeakFreqs} = vmPeakFreqsPerOnset;
expectationData.data{expDataCols.vmFulfillPerOnset} = vmFulfillPerOnset;
%expectationData.data{expDataCols.vmViolationPerOnset} = vmViolationPerOnset;
expectationData.data{expDataCols.vmAdjViolPerOnset} = vmAdjViolPerOnset;
expectationData.data{expDataCols.vmMetricLevelProb} = []; %vmMetricLevelProb;
expectationData.data{expDataCols.vmAreaPerPeak} = vmAreaPerPeakList;
expectationData.data{expDataCols.vmTimingDev} = vmTimingDev;
expectationData.data{expDataCols.vmK} = vmK;
outData = expectationData;

