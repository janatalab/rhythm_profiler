function outData = get_resonPeakInfo(meanEnergy,resonFreqs,params)
% Retrieves peak frequencies and peak widths of an RP structure
%
% outData = get_resonPeakInfo(thisRP,params)
%
% This script calls various other functions for plotting resonator
% bank outputs, periodicity surfaces, average periodicity surfaces
% (APS), mean periodicity profiles (MPP), and input signals.
%
% This function passes the params struct to find_peaks.m
% Please see the discription for that function for details on params.
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 3/07
%


if(size(resonFreqs,2) > size(resonFreqs,1))
  resonFreqs = resonFreqs';
end

peakIdxs = find_peaks(meanEnergy,params)';
peakHeights = peak_heights('signal',meanEnergy,'peakIdxs',peakIdxs,'xVals',resonFreqs);
if(isfield(params,'minPeakHeight'))
  goodPeakMask = peakHeights >= params.minPeakHeight;
  peakIdxs = peakIdxs(goodPeakMask,1);
  peakHeights = peakHeights(goodPeakMask);
end

if(~isempty(peakIdxs))
  peakFreqs = resonFreqs(peakIdxs);
  maxPeakEnergyFreq = resonFreqs(find(meanEnergy == max(meanEnergy(peakIdxs)),1,'first'));
  normPeakFreqs = peakFreqs ./ maxPeakEnergyFreq;
  widths = get_rp_peakWidths('rpEnergy',meanEnergy,'peakFreqs',peakFreqs,'resonFreqs',resonFreqs);
  [approxRatios,ratioBinIdx,errorVec] = approx_peak_ratios('peakFreqs',peakFreqs,'maxPeakFreq',maxPeakEnergyFreq,'params',params);
else
  peakFreqs = [];
  normPeakFreqs = [];
  widths = [];
  peakHeights = [];
  approxRatios = [];
  errorVec = [];
  ratioBinIdx = [];
end

outData.peakFreq = peakFreqs;
outData.normPeakFreq = normPeakFreqs;
outData.width = widths;
outData.normHeight = peakHeights;
outData.approxRatio = approxRatios;
outData.ratioBinIdx = ratioBinIdx;
outData.errorVec = errorVec;
return
  

  
