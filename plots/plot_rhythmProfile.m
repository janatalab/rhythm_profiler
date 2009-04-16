function outData = plot_rhythmProfile(inData,params)
% Handles the various plotting functions for a single rhythm profile (rp) struct
%
% This script calls various other functions for plotting resonator
% bank outputs, periodicity surfaces, average periodicity surfaces
% (APS), mean periodicity profiles (MPP), and input signals.
%
% possible params are plotTitle (title at top of plot
%                     timeTickRes (time tick resolution in Sec.)
%                     numResonTicks (number of reson filter ticks)             
%                     freqLegend (0 or 1: whether or not to print reson
%                                 freq legend, which gives the
%                                 reson period spacing)
%                     savePlot (0 or 1: whether or not to save the plot)
%                     plotPath (path to save plot to)
%                     plotFname (filename to save plot to)
%                     perform: cell array of strings for which plots to perform
%                                   possible vals:
%                                   'resonOutput','resonEnergy','plotBands',
%                                   'plotBandEnergies','stdEnergy'*,'findPeaks'*
%                                   *(only performed when
%                                   resonEnergy is performed)
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 3/07
%

%plot_rhythmProfile expects input data to be passed into successive
%cells in a cell array (after the rp, which is in inData{1}). The
%following allows passing just an rp, without encapsulating in a cell
if(~iscell(inData))
  temp = inData;
  clear inData;
  inData{1} = temp;
end

%allows for accepting an rp as a string or as an rp data struct
if(ischar(inData{1}))
  rpload = load(inData{1});
  thisRP = rpload.rp;
else
  thisRP = inData{1};
end

if(~isfield(params,'appendToPlot'))
  params.appendToPlot = 0;
end

if(isfield(params,'savePlot') && params.savePlot && ...
   exist(fullfile(params.savePath,params.plotFname),'file') && ~params.appendToPlot)
  confirm_overwrite = input(['File ' fullfile(params.savePath,params.plotFname) '  exists. Overwrite (y/n)?'],'s');
  if(ismember(confirm_overwrite,{'Y','y'}))
    delete(fullfile(params.savePath,params.plotFname));
  end
end

if(length(inData) > 1)
  audArray = inData(2:length(inData));
  audArrayCols = set_var_col_const(audArray{1}.vars);
else
  audArray = [];
end

get_rpPlotInfo;
numBands = size(thisRP.data{thisRPCols.resonatorOut},1);

if(~isfield(params,'fig') || (~isfield(params.fig,'title')))
  params.fig.title = '';
end

if(~isfield(params,'color'))
  params.color = 1;
end

if(~isfield(params,'bands') || ~isfield(params.bands,'climMode'))
  params.bands.climMode = 'scaledAcrossBands';
end

if(~isfield(params,'format'))
  params.format = '-dpsc';
end

if(isempty(thisRP))
 
  clear fparams;
  fparams.title = params.fig.title;
  fparams.axLocs = {};
  fig1 = rp_figure(fparams);
  
  axes('position',[0.5 0.5 0.1 0.02],'visible','off');
  txtMess_h = text(0.5,0.5,'No Rhythm Profile Data');
  set(txtMess_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14,'color',[1 0 0]);
  
  if(isfield(params,'savePlot') & params.savePlot)
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,params.plotFname)));
    print(params.format,'-append',fullfile(params.savePath,params.plotFname));
    close(fig1);
  end
  return
end

if(~isfield(params,'separatePages'))
  params.separatePages = 0;
end

params.fig.axLocs = {};

if(ismember('resonOutput',params.perform) && numBands == 1)
  params.fig.axLocs = union(params.fig.axLocs,'rectPlot_top');
  params.fig.axLocs = union(params.fig.axLocs,'smallBox_top');
  [figH,axHList] = rp_figure(params.fig);
  topAx = get_axhandle(axHList,'rectPlot_top');
  smallTopAx = get_axhandle(axHList,'smallBox_top');
  
  plot_rpResonOutput(topAx,thisRP,params);

  if(ismember('showInput',params.perform) && (length(audArray) > 0))
    params.xlim = get(topAx,'xlim');
    plot_rpInput(smallTopAx,audArray,params);
    
    if(isfield(params,'freqLegend') & params.freqLegend)
      audArrayCols = set_var_col_const(audArray{1}.vars);
      audFs = audArray{1}.data{audArrayCols.Fs};
      params.legendParams.Fs = 1;
      plotLegend(topAx,params.legendParams);
    end
    
  end

  if(isfield(params,'savePlot') & params.savePlot)

    [pth,fstub,ext] = fileparts(params.plotFname);
    if(params.separatePages)
      pfname = [fstub '_rOut' ext];
      print(params.format,fullfile(params.savePath,pfname));
    else
      pfname = [fstub ext];
      print(params.format,'-append',fullfile(params.savePath,pfname));
    end
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,pfname)));      
    close(figH);
  end

  
end

