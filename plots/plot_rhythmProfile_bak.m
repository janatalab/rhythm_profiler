function outData = plot_rhythmProfile(inData,params)
%
% plots a single rhythm profile from the rp data, passed in to the
% first data argument (inData).
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
%  May 2007 - Stefan Tomic

load new_seismic;

[pth,fstub,ext] = fileparts(params.plotFname);

thisRP = inData{1};

if(length(inData) > 1)
  audArray = inData(2:length(inData));
  audArrayCols = set_var_col_const(audArray{1}.vars);
else
  audArray = [];
end


if(~ismember('showInput',params.perform))
  params.perform = union(params.perform,'showInput');
end

if(isempty(thisRP))
 
  clear fparams;
  fparams.plotTitle = params.plotTitle;
  fparams.axLocs = {};
  fig1 = rhythmTap_figure(fparams);
  
  axes('position',[0.5 0.5 0.1 0.02],'visible','off');
  txtMess_h = text(0.5,0.5,'No Rhythm Profile Data');
  set(txtMess_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14,'color',[1 0 0]);
  
  if(isfield(params,'savePlot') & params.savePlot)
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,params.plotFname)));
    print('-dpsc','-append',fullfile(params.savePath,params.plotFname));
    close(fig1);
  end
  return
  
else
  thisRPCols = set_var_col_const(thisRP.vars);
  Fs = thisRP.data{thisRPCols.Fs};
  resonFreqs = thisRP.data{thisRPCols.resonatorFreqs};

  %make sure resonFreqs is a column vector to construct the
  %proper label string matrix
  if(size(resonFreqs,2) > 1)
    resonFreqs = resonFreqs';
  end
  
  nResons = length(resonFreqs);
  freqMin = 1;
  if(isfield(params,'maxResonFreqPlot'))
    freqMax = find(resonFreqs < params.maxResonFreqPlot,1,'last');
  else
    freqMax = length(resonFreqs);
  end
  

  resIdxVector = [1:nResons];
  resonFreqTick = [freqMin:floor(freqMax./params.numResonTicks):freqMax];
  resonFreqLabel = num2str(resonFreqs(resonFreqTick),'%.2f');

  
  
  % get time tick labels if performing resonEnergy or resonOutput
  % (not necessary if just plotting mean reson output)
  if(~isempty(intersect({'resonEnergy','resonOutput'},params.perform)))
  
  end
  
     
end
  
