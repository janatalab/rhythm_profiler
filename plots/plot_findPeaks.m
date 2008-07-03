function outData = plot_findPeaks(ax,inData,params)
% Finds and displays the peaks in a mean periodicity profile 
%
% outData = plot_findPeaks(ax,inData,params)
%
% Description:
% Finds the peaks in a mean periodicity profile and displays the
% peak frequencies on the specified axes
%
% INPUTS
%  ax: the axes handle to display the values of peak frequencies
%  inData: the rhythm profile (rp) struct containing the data to
%          analyze
%  params.peakFinder.perform: cell array. If it contains "lowPass",
%                             then a low pass filter will be
%                             applied to the signal before peak detection
%  params.peakFinder.lpFreq: low pass cutoff frequency if
%                            performing low pass filtering for peak detection
%  params.peakFinder.thresh: float between 0 and 1. fraction of max
%                            value of the signal to regard as a
%                            threshold below which peak
%                            detection will not be performed
%
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 3/07



thisRP = inData;
thisRPCols = set_var_col_const(thisRP.vars);
get_rpPlotInfo;

%params.peakFinder.Fs = Fs;
%peakIdxs = find_peaks(meanEnergy,params.peakFinder);
%peakFreqs = resonFreqs(peakIdxs);
%maxPeakEnergyFreq = resonFreqs(find(meanEnergy == max(meanEnergy(peakIdxs)),1,'first'));
%normPeakFreqs = peakFreqs ./ maxPeakEnergyFreq;
%widths = get_rp_peakWidths('rpEnergy',meanEnergy,'peakFreqs',peakFreqs,'resonFreqs',resonFreqs)';

%nPeakFreqs = length(peakFreqs);

peakInfo = thisRP.data{thisRPCols.peakInfo};
peakInfoCols = set_var_col_const(peakInfo.vars);
peakFreqs = peakInfo.data{peakInfoCols.peak};
normPeakFreqs = peakInfo.data{peakInfoCols.norm};
widths = peakInfo.data{peakInfoCols.width};

peakFindHeader = sprintf('Peak   Norm   Width\n');
peakFindText = [peakFindHeader sprintf('%0.2f%8.2f%9.2f\n', ...
					 [peakFreqs normPeakFreqs widths]')];
axes(ax);
set(ax,'visible','off');
t = text(0,1,peakFindText,'VerticalAlignment','top');
  

  
