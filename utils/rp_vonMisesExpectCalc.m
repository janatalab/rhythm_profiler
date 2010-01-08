function outData = rp_vonMisesExpectCalc(varargin)
% Calculates an expectation error based on von Mises distributions across metric levels
% 
% outData = rp_vonMisesExpectCalc(inData,params)
% 
% INPUTS (tag/value pairs):
%         rp - a rhythm profiler struct
%   inputSig - the input signal to the resonator model (denv, sumDenv, or any
%              other signal)
%
%     RELEVANT PARAMS:
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
  end
end

rpCols = set_var_col_const(rp.vars);
params = rp.data{rpCols.params}.rp;

%for better results, use a distResolution that is odd (results in an even
%number of bins)
try
  params.vmExpect.distResolution = 100;
catch
  warning('von Mises distribution resolution not set. Setting to 100.');
  params.vmExpect.distResolution = 100;
end

distResolution = params.vmExpect.distResolution;
angleDistVector = [-pi:2*pi/distResolution:pi];


%obtain idx
if(iscell(rp))
  rp = rp{1};
end

rp = ensemble_datastruct2tree(rp);

onsetInfo = rp.onsetInfo;

peakFinderParams =  params.resonatorBank.peakFinder;
resonFreqs = rp.resonatorFreqs;
nResons = length(resonFreqs);
nBands = length(onsetInfo.onsetTimesSampsByBand);

if(params.perform.vmExpect.useInterpPeak)
  bandPeakInfo = rp.interpMPPStruct.bandPeakInfo;
else
  bandPeakInfo = rp.peakInfo.bandPeakInfo;
end

for iBand = 1:nBands

  onsetTimesThisBand = onsetInfo.onsetTimesSampsByBand{iBand};
  
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
     
  nOnsets = length(onsetTimesThisBand);
  
  %obtain the denv magnitudes at onset times
  denvAtOnsets = squeeze(inputSig(iBand,onsetTimesThisBand));
  denvThisBand = inputSig(iBand,:);
  
  peakFreqs = bandPeakInfo.peakFreq{iBand};
  peakWidths = bandPeakInfo.baseWidths{iBand};
  peakHeights = bandPeakInfo.normHeight{iBand};
    
  %normalizing by RMS here
  peakIdxs = rp.peakInfo.peakIdxs; %get peak idxs of non-interpolated peaks
  rmsResonThisBand = sqrt(mean(squeeze(rp.resonatorOut(iBand,peakIdxs,:)).^2,2));
  meanRMSThisBand = mean(rmsResonThisBand);

  onsetExpectByBand = rp.complexExpectAtOnsets{iBand};
  onsetExpectByBand = onsetExpectByBand ./ meanRMSThisBand;
  denvEnergy = sqrt(mean(denvThisBand.^2));

  adjDenvAtOnsets = denvAtOnsets ./ denvEnergy;
    
 
  for iOnset = 1:nOnsets
    
    thisComplexResonOut = onsetExpectByBand(:,iOnset);
    thisComplexResonMags = abs(thisComplexResonOut);
    thisComplexResonPhases = angle(thisComplexResonOut);
  
    clear peakPhases
    if(params.perform.vmExpect.useInterpPeak)
      
      nInterpPeaks = length(peakFreqs);
      for iInterpPeak = 1:nInterpPeaks
	thisPeak = peakFreqs(iInterpPeak);
	lBorderReson = find(resonFreqs <= thisPeak,1,'last');
	rBorderReson = find(resonFreqs >= thisPeak,1,'first');
	pct(iInterpPeak) = (thisPeak - resonFreqs(lBorderReson)) ./ ...
	    (resonFreqs(rBorderReson) - resonFreqs(lBorderReson));
	if(~isfinite(pct))
	  pct(iInterpPeak) = 0;
	end
		
	lAngle = angle(thisComplexResonOut(lBorderReson));
	rAngle = angle(thisComplexResonOut(rBorderReson));
	
	lMag = thisComplexResonMags(lBorderReson);
	rMag = thisComplexResonMags(rBorderReson);
	diffMag = diff([lMag rMag]);
	
	peakPhases(iInterpPeak) = interpAngle(lAngle,rAngle,pct(iInterpPeak));
	peakMags(iInterpPeak) = lMag + pct(iInterpPeak) .* diffMag;
	
      end      
   
    else
      peakPhases = angle(thisComplexResonOut(peakIdxs))';
      peakMags = thisComplexResonMags(peakIdxs);
    end
    
    nPeaks = length(peakIdxs);
    
    
    clear variance vmDistPerPeak vmAreaPerPeak vmProbPerPeak vmAdjProbPerPeak vmAdjProbPerPeakTest metricLevel pwProportion;
    k = [];
    timingDev = [];
    for iPeak = 1:nPeaks
	
      pwProportion(iPeak) = peakWidths(iPeak)./ peakFreqs(iPeak)./peakHeights(iPeak);
      variance(iPeak) = pwProportion(iPeak);

      k(iPeak)  = 1./(variance(iPeak));
      vmDistPerPeak(iPeak,:) =  von_mises_pdf(angleDistVector,0,k(iPeak));


      diffAngle = peakPhases(iPeak) - angleDistVector;
      evalAngleIdx = find(abs(diffAngle) == min(abs(diffAngle)));
      evalAngleIdxPerPeak(iPeak) = evalAngleIdx;
     
      sumResonMags = sum(peakMags);
      
      if(sumResonMags ~= 0)
	weight(iPeak) = peakMags(iPeak) ./ sumResonMags;
      else
	weight(iPeak) = 0;
      end

      vmProbPerPeak(iPeak) = vmDistPerPeak(iPeak,evalAngleIdx).*weight(iPeak);

      %find the indices to evaluate for the area of the von mises
      %dist (timing dev calc)
      %not including index corresponding to angle zero. This could result
      %in a value greater than .5 (since zero bin is directly in the middle
      %when using odd number of bins).
      if(peakPhases(iPeak) > 0)
	areaIdxs = find((angleDistVector > 0) & (angleDistVector <= peakPhases(iPeak)));
      else
	areaIdxs = find((angleDistVector >= peakPhases(iPeak)) & (angleDistVector < 0));
      end
     
      vmAreaPerPeak(iPeak) = sum(vmDistPerPeak(iPeak,areaIdxs).*...
				 weight(iPeak).*(pi/distResolution));    
      
     

      
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
