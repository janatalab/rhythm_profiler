%test script for beat algorithm
clear params;
PLOT_AUD_METRIC_SURFACE = 0;
PLOT_MOV_METRIC_SURFACE = 1;


%directory with files to analyze
rp_test_dir = '/afs/cmb.ucdavis.edu/share/petrlab/motion_capture/metric_surfaces/js_kneesalternating';

wavDirStruct = dir(fullfile(rp_test_dir,'*.wav'));
wavFnames = {wavDirStruct.name};
wavflist = check_stim_dirs(wavFnames,'srcroot',rp_test_dir,'destroot',rp_test_dir);

matDirStruct = dir(fullfile(rp_test_dir,'*.mat'));
matFnames = {matDirStruct.name};
matflist = check_stim_dirs(matFnames,'srcroot',rp_test_dir,'destroot',rp_test_dir);

%PLOTTING METRIC SURFACES FOR AUDIO DATA
if(PLOT_AUD_METRIC_SURFACE)
  params{1}.ipem.glob.process = {'ani','rp'};
  params{1}.ipem.glob.force_recalc = {};
  params{1}.ipem.glob.save_calc = params{1}.ipem.glob.process;
  params{1}.ipem.ani = ani_paramGroups;
  params{1}.ipem.rp = rp_paramGroups('param_group',...
				     'reson_filterQSpacing_periodBasedDecay',...
				     'input_type','ani','gain_type','weighted_partialHanning',...
				     'perform_mulawCompression',0);
  
  %params{1}.plot.meanROutYlim = [0 0.06];
  %params{1}.plot.meanREnergyYlim = [0 0.8];
  %params{1}.plot.resonOutClim = [-0.1 0.1];
  %params{1}.plot.resonEnergyClim = [0 0.9];
  %params{1}.plot.meanROutYlim = [0 1.6];
  %params{1}.plot.meanREnergyYlim = [0 22];
  %params{1}.plot.resonOutClim = [-1.6 1.6];
  %params{1}.plot.resonEnergyClim = [0 22];
  params{1}.plot.bands.climMode = 'scaledAcrossBands';
  params{1}.plot.freqLegend = 1;
  params{1}.plot.legendParams.minHz = 1;
  params{1}.plot.legendParams.maxHz = 5;
  params{1}.plot.legendParams.numKeys = 8;
  params{1}.plot.colorbar = 1;
  params{1}.plot.savePath = rp_test_dir;
  params{1}.plot.timeTickRes = 2.0;
  params{1}.plot.numResonTicks = 15;
  params{1}.plot.maxResonFreqPlot = 10;
  params{1}.plot.peakFinder.thresh = 0.25;
  params{1}.plot.plotMeans = 1;
  params{1}.plot.savePlot = 1;
  params{1}.plot.perform = {'resonOutput','plotBandEnergies','resonEnergy','meanEnergy','stdEnergy','findPeaks'};
  params{1}.plot.plotFname = 'audio_metric_surface.ps';
  
  plot_dir_rhythm_profile(wavflist,params{1});
end



%PLOTTING METRIC SURFACES FOR MOTION DATA
if(PLOT_MOV_METRIC_SURFACE)
  params{2}.ipem.glob.process = {'rp'};
  params{2}.ipem.glob.force_recalc = {};
  params{2}.ipem.glob.save_calc = params{2}.ipem.glob.process;
  params{2}.ipem.rp = rp_paramGroups('param_group',...
				     'reson_filterQSpacing_periodBasedDecay',...
				     'input_type','mat','gain_type','weighted_partialHanning',...
				     'perform_mulawCompression',0,'matTranspose',1,'matVarName','components');
  %params{2}.plot.meanROutYlim = [0 0.06];
  %params{2}.plot.meanREnergyYlim = [0 0.8];
  %params{2}.plot.resonOutClim = [-0.1 0.1];
  %params{2}.plot.resonEnergyClim = [0 0.9];
  %params{2}.plot.meanROutYlim = [0 1.6];
  %params{2}.plot.meanREnergyYlim = [0 22];
  %params{2}.plot.resonOutClim = [-1.6 1.6];
  %params{2}.plot.resonEnergyClim = [0 22];
  params{2}.plot.bands.climMode = 'meanAcrossBands';%'scaledAcrossBands';%'scaledPerBand';
  params{2}.plot.freqLegend = 1;
  params{2}.plot.legendParams.minHz = 1;
  params{2}.plot.legendParams.maxHz = 5;
  params{2}.plot.legendParams.numKeys = 8;
  params{2}.plot.colorbar = 1;
  params{2}.plot.savePath = rp_test_dir;
  params{2}.plot.timeTickRes = 2.0;
  params{2}.plot.numResonTicks = 15;
  params{2}.plot.maxResonFreqPlot = 10;
  params{2}.plot.peakFinder.thresh = 0.25;
  params{2}.plot.plotMeans = 1;
  params{2}.plot.savePlot = 1;
  params{2}.plot.perform = {'plotBandEnergies','resonEnergy','meanEnergy','stdEnergy','findPeaks'};
  params{2}.plot.plotFname = 'motion_metric_surface_climMeanAcrossBands.ps';
  
  plot_dir_rhythm_profile(matflist,params{2});
end


