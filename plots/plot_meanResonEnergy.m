function outData = plot_meanResonEnergy(inData,params)
%
%
%
%

rpData = inData;
rpCols = set_var_col_const(rpData.vars);
ax = params.ax;

numPlots = length(rpData.data{rpCols.meanResonEnergy});

for iPlot = 1:numPlots

  meanEnergy = rpData.data{rpCols.meanResonEnergy}{iPlot};
  stdEnergy  = rpData.data{rpCols.stdResonEnergy}{iPlot};
  resonFreqs = rpData.data{rpCols.resonatorFreqs}{iPlot};

  if(isfield(params,'lineSpec'))
    lspec = params.lineSpec{iPlot};
  else
    lspec = 'b-';
  end
  
  if(isfield(params,'plotStd') && params.plotStd(iPlot)) 
    errorbar(ax,meanEnergy,stdEnergy,lspec,'lineWidth',.5);
  else
    plot(ax,meanEnergy,lspec,'lineWidth',.5);
  end
  set(ax,'xlim',[1 length(meanEnergy)]);
  hold(ax,'on');
end



if(isfield(params,'ylim'))
  set(ax,'ylim',params.ylim);
end

%not plotting yticks for now. This may be changed later
set(ax,'ytick',[]);

if(isfield(params,'numResonTicks'))
  numResons = length(resonFreqs);
  resonFreqTick = [1:floor(numResons./params.numResonTicks):numResons];
  resonFreqLabel = num2str(resonFreqs(resonFreqTick)','%.2f');  
  set(ax,'xtick',resonFreqTick);
  set(ax,'xtickLabel',resonFreqLabel);
end

legend(ax,strrep(params.legendLabels,'_','\_'),'Location','NorthWest');

return
