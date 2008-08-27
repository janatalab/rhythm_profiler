function outData = plot_ratioProb(ax,inData,params)
% Plots a bargraph that illustrates relative heights of peaks,
% indicating probability of metric ratios present in input
%
% outData = plot_findPeaks(ax,inData,params)
%
% Description:
%
% INPUTS
%  ax: the axes handle to display the values of peak frequencies
%  inData: the rhythm profile (rp) struct containing the data to
%          analyze
%
%
% Copyright (c) 2008 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 8/20/2008

try
  numVals = params.numVals;
catch
  numVals = 16;
end

rp = inData;
rpCols = set_var_col_const(rp.vars);
peakInfo = rp.data{rpCols.peakInfo};
peakInfoCols = set_var_col_const(peakInfo.vars);
ratios = peakInfo.data{peakInfoCols.approxRatios};
heights = peakInfo.data{peakInfoCols.normHeight};

vals = zeros(1,numVals);
vals(ratios) = heights;

bar(ax,vals,0.4,'k');
set(ax,'xlim',[0 numVals + 1]);
set(ax,'ylim',[0 1]);
set(ax,'xtick',1:numVals);

return
