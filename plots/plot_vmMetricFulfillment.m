function outData = plot_vmMetricFulfillment(inData,params)
% plots von mises- based calculations for comparison
%
% params.plotData - a string specifying which von mises calc to display
% (vmPredictionPerOnset, vmViolationPerOnset, vmTimingDev)
%
% NOTE: supports just one band for now.
%
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 4/27/09
% 10/06/09 - updated for rhythm_profiler_v2 and for updates done to vm calcs
%            since this function was originally written

rp = inData;
if(iscell(rp))
  rp = rp{1};
end

try 
  vmParams.lastPlot;
catch
  vmParams.lastPlot = 0;
end

try
  params.title;
catch
  params.title = '';
end

rp = ensemble_datastruct2tree(rp);

%assuming second data cell is the input to the rhythm profiler
%this may be a little kludgy, but I need some quick results
inputSig = inData{2};
inputSigCols = set_var_col_const(inputSig.vars);
input_wvf = inputSig.data{inputSigCols.wvf};

Fs = rp.Fs;
sigLenSamps = size(rp.resonatorOut,3);
subPlotNum = params.subplotNum;
nSubPlots = 4;

vmExpect = rp.vmExpect;
plotData = vmExpect.(params.plotData){1};
onsetTimesSamps = rp.expectationError.onsetTimesSampsByBand{1}';

if(mod(subPlotNum,nSubPlots) == 1)
  close all
  figNum = floor(subPlotNum/nSubPlots) +1;
  figure(figNum);
  set(figNum,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);
  axes('position',[0 0.96 1 0.04],'visible','off');
  textH = text(0.5,0.5,params.plotData,'fontweight','bold','fontsize',16,'fontname','helvetica','verticalalignment','middle','horizontalalignment','center');
end

subPlotNum = mod(subPlotNum-1,nSubPlots)+1;

axBottom = 1 - 0.12 * (subPlotNum * 2 - 1);
axHInput = axes('position',[0.1 axBottom 0.8 0.075]);
axBottom = 1 - 0.12 * (subPlotNum * 2);
axHOutput = axes('position',[0.1 axBottom 0.8 0.075]);

%plot(axHInput,repmat(onsetTimesSamps,2,1),[zeros(size(onsetTimesSamps)) ; input_wvf(onsetTimesSamps)'],'b','linewidth',1.5);
plot(axHInput,input_wvf);
set(axHInput,'xtick',[1:2*Fs:sigLenSamps],'xticklabel',[0:2:sigLenSamps/Fs],'tickdir','out');
set(axHInput,'xlim',[0 (sigLenSamps+Fs)]); % set xlim to 1 sec past end of sig
title(axHInput,[params.title ' INPUT']);
plot(axHOutput,repmat(onsetTimesSamps,2,1),[zeros(size(plotData)) ; plotData],'b','linewidth',1.5);
set(axHOutput,'xtick',[1:2*Fs:sigLenSamps],'xticklabel',[0:2:sigLenSamps/Fs],'tickdir','out');
set(axHOutput,'xlim',[0 (sigLenSamps+Fs)]); % set xlim to 1 sec past end of sig
title(axHOutput,[params.title ' OUTPUT']);

meanData = mean(plotData);
axMeanVal = axes('position',[0.9 axBottom 0.1 0.075],'visible','off');
text(0.5,0.5,sprintf('%.2f',meanData),'fontsize',14,'fontname','helvetica','verticalalignment','middle','horizontalalignment','center')


if( params.savePlot && (params.lastPlot || (subPlotNum == nSubPlots)))

  fstub = regexprep([params.plotData '_' params.title],'[)(=]','');
  fstub = regexprep(fstub,'[\s,]','_');
  %fstub = strrep(fstub,'(','');
  %fstub = strrep(fstub,'=','');
  fullfname = fullfile(params.path,[fstub '_normByRMS2.ps']);
  print('-dpsc',fullfname);
  fprintf('writing to %s\n',fullfname);
end

outData = [];
