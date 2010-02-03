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


%NOT BEING USED
%MMP = rp.meanResonatorEnergy;
%MMPPeaks = rp.peakInfo.peakFreq;
%MMPPeriods = 1./MMPPeaks;

nBands = size(rp.resonatorOut,1);

refVec = complex(1,0);

peakPhaseTolerances = pi/6;

%nTimeSamps = size(rp.resonatorBandEnergy,3);
%if(~isempty(params.timeLimSecs))
%  timeStartSamps = round(params.timeLimSecs(1) * params.Fs) + 1;
%  timeStopSamps = min(round(params.timeLimSecs(2) * params.Fs),nTimeSamps);
%else
%  timeStartSamps = 1;
%  timeStopSamps = size(rp.resonatorOut,3);
%end

if(params.perform.phaseCoherence.useInterpPeak)
  bandPeakInfo = rp.interpMPPStruct.bandPeakInfo;
else
  bandPeakInfo = rp.peakInfo.bandPeakInfo;
end

for iBand = 1:nBands
  
  %recalculate MPP over specified time limit
  %MPPThisBand = mean(squeeze(rp.resonatorBandEnergy(iBand,:,timeStartSamps:timeStopSamps)),2);
  %fpParams = params.resonatorBank.peakFinder;
  %peakIdxs = find_peaks(MPPThisBand,fpParams);
  %peakHeights = peak_heights('signal',MPPThisBand,'peakIdxs',peakIdxs);
  %if(isfield(fpParams,'minPeakHeight'))
  %  goodPeakMask = peakHeights >= fpParams.minPeakHeight;
  %  peakIdxs = peakIdxs(goodPeakMask);
  %  peakHeights = peakHeights(goodPeakMask);
  %end

  peakFreqsThisBand = bandPeakInfo.peakFreq{iBand};
  nPeaks = length(peakFreqsThisBand);
  
  onsetTimesThisBand = onsetTimesSampsByBand{iBand};
  nOnsets = length(onsetTimesThisBand);
  onsetExpectThisBand = onsetExpectByBand{iBand};
 
  mlMask = [];
  mlAssign = [];
  peakMagsByOnset = [];
  peakPhasesByOnset = [];
  
  %we might want to abstract the whole phase and magnitude interpolation
  %routine out to an earlier stage, since this is fairly costly, and
  %also used by multiple functions (e.g. vmExpect calc)
  if(params.perform.phaseCoherence.useInterpPeak)
    
    %find the border reson indices to the interpolated peaks
    %the border indices will be used to calculate interpolated phase angles
    
    for iPeak = 1:nPeaks

      lBorderReson = find(resonFreqs <= peakFreqsThisBand(iPeak),1,'last');
      rBorderReson = find(resonFreqs > peakFreqsThisBand(iPeak),1,'first');
      thisPeak = peakFreqsThisBand(iPeak);
      pct =(thisPeak - resonFreqs(lBorderReson)) ./ ...
	    (resonFreqs(rBorderReson) - resonFreqs(lBorderReson));     
      
 
      for iOnset = 1:nOnsets
	
	thisComplexResonMags = abs(onsetExpectThisBand(:,iOnset));
	lMag = thisComplexResonMags(lBorderReson);
	rMag = thisComplexResonMags(rBorderReson);
	diffMag = diff([lMag rMag]);
	
	lAngle = angle(onsetExpectThisBand(lBorderReson,iOnset));
	rAngle = angle(onsetExpectThisBand(rBorderReson,iOnset));
	peakPhasesByOnset(iPeak,iOnset) = interpAngle(lAngle,rAngle,pct);
	peakMagsByOnset(iPeak,iOnset) = lMag + pct .* diffMag;
	
      end%for
    
    end %for
    
  else
    %not interpolating. Use peakPhases and peakMags corresponding to
    %non-interpolated MPP
    
    peakIdxs = bandPeakInfo.peakIdxs{iBand};
    peakPhasesByOnset = angle(onsetExpectThisBand(peakIdxs,:));
    peakMagsByOnset = abs(onsetExpectThisBand(peakIdxs,:));
    
  end
  
  
  for iOnset = 1:nOnsets

    %peakPhases = angle(onsetExpectThisBand(peakIdxs,iOnset));

    peakPhases = peakPhasesByOnset(:,iOnset);
    
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

  allVecs = peakMagsByOnset .* cos(peakPhasesByOnset) + peakMagsByOnset .* ...
	    sin(peakPhasesByOnset) .* i;
  
  
  for iPeak = 1:nPeaks    
    
    %peakRefIdx = peakIdxs(iPeak);
    
    %vecsAssignedThisPeak = squeeze(onsetExpectThisBand(peakRefIdx,find(mlAssign(iPeak,:))))';
    
    vecsThisPeak = allVecs(iPeak,find(mlAssign(iPeak,:)))';
    
    
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
  
  %peakHeights(~keepPeaks) = [];
  %peakFreqsPerBand{iBand}(~keepPeaks) = [];
  %peakHeightsPerBand{iBand,1} = peakHeights;
  
  
end %for iBand

cohStruct = ensemble_init_data_struct;
cohStruct.vars = {'peakFreqPerBand','cohPerPeakPerBand','peakHeightsPerBand'};
cohCols = set_var_col_const(cohStruct.vars);

%not exporting peakFreqsPerBand or peakHeightsPerBand any longer
%this was probably only done because we were recalculating MPP peaks
%due to setting timelim. But timelim should really probably be dealt with
%elsewhere

%cohStruct.data{cohCols.peakFreqPerBand} = peakFreqsPerBand;
cohStruct.data{cohCols.cohPerPeakPerBand} = cohPerPeak;
%cohStruct.data{cohCols.peakHeightsPerBand} = peakHeightsPerBand;

outData = cohStruct;

