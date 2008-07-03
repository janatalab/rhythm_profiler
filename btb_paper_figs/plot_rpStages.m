% a quick and dirty script to plot various stages of RP processing,

SAVEPLOT = 1;
FMT = '-dpsc';
plotDir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/rpStages';
close all

figprops = {'fontsize',12,'fontweight','bold'};

max_sec = 30;
xLimSec = [0 max_sec];
tTickSec = [0:2:max_sec];
nResonTicks = 12;

screenSize = get(0,'screensize');
screenSize = screenSize(3:4);

%figure and axes dimensions
chanFigSize = [800 400];
chanAxSize = [0.775 .15];
chanAxLPos = .13;
imgFigSize = [800 600];
imgAxSize = [.775 .8150];


if(~exist('ipemProc','var'))
  stimulusID = 8;
  stimMeta = mysql_extract_metadata('table','stimulus','stimulus_id',stimulusID);
  artist = stimMeta.artist;
  song_name = stimMeta.name;
  fstub = sprintf('stimID%d',stimulusID);

  ipem_params.glob.process = {'ani','rp'};
  ipem_params.glob.force_recalc = {};
  ipem_params.glob.save_calc = {};
  ipem_params.ani = ani_paramGroups;
  ipem_params.rp = rp_paramGroups('param_group',...
				  'reson_filterQSpacing_periodBasedDecay',...
				  'input_type','ani','gain_type','weighted_partialHanning',...
				  'perform_mulawCompression',0);
  ipemProc = ipem_proc_series(stimulusID,ipem_params);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
  rpCols = set_var_col_const(rp.vars);
  ani = ipemProc.data{ipemProcCols.ani}{1};
  aniCols = set_var_col_const(ani.vars);
end

%ANI AND RMS PLOTS
plot_chans = [4 10 30];
nChan = length(plot_chans);
plotTag = {'ani','rms'};
for iPlot = 1:2
  plotSig = plotTag{iPlot};
  
  switch(char(plotSig))
   case 'ani'
    sig = ani.data{aniCols.sig};
    Fs = ani.data{aniCols.Fs};
 
   case 'rms'
    sig = rp.data{rpCols.rms};
    Fs = rp.data{rpCols.Fs};
  end
  
  figure(iPlot);
  set(iPlot,'position',[ 100 100 chanFigSize]);

  clear anAx;
  for(iChan = 1:nChan)
    chan_idx = plot_chans(iChan);
    anAx(iChan) = axes('position',[chanAxLPos 1-.8*iChan/nChan chanAxSize]);
    plot(sig(chan_idx,:),'k');
    title(sprintf('Channel %d, CF= %d Hz', chan_idx, ...
	ani.data{aniCols.filterFreqs}(chan_idx)), 'fontsize', 14)
    
    if iChan == nChan
      xlabel('Time (s)',figprops{:});
    end
    
    if iChan == 1
      title_axes = axes('position',[0,0.95, 1, 0.05], 'units','norm');
      axis off
      switch plotTag{iPlot}
	case 'ani'
	  title_str = sprintf('Auditory nerve images in %d frequency bands', nChan);
	case 'rms'
	  title_str = 'Root mean square (RMS) of auditory nerve image activity';
      end
      text(0.5, 0.5, title_str, 'units','norm','horizontalalign','center', ...
	  'verticalalign','middle', 'fontsize', 18)
    end
  end
  
  set(anAx,'xtick',[],'ytick',[],figprops{:});
%  anAx(end+1) = axes('position',[chanAxLPos .15 chanAxSize ]);
%  plot(sig(40,:));
  set(anAx(:),'xtick',round(tTickSec*Fs));
  set(anAx(end),'xticklabel',tTickSec);
  set(anAx(1:end-1),'xticklabel',[]);
  set(anAx(end),'ytick',[]);
  
  set(anAx,'xlim',xLimSec*Fs);
  ylim = [min(min(sig(plot_chans,:))) ...
	  max(max(sig(plot_chans,:)))];
  set(anAx,'ylim',ylim);
  set(anAx,figprops{:});

  if(SAVEPLOT)
    print(FMT,fullfile(plotDir,['fig' num2str(iPlot) '_' fstub '_' char(plotSig)]));
  end
  
end

%%%DENV

iPlot = 3;
figure(iPlot);
set(iPlot,'position',[100 100 chanFigSize]);
sig = rp.data{rpCols.sumDenv};
ssig = size(sig);
nChan = 5;
for(iChan = 1:nChan)
  dax(iChan) = axes('position',[chanAxLPos .8 - (.88-.1)*(iChan-1)/nChan chanAxSize]);
  plot(sig(iChan,:),'k');  
  start_freq = ...
      ani.data{aniCols.filterFreqs}((iChan-1)*rp.data{rpCols.params}.rp.sumAdjacentBands+1);
  stop_freq = ...
 ...