params.fig.axLocs = {};
if(ismember('resonEnergy',params.perform))
  params.fig.axLocs = union(params.fig.axLocs,'rectPlot_bottom');

  if(ismember('meanEnergy',params.perform))
    params.fig.axLocs = union(params.fig.axLocs, ...
			      'rectPlot_bottomRightVert');
  end
  
  if(ismember('findPeaks',params.perform))
    params.fig.axLocs = union(params.fig.axLocs,...
			      'smallRectPlot_top');
  end
  
  if(ismember('peakRatios',params.perform))
    params.fig.axLocs = union(params.fig.axLocs,'smallRectPlot_middle');
  end
  
  if(ismember('showInput',params.perform))
    params.fig.axLocs = union(params.fig.axLocs,'smallBox_bottom');
  end

  [figH,axHList] = rp_figure(params.fig);
  bottomAx = get_axhandle(axHList,'rectPlot_bottom');
 
  plot_rpResonEnergy(bottomAx,thisRP,params);

  if(ismember('meanEnergy',params.perform))
    bottomRightAx = get_axhandle(axHList,'rectPlot_bottomRightVert');
    plot_rpMeanResonEnergy(bottomRightAx,thisRP,params);
  end

  if(ismember('findPeaks',params.perform))
    topAx = get_axhandle(axHList,'smallRectPlot_top');
    plot_findPeaks(topAx,thisRP,params);
  end

  if(ismember('peakRatios',params.perform))
    middleAx = get_axhandle(axHList,'smallRectPlot_middle');
    plot_peakRatios(middleAx,thisRP,params);
  end
  
  if(ismember('showInput',params.perform) && (length(audArray) > ...
					      0))
    params.xlim = get(bottomAx,'xlim');
    smallBottomAx = get_axhandle(axHList,'smallBox_bottom');
    plot_rpInput(smallBottomAx,audArray,params);
    
    if(isfield(params,'freqLegend') & params.freqLegend)
      audArrayCols = set_var_col_const(audArray{1}.vars);
      audFs = audArray{1}.data{audArrayCols.Fs};
      params.legendParams.Fs = 1;
      plotLegend(topAx,params.legendParams);
    end


  end
  
  if(isfield(params,'savePlot') & params.savePlot)
    [pth,fstub,ext] = fileparts(params.plotFname);
    if(params.separatePages)
      pfname = [fstub '_rEnergy' ext];
      print(params.format,fullfile(params.savePath,pfname));
    else
      pfname = [fstub ext];
      print(params.format,'-append',fullfile(params.savePath,pfname));
    end
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,pfname))); 
    close(figH);
  end

end

if(ismember('plotBandOutputs',params.perform))
  %params.fig = [];
  params.fig.axLocs = {'subplot'};
  params.fig.nRows = 5;
  params.fig.nCols = 1;
  if(~isempty(thisRP.data{thisRPCols.meanChannelCBU}))
    rowLabelStr = sprintf('%.2f CBU,',thisRP.data{thisRPCols.meanChannelCBU});
    rowLabelCell = regexp(rowLabelStr,'\d+\.\d+ CBU','match');
  else
    rowLabelCell = repmat({''},numBands,1);
  end
  
  params.fig.rowLabels = rowLabelCell;
  params.fig.xLabel = 'Time (s)';
  params.fig.yLabel = 'Resonator Frequency (Hz)';  
  
  params.plotRPBandSigs.plotSig = 'resonatorOut';
  plot_rpBandSigs(thisRP,params);


end
  

if(ismember('plotBandEnergies',params.perform))
  %params.fig = [];
  params.fig.axLocs = {'subplot'};
  params.fig.nRows = 5;
  params.fig.nCols = 1;
  if(~isempty(thisRP.data{thisRPCols.meanChannelCBU}))
    rowLabelStr = sprintf('%.2f CBU,',thisRP.data{thisRPCols.meanChannelCBU});
    rowLabelCell = regexp(rowLabelStr,'\d+\.\d+ CBU','match');
  else
    rowLabelCell = repmat({''},numBands,1);
  end
  params.fig.rowLabels = rowLabelCell;
  params.fig.xLabel = 'Time (s)';
  params.fig.yLabel = 'Resonator Frequency (Hz)';  
  
  params.plotRPBandSigs.plotSig = 'resonatorBandEnergy';
  plot_rpBandSigs(thisRP,params);

end

if(ismember('entropy',params.perform))
    
  plot_rpEntropy(thisRP,params);
  
end

