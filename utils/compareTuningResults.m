PLOT_PERF_VS_TEMPI = 0;

firstModel = load('contest_evaluation_ballroom_and_songs_beta_1.75_4.5.mat');
secondModel = load('contest_evaluation_ballroom_and_songs_more_filters_beta_gain.mat');

plotPath = '/home/petr/data/rhythm/rhythm_profiler/tempo_induction_competition/plots';

bothCorrectAcc2 = ((firstModel.withinToleranceMask2) & (secondModel.withinToleranceMask2));
firstModelCorrectAcc2  = ((firstModel.withinToleranceMask2) & ~(secondModel.withinToleranceMask2));
secondModelCorrectAcc2 = (~(firstModel.withinToleranceMask2) & (secondModel.withinToleranceMask2));

firstModelEstTempi = firstModel.peakVals;
secondModelEstTempi = secondModel.peakVals;

annotatedTempos = firstModel.annotatedTempos;

if(PLOT_PERF_VS_TEMPI)
  figure;
  plot(annotatedTempos*60,log2(firstModelEstTempi./annotatedTempos),'m*');
  hold on;
  plot(annotatedTempos*60,log2(secondModelEstTempi./annotatedTempos),'b*');
  title(['Ratio between estimated tempo and correct tempo vs. tempo' ...
	 ' value'],'FontSize',12,'FontWeight','Bold');
  xlabel('Correct tempo');
  ylabel('log2(computed tempo/correct tempo)');
  
end

idxsSecondModelCorrect = find(secondModelCorrectAcc2);
processFileList = secondModel.comparison_matrix(idxsSecondModelCorrect,1);
processFileList = processFileList(1:20);

plotParams.ipem.glob.process = {'ani','rp'};
plotParams.ipem.glob.force_recalc = {};
plotParams.ipem.glob.save_calc = {'rp'};
plotParams.ipem.ani  = ani_paramGroups;
plotParams.ipem.ani.normalize_maxVal = 0.9;
plotParams.ipem.rp = rp_paramGroups('param_group',...
				    'reson_filterQSpacing_periodBasedDecay',...
				    'input_type','ani','gain_type','beta_distribution',...
				    'perform_mulawCompression',0);
plotParams.ipem.rp.resonatorBank.spacingFactor = 0.5; %0.125;
plotParams.n2a_params.timingColumn = 'onset_beats';
plotParams.n2a_params.beatsPerSec = 2;
plotParams.separatePlotFiles = 0;
plotParams.plot.freqLegend = 1;
plotParams.plot.legendParams.minHz = 1.5;
plotParams.plot.legendParams.maxHz = 5;
plotParams.plot.legendParams.numKeys = 7;
plotParams.plot.colorbar = 1;
plotParams.plot.savePath = plotPath;
plotParams.plot.timeTickRes = 2.0;
plotParams.plot.numResonTicks = 15;
plotParams.plot.maxResonFreqPlot = 10;
plotParams.plot.plotMeans = 1;
plotParams.plot.color = 0;
plotParams.plot.separatePages = 0;
plotParams.plot.savePlot = 1;
plotParams.plot.showInput = 0;
plotParams.plot.inputSigType = 'impulse';
plotParams.plot.peakFinder.thresh = 0.25;
plotParams.plot.peakFinder.perform = {};
plotParams.plot.meanEnergy.numticks = 4;
plotParams.plot.perform = {'resonEnergy','meanEnergy','stdEnergy','findPeaks'};
plotParams.plot.plotFname = 'rp_plots_firstModel_1.75_4.5.ps';
plot_dir_rhythm_profile(processFileList,plotParams);