if(ismember('resonOutput',params.perform))
  
  rOut = thisRP.data{thisRPCols.resonatorOut};
  
  %if all bands of rOut were passed in, take the mean across bands
  if(ndims(rOut) == 3)
    rOut = squeeze(mean(rOut,1));
  end
  
  nTimeSamps = size(rOut,2);
  timeVector = [0:nTimeSamps-1]./Fs;
  timeTick = [0:params.timeTickRes:timeVector(end)];
  
  %create the figure
  fig1 = figure;
  set(fig1,'units','inches');
  set(fig1,'position',[1 1 8 10.5]); 
  set(fig1,'paperposition',[0.25 0.25 8 10.5]); 

  %assign a title to the figure
  titleStr = strrep(params.plotTitle,'_','\_');
  axes('position',[0.5 0.95 0.1 0.02],'visible','off');
  txt_h = text(0.5,0.5,titleStr);
  set(txt_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14);

  %firstSubH = axes('position',[0.13 0.11 0.775 0.7]);
  firstSubH = axes('position',[0.13 0.47 0.775 0.34]);
  imagesc(timeVector,resIdxVector,rOut);


  if(isfield(params,'colorbar') & params.colorbar)
    colorbar;
  end

  colormap(new_seismic);
 
  maxRoutVal = max(max(abs(rOut))); 
  
  if(isfield(params,'resonOut') && isfield(params.resonOut,'clim'))
    setClim = params.resonOut.clim;
  else
    setClim = [-maxRoutVal maxRoutVal];
  end

  set(gca,'clim',setClim);
  set(gca,'Xtick',timeTick);
  set(gca,'Ytick',resonFreqTick);
  set(gca,'YtickLabel',resonFreqLabel);
  set(gca,'YLim',[freqMin freqMax]);
  xlabel('time (s)');
  ylabel('Resonator Freq (Hz)');
  
  %plot the impulse onsets and overlay on first subplot
  if(length(audArray) > 0 && ismember('showInput',params.perform))
    figure(fig1);
    pos = get(firstSubH,'position');
    xlimAx = get(firstSubH,'xlim');
  
    inputGraphH = axes('position',[pos(1) 0.81 pos(3) 0.1]);

    hold on;
    wvfPlotNum = 1;

    wvfFs = audArray{1}.data{audArrayCols.Fs}(1);
    
    for iAudGroup = 1:length(audArray)
      audStruct = audArray{iAudGroup};
      thisWvf = audStruct.data{audArrayCols.wvf};
      if(iscell(thisWvf))
	thisWvf = thisWvf{1};
      end

      thisWvfFs = audStruct.data{audArrayCols.Fs};
      
      if(any(diff(thisWvfFs)))
	error('Wvf overlays on RP output plot do not have matching sampling rates.');
      else      
	thisWvfFs = thisWvfFs(1);
      end
      
      if(isfield(params,'trialSets'))
	findTrialSet = params.trialSets(find(iAudGroup == params.trialSets(:,1)),2);
	thisColor = [1 0 0]*(mod(findTrialSet-1,2));
      else
	thisColor = [0 0 0];
      end
      
      if(~isempty(thisWvf))
	
	if(thisWvfFs ~= wvfFs)
	  error('Wvf overlays on RP output plot do not have matching sampling rates.');
	end
	  
	switch (params.inputSigType)
	 case 'impulse'
	  if(isfield(params,'overlayInput') && params.overlayInput)
	    yMin = 0;
	    yMax = 1;
	  else
	    yMin = wvfPlotNum-1;
	    yMax = wvfPlotNum;
	  end
	  wvfPointsX = repmat(find(thisWvf)',2,1);
	  wvfPointsY = [yMin ; yMax] * ones(1,size(wvfPointsX,2));
	  plot(wvfPointsX,wvfPointsY,'Color',thisColor);
	 case 'wvf'

	  yMin = 0;
	  yMax = 1;
	  %convert wvf to mono if necessary
	  thisWvf = mean(thisWvf,2);
	  %normalize
	  thisWvf = -1.*thisWvf./max(abs(thisWvf)).*0.98;
	  %scale and offset wvf to be between 0 and 1
	  thisWvf = thisWvf - min(thisWvf);
	  %wvfPointsX = repmat([1:length(thisWvf)],2,1)./wvfFs;
	  %wvfPointsY = [yMin ; yMax] * ones(1,size(wvfPointsX,2));
	  plot(thisWvf,'k');
	  
	  %plot HWR diff
	  %denv = thisRP.data{thisRPCols.denv};
	  %denvFs = thisRP.data{thisRPCols.Fs};
	  %for iChan = 1:size(denv,1)
	  %  yMin = iChan;
	  %  yMax = iChan+1;
	  %  denvChan = denv(iChan,:);
	    %normalize the signal and reverse it (since we're going
            %to reverse the axes later)
	  %  denvChan = -1 .* (denvChan  - min(denvChan))./max(denvChan) + 1;
	  %  denvPointsX = repmat([1:length(denvChan)],2,1)./denvFs.*wvfFs;
	  %  denvPointsY = denvChan + yMin;
	  %  plot(denvPointsX,denvPointsY,'k');
	    

	 case 'mid'
	  
	  
	end	  
	  
      
	wvfPlotNum = wvfPlotNum + 1;
      else

	yMax = 1;
      end
    end
 
    set(gca,'xlim',xlimAx*wvfFs);
    set(gca,'ylim',[0 yMax]);
    set(gca,'xtick',[]);
    set(gca,'xticklabel',[]);
    set(gca,'ytick',[]);
    set(gca,'yticklabel',[]);
    set(gca,'ydir','reverse');
    
    params.legendParams.Fs = wvfFs;
    if(isfield(params,'freqLegend') & params.freqLegend)
      plotLegend(inputGraphH,params.legendParams);
    end
  end
  
  if(isfield(params,'savePlot') & params.savePlot)
    disp(sprintf('Writing new plots to %s\n\n', ...
		 fullfile(params.savePath,params.plotFname)));
    pfname = [fstub '_rOut_' ext];
    print('-dpsc','-append',fullfile(params.savePath,pfname));
    close(fig1);
  end
end

if(~isempty(intersect({'resonEnergy','meanEnergy'},params.perform)))

  clear fparams;
  fparams.plotTitle = params.plotTitle;

  if(length(intersect({'resonEnergy','meanEnergy'},params.perform)) == 2)
    fparams.axLocs = {'rectPlot_top','rectPlot_bottom'};
    [fig2,ax] = rhythmTap_figure(fparams);
    ax1 = get_axhandle(ax,'rectPlot_top');
    ax2 = get_axhandle(ax,'rectPlot_bottom');
  elseif(ismember('resonEnergy',params.perform))
    fparams.axLocs = {'rectPlot_top'};
    [fig2,ax] = rhythmTap_figure(fparams);
    ax1 = get_axhandle(ax,'rectPlot_top');
  else
    fparams.axLocs = {'rectPlot_top'};
    [fig2,ax] = rhythmTap_figure(fparams);
    ax2 = get_axhandle(ax,'rectPlot_top');
  end
  resEnergy = thisRP.data{thisRPCols.resonatorEnergy};
  meanEnergy = thisRP.data{thisRPCols.meanResonatorEnergy};
  minMeanEnergy = min(meanEnergy);
  maxMeanEnergy = max(meanEnergy);
  energyMaxVal = max(resEnergy(:));
  resonFreqLabel = num2str(resonFreqs(resonFreqTick),'%.2f');

end
  
if(ismember('resonEnergy',params.perform))

  nTimeSamps = size(resEnergy,2);
  timeVector = [0:nTimeSamps-1]./Fs;
  timeTick = [0:params.timeTickRes:timeVector(end)];
    
  axes(ax1);
  imagesc(timeVector,resIdxVector,resEnergy);
  colormap(hot);
  
  if(isfield(params,'resEnergy') && isfield(params.resEnergy,'clim'))
    setClim = params.resEnergy.clim;
  else
    setClim = [minMeanEnergy energyMaxVal];
  end
  
  set(ax1,'clim',setClim);
  set(ax1,'Xtick',timeTick);
  set(ax1,'Ytick',resonFreqTick);
  set(ax1,'YtickLabel',resonFreqLabel);
  set(ax1,'YLim',[freqMin freqMax]);
 
  if(isfield(params,'colorbar') & params.colorbar)
    colorbar;
  end
end

if(ismember('meanEnergy',params.perform))
  
  %axes('position',[0.13 0.10 0.775 0.34]);
  axes(ax2);
  
  if(ismember('stdEnergy',params.perform))
    stdEnergy = thisRP.data{thisRPCols.stdResonatorEnergy};
    errorbar(meanEnergy,stdEnergy,'color',[0 .8 0]);
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
  set(ax2,'ylim',ylim);
  set(ax2,'xlim',[freqMin freqMax]);
  set(ax2,'xtick',resonFreqTick);
  set(ax2,'xtickLabel',resonFreqLabel);
  
  if(ismember('findPeaks',params.perform))
    params.peakFinder.Fs = Fs;
    peakIdxs = find_peaks(meanEnergy,params.peakFinder);
    peakFreqs = resonFreqs(peakIdxs);
    maxPeakEnergyFreq = resonFreqs(find(meanEnergy == max(meanEnergy(peakIdxs))));
    normPeakFreqs = peakFreqs ./ maxPeakEnergyFreq;
    widths = get_rp_peakWidths('rpEnergy',meanEnergy,'peakFreqs',peakFreqs,'resonFreqs',resonFreqs)';
    
    
    nPeakFreqs = length(peakFreqs);
    for(pRowStart = 1:5:nPeakFreqs)
      pRows = pRowStart:min(pRowStart+4,nPeakFreqs);
      peakFindHeader = sprintf('Peak   Norm   Width\n');
      peakFindText = [peakFindHeader sprintf('%0.2f%8.2f%9.2f\n', ...
					     [peakFreqs(pRows) normPeakFreqs(pRows) widths(pRows)]')];
      axLeft = 0.13 + 0.5*(floor(pRowStart/5));
      peakInfoAxes = axes('position',[axLeft 0.81 0.4 0.1],'visible','off');
      t = text(0,1,peakFindText,'VerticalAlignment','top');
      
    end
  
  end
  

end

if(~isempty(intersect({'resonEnergy','meanEnergy'},params.perform)))
  if(isfield(params,'savePlot') & params.savePlot)
    disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,params.plotFname)));
    pfname = [fstub '_rEnergy' ext];
    print('-dpsc','-append',fullfile(params.savePath,pfname));
    close(fig2);
  end
