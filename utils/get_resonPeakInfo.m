function outData = get_resonPeakInfo(thisRP,params)
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

thisRPCols = set_var_col_const(thisRP.vars);
meanEnergy = thisRP.data{thisRPCols.meanResonatorEnergy};
resonFreqs = thisRP.data{thisRPCols.resonatorFreqs};
if(size(resonFreqs,2) > size(resonFreqs,1))
  resonFreqs = resonFreqs';
end


peakIdxs = find_peaks(meanEnergy,params);
peakFreqs = resonFreqs(peakIdxs);
maxPeakEnergyFreq = resonFreqs(find(meanEnergy == max(meanEnergy(peakIdxs)),1,'first'));
normPeakFreqs = peakFreqs ./ maxPeakEnergyFreq;
widths = get_rp_peakWidths('rpEnergy',meanEnergy,'peakFreqs',peakFreqs,'resonFreqs',resonFreqs);

nPeakFreqs = length(peakFreqs);


outData = ensemble_init_data_struct;
outData.name = 'rp_peak_info';
outData.type = 'rp_peak_info';
outData.vars = {'peak','norm','width'};
outDataCols= set_var_col_const(outData.vars);
outData.data{outDataCols.peak} = peakFreqs;
outData.data{outDataCols.norm} = normPeakFreqs;
outData.data{outDataCols.width} = widths;

return
  

  
