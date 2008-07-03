function plot_rpMeanResonEnergy(ax,thisRP,params)
% Plots a mean periodicity profile (MPP)
% 
% plot_rpMeanResonEnergy(ax,thisRP,params)
%
% plots a mean periodicity profile (MPP) on a specified axes given
% a rp struct. Standard deviation bars can optionally be plotted.
%
% INPUT
% ax: the axes handle to plot to
% thisRP: rhythm profile (rp) data struct
% params.meanEnergy.numTicks: number of y ticks
% params.meanEnergy.yTickLabelFmt: C String style format for y tick labels
% params.meanEnergy.yLim: ylim specification for MPP
% params.perform: if this contains a cell array with 'stdEnergy',
%                 then standard deviation bars will be plotted
% params.color: 0 or 1. Whether or not to plot in color
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 4/07


get_rpPlotInfo;
axes(ax);
  
if(~isfield(params,'meanEnergy') || (~isfield(params.meanEnergy,'numticks')))
  params.meanEnergy.numticks = 4;
end

if(~isfield(params,'meanEnergy') || (~isfield(params.meanEnergy,'yTickLabelFmt')))
  params.meanEnergy.yTickLabelFmt = '%.2f';
end

if(ismember('stdEnergy',params.perform))

  
  if(params.color)
    colorSpec = [0 0.8 0];
  else
    colorSpec = [0.5 0.5 0.5];
  end
  
  errorbar(meanEnergy,stdEnergy,'color',colorSpec);
  hold on;
end
  
if(isfield(params,'meanEnergy') && isfield(params.meanEnergy,'ylim'))
  ylim = params.meanEnergy.ylim;
elseif(ismember('stdEnergy',params.perform))
  ylim(1) = 0.8.*min(meanEnergy - stdEnergy);
  ylim(2) = 1.2.*max(meanEnergy + stdEnergy);
else
  ylim(1) = 0.8.*min(meanEnergy);
  ylim(2) = 1.2.*max(meanEnergy);
end
plot(meanEnergy,'k');
set(ax,'ylim',ylim);
set(ax,'xlim',[freqMin freqMax]);
set(ax,'xtick',[]);
set(ax,'ytick',[]);
camorbit(ax,90,0);
ytick = [ylim(1):(ylim(2)-ylim(1))/(params.meanEnergy.numticks-1):ylim(2)]';

set(ax,'ytick',ytick);
set(ax,'yticklabel',num2str(ytick,params.meanEnergy.yTickLabelFmt));
set(ax,'yaxislocation','right');
rotateyticklabel(ax,-90);
  
return