end



if(ismember('plotBands',params.perform))

  rOut3D = thisRP.data{thisRPCols.resonatorOut};
  nBands = size(rOut3D,1);
  
  meanChannelCBU = thisRP.data{thisRPCols.meanChannelCBU};
  
  %used for setting clims
  climVal = max(max(sqrt(sum(rOut3D.^2,3)./size(rOut3D,3))));
  
  for iBand = 1:nBands
    
    if(mod((iBand -1),10) == 0)
      figh = figure;
      set(figh,'units','inches');
      set(figh,'position',[1 1 8 10.5]); 
      set(figh,'paperposition',[0.25 0.25 8 10.5]); 
      titleStr = strrep(params.plotTitle,'_','\_');
      axes('position',[0.5 0.95 0.1 0.02],'visible','off');
      txt_h = text(0.5,0.5,titleStr);
      set(txt_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14);
    end
    
    if(nBands <= 5)
      subplot(5,1,mod((iBand-1),10)+1);
    else
      subplot(5,2,mod((iBand-1),10)+1);
    end
    
    imagesc(timeVector,resIdxVector,squeeze(rOut3D(iBand,:,:)));
  
    if(~isempty(meanChannelCBU))
        ylabel(sprintf('%.2f CBU',meanChannelCBU(iBand)),'rotation',0,'HorizontalAlignment','right');
    end
    
    colormap(new_seismic);
    
    set(gca,'clim',[-climVal climVal]);
    set(gca,'Xtick',timeTick);
    set(gca,'Ytick',resonFreqTick);
    set(gca,'XtickLabel',[]);
    set(gca,'YtickLabel',[]);
    set(gca,'YLim',[freqMin freqMax]);
  
    if(isfield(params,'savePlot') & params.savePlot & ((mod(iBand,10) == 0) | (iBand == nBands)))
      if(nBands > 10)
	[p,fnamestub ext] = fileparts(params.plotFname);
	saveToFname = [fnamestub '_bandOutputs' ext];
      else
	saveToFname = params.plotFname;
      end
      
      disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,saveToFname)));
      print('-dpsc','-append',fullfile(params.savePath,saveToFname));
      close(figh);
    end
    
  end
  
