function outData = plot_rpStages2(inData,params)
%
%
% contains elements of plot_rpStages. It serves similar purposes
% and may eventually replace the other script

dpi = 72;

figPadWidth = 7.5*dpi;
figPadHeight = 10*dpi;

numRows = 10;
numCols = 1;

figWidth = figPadWidth - 20;
figHeight = figPadHeight - 20;

axPadWidth = figWidth/numCols;
axPadHeight = floor(figHeight/numRows);

axWidth = axPadWidth - 10;
axHeight = axPadHeight - 10;


ani = inData{1};
rp = inData{2};

aniCols = set_var_col_const(ani.vars);
rpCols = set_var_col_const(rp.vars);

nChan = size(ani.data{aniCols.sig},1);


numSum = rp.data{rpCols.params}.rp.sumAdjacentBands;

aniFs = ani.data{aniCols.Fs};
rpFs = rp.data{rpCols.Fs};

for iChan = 1:nChan

  rowidx = mod(iChan-1,numRows);
  colidx = mod(floor((iChan-1)/numRows),numCols);
  
  if((mod(iChan-1,numRows) == 0) && (colidx == 0))
    figh = figure;
    set(figh,'position',[100 100 figPadWidth figPadHeight]);
    set(figh,'paperunits','inches','paperposition',[0.5 0.5 7.5 10]);
  end
  
  axLeft = (figPadWidth - figWidth)/2 + colidx*axPadWidth;
  axTop = figPadHeight/2 + figHeight/2 - (rowidx*axPadHeight);
  axBottom = axTop - axPadHeight;
  axes;
  
  plotSig = ani.data{aniCols.sig}(iChan,:);
  %normalize
  plotSig = (plotSig - min(plotSig));
  plotSig = plotSig./max(plotSig);
  plot([1:length(plotSig)]./aniFs,plotSig,'c');
  set(gca,'units','pixels','position',[axLeft axBottom axWidth axHeight],...
	  'xtick',[],'ytick',[]); 
  set(gca,'ylim',[min(plotSig) max(plotSig)]);
  timeLim = get(gca,'xlim');
  
  hold on;

  plotSig = rp.data{rpCols.rms}(iChan,:);
  %normalize
  plotSig = (plotSig - min(plotSig));
  plotSig = plotSig./max(plotSig);
  plot([1:length(plotSig)]./rpFs,plotSig,'k');
  set(gca,'units','pixels','position',[axLeft axBottom axWidth axHeight],...
	  'xtick',[],'ytick',[]);
  set(gca,'ylim',[min(plotSig) max(plotSig)]);
  set(gca,'xlim',timeLim);
   
  plotSig = rp.data{rpCols.denv}(iChan,:);
  %normalize
  plotSig = (plotSig - min(plotSig));
  plotSig = plotSig./max(plotSig);
  plot([1:length(plotSig)]./rpFs,plotSig,'r');
  set(gca,'units','pixels','position',[axLeft axBottom axWidth axHeight],...
	  'xtick',[],'ytick',[]);
  set(gca,'ylim',[min(plotSig) max(plotSig)]);
  set(gca,'xlim',timeLim);
    
  if(rowidx == numRows - 1) && (colidx == numCols -1)
    print('-dpsc','-append',params.fpath);
    close(figh);
  end
  
  
end


return