if(ismember('onsetExpectDist',params.perform))
  params.fig.axLocs = union(params.fig.axLocs,'squarePlot_top');
  params.fig.axLocs = union(params.fig.axLocs,'infoBox_top');
  [figH,axHList] = rp_figure(params.fig);
  topAx = get_axhandle(axHList,'squarePlot_top');
  infoAx = get_axhandle(axHList,'infoBox_top');
  
  expectData = thisRP.data{thisRPCols.expectationError};
  expectData = ensemble_datastruct2tree(expectData);
  polar(topAx,expectData.thetaDistPlotInfo,expectData.radDistPlotInfo);

  axes(infoAx);
  text(.05,.7,sprintf('Entropy: %.3f',expectData.distEntropy));
  text(.05,.5,sprintf('Mean Angle: %.2f',angle(expectData.distMean)));
  text(.05,.3,sprintf('Mean Strength: %.2f',abs(expectData.distMean)));
  
  if(isfield(params,'savePlot') & params.savePlot)
    [pth,fstub,ext] = fileparts(params.plotFname);
    if(params.separatePages)
      pfname = [fstub '_onsetExpectation' ext];
      print(params.format,fullfile(params.savePath,pfname));
    else
      pfname = [fstub ext];
      print(params.format,'-append',fullfile(params.savePath,pfname));
    end
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,pfname))); 
    close(figH);
  end
  
end

if(ismember('expectProbByOnset',params.perform))
  params.fig.axLocs = {};
  params.fig.axLocs = union(params.fig.axLocs,'squarePlot_top');
  params.fig.axLocs = union(params.fig.axLocs,'squarePlot_bottom');
  params.fig.axLocs = union(params.fig.axLocs,'smallLegend_topRight');
  params.fig.axLocs = union(params.fig.axLocs,'smallLegend_bottomRight');

  expectData = thisRP.data{thisRPCols.expectationError};
  expectData = ensemble_datastruct2tree(expectData);
  onsetExpectMtx = expectData.onsetExpectMtx;
  onsetsToPlot = params.expectProbByOnset.onsetsToPlot;
   
  %obtain the onset pattern to plot in the legend
  inSig = audArray{1}.data{audArrayCols.wvf};
  fpParams.thresh = 0.01;
  peakIdxs = find_peaks(inSig,fpParams);
  startLegendPlot = peakIdxs(min(onsetsToPlot));
  endLegendPlot = peakIdxs(max(onsetsToPlot)+1);
  
  nOnsets = length(onsetsToPlot);
  
  for iOnset = 1:nOnsets
    onsetNum = onsetsToPlot(iOnset);
    
    if(mod(iOnset-1,2) == 0)
      [figH,axHList] = rp_figure(params.fig);
      currentAx = get_axhandle(axHList,'squarePlot_top');
      legendAx = get_axhandle(axHList,'smallLegend_topRight');
    else
      currentAx = get_axhandle(axHList,'squarePlot_bottom');
      legendAx = get_axhandle(axHList,'smallLegend_bottomRight');
    end
 

    bar(legendAx,inSig(startLegendPlot:endLegendPlot),'barwidth',0.5);
    hold(legendAx,'on');
    bar(legendAx,peakIdxs(onsetNum)-startLegendPlot, ...
	inSig(peakIdxs(onsetNum)),'EdgeColor',[1 0 0],'barwidth',0.8);
    set(legendAx,'visible','off','xlim',[-4 (endLegendPlot-startLegendPlot+6)]);
    
    axes(currentAx);
    compass(currentAx,sum(onsetExpectMtx(:,onsetNum)),'r');
    hold on;
    compass(currentAx,onsetExpectMtx(:,onsetNum));
    camroll(currentAx,90);
    camzoom(currentAx,1.15);
   
    if(isfield(params,'savePlot') && params.savePlot && ...
       (mod(iOnset,2) == 0) )
      [pth,fstub,ext] = fileparts(params.plotFname);
      if(params.separatePages)
	pfname = [fstub '_expectProbByOnset' ext];
	print(params.format,fullfile(params.savePath,pfname));
      else
	pfname = [fstub ext];
	print(params.format,'-append',fullfile(params.savePath,pfname));
      end
      disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,pfname))); 
      close(figH);
    end %savePlot
    
  end %for iOnset
  
end %expectProbByOnset
   


outData = axHList;

return


function plotLegend(ax_h,params)

plotPos = get(ax_h,'position');
axWidth = plotPos(3);
axXlim = get(ax_h,'xlim');
widthPerSec = axWidth./(axXlim(2) - axXlim(1)).*params.Fs;
keyXPos = plotPos(1) + plotPos(3);
spacerHeight = .005;
numKeys = params.numKeys;
maxPeriod = 1./params.minHz;
keyWidth = widthPerSec*maxPeriod;
keyHeight = .01;

for iKey = 1:numKeys 
  keyYPos = plotPos(2)+plotPos(4) - (keyHeight)*iKey - spacerHeight*(iKey-1);
  legax = axes('position',[keyXPos+.18 keyYPos keyWidth keyHeight]);
  
  thisHz = (params.maxHz - params.minHz)./(numKeys).*(iKey -1) + params.minHz;
  thisPeriod = 1./thisHz;
  plot(repmat([0 thisPeriod],2,1),[0 0 ;1 1],'k');
  set(legax,'visible','off','xlim',[-0.05 1]);
  
  textAx = axes('position',[keyXPos+.12 keyYPos .02 .02],'xlim',[0 1],'ylim',[0 1],'visible','off');
  text(0,0,[num2str(thisHz,'%.2f') 'Hz'],'fontsize',8);
  
end

return