end

if(ismember('plotBandEnergies',params.perform))
   
  meanChannelCBU = thisRP.data{thisRPCols.meanChannelCBU};
  nBands = size(thisRP.data{thisRPCols.resonatorBandEnergy},1);
  maxRBEnergy = max(abs(thisRP.data{thisRPCols.resonatorBandEnergy}(:)));
  
  climMin = min(min(mean(thisRP.data{thisRPCols.resonatorBandEnergy},3)));
  climMax = max(max(mean(thisRP.data{thisRPCols.resonatorBandEnergy},3)));

  for iBand = 1:nBands
    
    if(mod((iBand -1),10) == 0)
      figh = figure;
      set(figh,'units','inches');
      set(figh,'position',[1 1 8 10.5]); 
      set(figh,'paperposition',[0.25 0.25 8 10.5]); 
      titleStr = strrep(params.plotTitle,'_','\_');
      axes('position',[0.5 0.95 0.1 0.02],'visible','off');
      txt_h = text(0.5,0.5,titleStr);
      set(txt_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14);
    end
     
    if(nBands <= 5)
      subplot(5,1,mod((iBand-1),10)+1);
    else
      subplot(5,2,mod((iBand-1),10)+1);
    end 
      
    imagesc(timeVector,resIdxVector,squeeze(thisRP.data{thisRPCols.resonatorBandEnergy}(iBand,:,:)));

    if(~isempty(meanChannelCBU))
        ylabel(sprintf('%.2f CBU',meanChannelCBU(iBand)),'rotation',0,'HorizontalAlignment','right');
    end

    colormap(hot);
        
    set(gca,'clim',[climMin climMax]);
    set(gca,'Xtick',timeTick);
    set(gca,'Ytick',resonFreqTick);
    set(gca,'XtickLabel',[]);
    set(gca,'YtickLabel',[]);
    set(gca,'YLim',[freqMin freqMax]);
  
    if(isfield(params,'savePlot') & params.savePlot & ((mod(iBand,10) == 0) | (iBand == nBands)))
     if(nBands > 10)
	[p,fnamestub ext] = fileparts(params.plotFname);
	saveToFname = [fnamestub '_bandEnergies' ext];
     else
	saveToFname = params.plotFname;
     end
     disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,saveToFname)));
     print('-dpsc','-append',fullfile(params.savePath,saveToFname));
     close(figh);
    end
    
  end
  
end %if plotBandEnergies







return


function plotLegend(ax_h,params)

plotPos = get(ax_h,'position');
axWidth = plotPos(3);
axXlim = get(ax_h,'xlim');
widthPerSec = axWidth./(axXlim(2) - axXlim(1)).*params.Fs;
keyXPos = .06;
spacerHeight = .005;
numKeys = params.numKeys;
maxPeriod = 1./params.minHz;
keyWidth = widthPerSec*maxPeriod;
keyHeight = .01;

for iKey = 1:numKeys 
  keyYPos = plotPos(2)+plotPos(4) - (keyHeight)*iKey - spacerHeight*(iKey-1);
  legax = axes('position',[keyXPos keyYPos keyWidth keyHeight]);
  
  thisHz = (params.maxHz - params.minHz)./(numKeys).*(iKey -1) + params.minHz;
  thisPeriod = 1./thisHz;
  plot(repmat([0 thisPeriod],2,1),[0 0 ;1 1],'k');
  set(legax,'visible','off','xlim',[0 1]);
  
  textAx = axes('position',[.005 keyYPos .02 .02],'xlim',[0 1],'ylim',[0 1],'visible','off');
  text(0,0,[num2str(thisHz,'%.2f') 'Hz'],'fontsize',8);
  
end


return
