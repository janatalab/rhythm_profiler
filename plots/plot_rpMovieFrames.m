function plot_rpMovieFrames(inData,params)
%
%
% plots rp movie frames to a specified directory for a given RP.
% If mutiple RP movies are desired, a wrapper function or script
% should call this function.
% Currently, the movie produced is just RP Energy with a playhead
% that scrolls from left to right. This function could be extended
% to produce other RP movies.
%
% July 22,2007 - Stefan Tomic

% savePlot param, if set to 0, allows for testing the script without
% saving the plot
clear searchCrit;
searchCrit.type = 'rhythm_profile';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimRP = inData{findIdx};
stimRPCols = set_var_col_const(stimRP.vars);

clear searchCrit;
searchCrit.type = 'aud';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
tapData = inData(findIdx);

if(~isfield(params,'savePlot'))
  params.savePlot = 1;
end

fps = params.fps;

Fs = stimRP.data{stimRPCols.Fs};
resonFreqs = stimRP.data{stimRPCols.resonatorFreqs};
nResons = length(resonFreqs);
energyMat = stimRP.data{stimRPCols.resonatorEnergy};

yticks = [5:floor((nResons-4)/params.numResonTicks):nResons];

meanEnergy = stimRP.data{stimRPCols.meanResonatorEnergy};
minMeanEnergy = min(meanEnergy);
energyMaxVal = max(energyMat(:));
durRPSamps = size(energyMat,2);
durSecs = durRPSamps/Fs;

nFrames = ceil(durSecs*fps);

figparams.figSize = 'ipod';
if(ismember('tapdata',params.process))
  figparams.axLocs = {'movie_img','movie_tapdata'};
else
  figparams.axLocs = {'movie_img'};
end
[figH,axList] = rhythmTap_figure(figparams);
figparams.fig_h = figH;
axImgH = get_axhandle(axList,'movie_img');

timeVector = [1:size(energyMat,2)]/Fs;
resIdxVector = 1:size(energyMat,1);
imagesc(timeVector,resIdxVector,energyMat,'parent',axImgH);
colormap(hot);

set(axImgH,'ytick',yticks);
img_xlim = get(axImgH,'xlim');
for iTickLabel = 1:length(yticks)
  t = text(.02*(img_xlim(2)-img_xlim(1))+img_xlim(1),yticks(iTickLabel)+2.5,...
       sprintf('%.2f',resonFreqs(yticks(iTickLabel))),...
       'color','c','verticalalignment','bottom',...
	   'fontweight','bold','fontsize',12,'parent',axImgH);
end
set(axImgH,'clim',[minMeanEnergy energyMaxVal]);
set(axImgH,'ycolor','c');
set(axImgH,'xtick',[]);

%use the following to inspect time
%set(axImgH,'xtick',[0:31],'xcolor','c');

if(ismember('tapdata',params.process))
  axTapData = get_axhandle(axList,'movie_tapdata');
  %params.tapData.axh = axTapData;
  %params.tapData.axImgH = axImgH;
  %params.tapData.axColor = [1 1 1];
  %params.tapData.lineWidth = 2;
  %plotTapData(tapData,params.tapData);
  %hold(axTapData,'on');
  params.tapData.inputSigType = 'impulse';
  params.tapData.axHList = axImgH;
  set(axImgH,'tag','rectPlot_top');
  plot_rpInput(axTapData,tapData,params.tapData);
end

hold(axImgH,'on');


lineH = [];
tapLineH = [];
for iFrame = 1:nFrames

  curTime = iFrame/fps;

  if(~isempty(lineH))
    delete(lineH);
    lineH = [];
  end
  
  if(~isempty(tapLineH))
    delete(tapLineH);
    tapLineH = [];
  end
  
  if(ismember('tapdata',params.process))
    tapLineH = plot(axTapData,[curTime curTime],[0 1],'c','LineWidth',params.lineWidth);
  end
  
  lineH = plot(axImgH,[curTime curTime],[0 nResons],'c','LineWidth',params.lineWidth);

  if(params.savePlot)
    switch(params.frameFmt)
     case 'tiff'
      fname = sprintf('frame%04d.tif',iFrame);
      print(fullfile(params.path,fname),'-dtiff','-r72');
     case 'jpeg'
      fname = sprintf('frame%04d.jpg',iFrame);
      print(fullfile(params.path,fname),'-djpeg');
    end
  end
end

delete(figH);

outData = [];
return
