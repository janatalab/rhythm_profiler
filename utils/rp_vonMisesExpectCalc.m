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

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

expectErrorStruct = rp.expectationError;


onsetExpectMtx = expectErrorStruct.onsetExpectMtx;
onsetTimesSamps = expectErrorStruct.onsetTimesSamps;
nOnsets = length(onsetTimesSamps);

peakFinderParams =  params.ipem.rp.resonatorBank.peakFinder;
resonFreqs = rp.resonatorFreqs;

for iOnset = 1:nOnsets
  
  thisComplexResonOut = onsetExpectMtx(:,iOnset);
  thisComplexResonMags = abs(thisComplexResonOut);
  thisComplexResonPhases = angle(thisComplexResonOut);
  
  %find the peak locations of the reson filter corresponding to this onset time
  %thresholding this might be a little tricky. Revisit this if we
  %are losing peaks (or have too many)
  peakIdxs = find_peaks(thisComplexResonMags,params)';
  peakHeights = peak_heights('signal',thisComplexResonMags,'peakIdxs',peakIdxs); 
  goodPeakMask = peakHeights >= peakFinderParams.minPeakHeight;
  peakIdxs = peakIdxs(goodPeakMask,1);
  peakHeights = peakHeights(goodPeakMask);
  
  if(~isempty(peakIdxs))
    if(peakIdxs(1) == 1)
      peakIdxs(1) = [];
      peakHeights(1) = [];
    end
  
    peakFreqs = resonFreqs(peakIdxs);
    peakWidths = peak_widths('signal',thisComplexResonMags,'peakIdxs',peakIdxs,'params',pwParams);
    peakPhases = angle(thisComplexResonOut(peakIdxs))';

    nPeaks = length(peakIdxs);
  
    %calculate phase tolerance for assigning metric levels to the onset
    peakPeriods = 1./peakFreqs;
    phaseTolerances = metricLevelToleranceSec ./ peakPeriods .* 2.*pi;
    %if there are no phases within the tolerance values, then
    %assign the closest phase to 0, otherwise, use only those
    %metric levels that are within the tolerance.
    if(~any(abs(peakPhases) <= phaseTolerances))
      assignMetricLevels = find(abs(peakPhases) == ...
				min(abs(peakPhases)));
    else
      assignMetricLevels = find(abs(peakPhases) <= ...
				phaseTolerances);
    end
    
    clear vmDistThisPeak vmProbPerPeak metricLevel pwProportion;
    k = [];
    timingDev = [];
    for iPeak = 1:nPeaks
         
      borders = [peakWidths(iPeak*2-1) peakWidths(iPeak*2)];
      borderAngles = angle(thisComplexResonOut(borders));
      pwProportion(iPeak) = abs(diff(resonFreqs(borders)))./peakFreqs(iPeak);
      %assuming that half of pwProportion is equivalent to variance
      variance = pwProportion(iPeak).*pi;
      %dispersion, k, is roughly equivalent to 1./variance 
      k(iPeak)  = 1./(variance);
      vmDistThisPeak =  von_mises_pdf(angleDistVector,peakPhases(iPeak),k(iPeak));
      vmDistThisPeak = (vmDistThisPeak - min(vmDistThisPeak)) ./ ...
			(max(vmDistThisPeak) - min(vmDistThisPeak));
      
      vmProbPerPeak(iPeak) = vmDistThisPeak(angleDistVector == 0) ...
	  .* thisComplexResonMags(peakIdxs(iPeak));    

      %constructing an overall distribution matrix
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
      
    end %for iPeak
  
    %find the timing devation from the closest peak. This is our
    %timing error
    sumMetricDist = sum(metricLevel,1);
    smdPeakIdxs = find_peaks(sumMetricDist,[]);
    smdPeakHeights = peak_heights('signal',sumMetricDist,'peakIdxs',smdPeakIdxs);
    smdPeakIdxs = smdPeakIdxs(smdPeakHeights >= 0.1);
    smdBorder1 = find(angleDistVector == 0);
    %if we just happen to be smack in the middle of two peaks, take
    %the later one (negative dir)
    smdBorder2 = ...
	smdPeakIdxs(find(abs(angleDistVector(smdPeakIdxs)) == min(abs(angleDistVector(smdPeakIdxs))),1,'first'));
    smdMin = min(smdBorder1,smdBorder2);
    smdMax = max(smdBorder1,smdBorder2);
    smdArea = sum(sumMetricDist(smdMin:smdMax).*(pi/distResolution));
    
    vmFulfillPerOnset(iOnset,1) = sum(vmProbPerPeak);
    vmViolationPerOnset(iOnset,1) = sum(1 - vmProbPerPeak);
    vmMetricLevelProb{iOnset,1} = metricLevel;
    vmPeakFreqsPerOnset{iOnset,1} = peakFreqs;
    vmMetricLevelError = max(timingDev);
    vmK{iOnset,1} = k;
    vmTimingDev(iOnset,1) = smdArea;
  end  % if(~isempty(peakIdxs))
  
end %for iOnset 

if(iscell(inData))
  outData = inData{1};
else
  outData = inData;
end
outDataCols = set_var_col_const(outData.vars);
expectationData = outData.data{outDataCols.expectationError};
expectationData.vars{end+1} = 'vmAngles';
expectationData.vars{end+1} = 'vmPeakFreqs';
expectationData.vars{end+1} = 'vmFulfillPerOnset';
expectationData.vars{end+1} = 'vmViolationPerOnset';
expectationData.vars{end+1} = 'vmMetricLevelProb';
expectationData.vars{end+1} = 'vmTimingDev';
expectationData.vars{end+1} = 'vmK';
expDataCols = set_var_col_const(expectationData.vars);
expectationData.data{expDataCols.vmAngles} = angleDistVector';
expectationData.data{expDataCols.vmPeakFreqs} = vmPeakFreqsPerOnset;
expectationData.data{expDataCols.vmFulfillPerOnset} = vmFulfillPerOnset;
expectationData.data{expDataCols.vmViolationPerOnset} = vmViolationPerOnset;
expectationData.data{expDataCols.vmMetricLevelProb} = ...
    vmMetricLevelProb;
expectationData.data{expDataCols.vmTimingDev} = vmTimingDev;
expectationData.data{expDataCols.vmK} = vmK;
outData.data{outDataCols.expectationError} = expectationData;

