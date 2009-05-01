function outData = plot_vmMetricFulfillment(inData,params)
% plots the metric fulfillment calculation obtained from von Mises distributions
%
%
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 4/27/09
%

rp = inData;
if(iscell(rp))
  rp = rp{1};
end


try(vmParams.lastPlot)
  vmParams.lastPlot = 0;
end

rp = ensemble_datastruct2tree(rp);

Fs = rp.Fs;
sigLenSamps = size(rp.resonatorOut,3);
subPlotNum = params.subplotNum;
nSubPlots = 6;

expectationError = rp.expectationError;
vmFulfillPerOnset = expectationError.vmFulfillPerOnset;
vmViolationPerOnset = expectationError.vmViolationPerOnset;
onsetTimesSamps = expectationError.onsetTimesSamps;

composite = (vmFulfillPerOnset./vmViolationPerOnset)';

if(mod(subPlotNum,nSubPlots))
  figNum = floor(subPlotNum/nSubPlots) +1;
  figure(figNum);
  set(figNum,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10])
end

if(subPlotNum == 1)
  axes('position',[0.1 0.9 0.9 0.5],'visible','off');
  text(0.5,0.5,'Composite Fulfillment','fontweight','bold');
end

subPlotNum = mod(subPlotNum-1,nSubPlots)+1;
subplot(nSubPlots,1,subPlotNum);
plot(repmat(onsetTimesSamps,2,1),[zeros(size(composite)) ; composite],'b','linewidth',1.5);
set(gca,'xtick',[1:2*Fs:sigLenSamps],'xticklabel',[0:2:sigLenSamps/Fs],'tickdir','out');
set(gca,'xlim',[0 (sigLenSamps+Fs)]); % set xlim to 1 sec past end of sig
title(params.title);


if( params.savePlot && (params.lastPlot || (subPlotNum == nSubPlots)))
  fullfname = fullfile(params.path,params.fname);
  print('-dpsc','-append',fullfname);
end

outData = [];
