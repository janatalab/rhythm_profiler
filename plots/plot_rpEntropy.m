function outData = plot_rpEntropy(thisRP,params)
% plots the entropy of peak ratios and metric classifier outputs
%
% outData = plot_rpEntropy(inData,params)
%
%
% 
% INPUT
%  thisRP: a rhythm profile (rp) data structure to plot
% 
% Copyright (c) 2008 The Regents of the University of California
% All Rights Reserved
%
% Author:
% 12/11/2008 First Version, Stefan Tomic

try
  ylim = params.entropy.ylim;
catch
  ylim = [0 1];
end

params.fig.axLocs = {'rectPlot_top','rectPlot_bottom'};
params.fig.xlabel = 'Time (s)';
params.fig.ylabel = 'Peak Ratio Entropy';

[figH,axHList] = rp_figure(params.fig);

ax_h = get_axhandle(axHList,'rectPlot_top');

thisRPCols = set_var_col_const(thisRP.vars);
ratioEntropy = thisRP.data{thisRPCols.ratioEntropyByFrame};
Fs = thisRP.data{thisRPCols.Fs};
nSamps = length(ratioEntropy);

rpParams = thisRP.data{thisRPCols.params};
entHopSize = rpParams.rp.mmpByFrame.hopSize;
entHopSizeSamps = Fs*entHopSize;
timeTickResSamps = params.timeTickRes.*Fs./entHopSizeSamps;
xtick = [1:timeTickResSamps:nSamps];
plot(ax_h,ratioEntropy);
xlabel(ax_h,'Time (s)');
ylabel(ax_h,'Peak Ratio Entropy');
set(ax_h,'xtick',xtick);
set(ax_h,'xticklabel',(xtick - 1).*entHopSizeSamps./Fs);
set(ax_h,'ytick',[0:.1:1]);
set(ax_h,'ylim',ylim);

fstubTag = '_rpEntropy';

save_rp_plot;
close(figH);

  