ani.data{aniCols.filterFreqs}(iChan*rp.data{rpCols.params}.rp.sumAdjacentBands);

  label_str = sprintf('%d-%d Hz', start_freq, stop_freq);
  % ylabel(label_str)
  text(0.98, 0.98, label_str, 'units','norm', ...
      'horizontalalign','right','verticalalign','top', ...
      'fontweight','bold')
  
  if iChan == 1
    title('Rectified 1st-derivative of RMS waveforms','fontsize',18)
  end
end

set(dax,'ylim',[min(sig(:)) max(sig(:))]);
set(dax,'xlim',xLimSec*Fs);
set(dax,'ytick',[]);
set(dax,'xtick',[]);
set(dax(:),'xtick',round(tTickSec*Fs));
set(dax(end),'xticklabel',tTickSec);
set(dax(1:end-1),'xticklabel',[]);
xlabel('Time (s)',figprops{:});
set(dax,figprops{:});

if(SAVEPLOT)
  print(FMT,fullfile(plotDir,['fig' num2str(iPlot) '_' fstub '_denv']),'-adobecset');
end
  
%RESON OUT PLOTS

%calculating mean energy here to find the peak reson filter
rEnergy = rp.data{rpCols.resonatorEnergy};
meanEnergy = mean(rEnergy,2);
maxEnergyIdx =find(meanEnergy ==  max(meanEnergy));
rOut = rp.data{rpCols.resonatorOut};
resonFreqs = rp.data{rpCols.resonatorFreqs};
nResons = length(resonFreqs);
resonTicks = [1:round(nResons/nResonTicks):nResons];
resonTickLabels = num2str(resonFreqs(resonTicks),'%0.2f|');


%plotting image of all reson filter outputs
iPlot = 4;
fh_rout = figure(iPlot);
set(iPlot,'position',[100 100  imgFigSize]);
rpax(2) = axes;
imagesc(squeeze(rOut(3,:,:)));
load new_seismic;
colormap(new_seismic);

colorbar

title('Reson filter outputs', 'fontsize', 18)
set(gca,'plotboxAspectRatio',[4 3 1])

%plotting reson filter with max energy output
iPlot = 5;
band = 3;
fh_rchan = figure(iPlot);
set(iPlot,'position',[100 100 chanFigSize(1) chanFigSize(2)/3]);
rpax(1) = axes('position',[chanAxLPos .32 chanAxSize(1) chanAxSize(2)*3]);

plot(squeeze(rOut(band,maxEnergyIdx,:)),'k');

set(rpax,'xlim',xLimSec*Fs);
set(rpax,'xtick',tTickSec*Fs);
set(rpax,'xticklabel',tTickSec);
set(rpax,figprops{:});
set(rpax(1),'ytick',[]);
set(rpax(2),'ytick',resonTicks);
set(rpax(2),'yticklabel',resonTickLabels);

xlabel(rpax(1),'Time (s)',figprops{:});
xlabel(rpax(2),'Time (s)',figprops{:});
ylabel(rpax(2),'Resonator Frequency (Hz)',figprops{:});


if(SAVEPLOT)
  print(['-f' num2str(fh_rchan)],FMT,fullfile(plotDir,['fig' num2str(fh_rchan) ...
		    '_' fstub '_resonChan']));
  print(['-f' num2str(fh_rout)],FMT,fullfile(plotDir,['fig' num2str(fh_rout) ...
		    '_' fstub '_resonOut']));
end

%RESON ENERGY PLOT
iPlot = 6;
figure(iPlot);
set(iPlot,'position',[100 100 imgFigSize]);
reax = axes;
imagesc(rEnergy);
colormap(hot);
set(reax,figprops{:});
set(reax,'xlim',xLimSec*Fs);
set(reax,'xtick',tTickSec*Fs);
set(reax,'xticklabel',tTickSec);
set(reax,'ytick',resonTicks);
set(reax,'yticklabel',resonTickLabels);
xlabel(reax,'Time (s)',figprops{:});
ylabel(reax,'Resonator Frequency (Hz)',figprops{:});
set(gca,'plotboxAspectRatio',[4 3 1])

set(gca,'clim',[min(meanEnergy) max(meanEnergy)])

colorbar

if(SAVEPLOT)
  print(FMT,fullfile(plotDir,['fig' num2str(iPlot) '_' fstub '_rEnergy']));
end

%MEAN RESON ENERGY
iPlot = 7;
figure(iPlot);
set(iPlot,'position',[100 100 imgFigSize]);
mreax = axes;
plot(meanEnergy,'linewidth',2,'k');
set(mreax,figprops{:});
set(mreax,'xtick',resonTicks);
set(mreax,'xticklabel',resonTickLabels);
%set(mreax,'ytick',[]);
xlabel(mreax,'Resonator Frequency (Hz)',figprops{:});

title('Mean Resonator Output Energy','fontsize',18)
set(gca,'plotboxAspectRatio',[3 1 1])

if(SAVEPLOT)
  print(FMT,fullfile(plotDir,['fig' num2str(iPlot) '_' fstub '_meanREnergy']));
end
