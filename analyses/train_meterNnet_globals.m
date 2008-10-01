function globals = train_meterNnet_globals;

projectPath = '/data2/rhythm/rhythm_profiler/meter_est';


globals.paths.dataPath = fullfile(projectPath,'exemplars');
globals.paths.plotPath = globals.paths.dataPath;

globals.input.barFreq = [.3 .6];
%globals.input.barFreq = .45;
globals.input.dur = 30;
globals.input.Fs = 300;
globals.input.gaussFWHMms = 10;
globals.input.accentPatterns = {[1 .33 .66 .33 .66 .33 ],...
		    [1 .25 .5 .25 .75 .25 .5 .25],...
		    [1 .33 .33 .66 .33 .33],...
		    [1 .66 1 .66 .66] };
globals.input.varianceMethod = 'random';
globals.input.variances = [.1 .1 .1 .1];
%globals.input.variances = [0 0 0 0];
globals.input.varianceQuant = 3;
globals.input.exemplarsPerClass = 100;
globals.input.classes = {'meter = 3/4','meter = 4/4','meter = 6/8','alternate23'};
globals.ipemProcParams.glob.process = {'rp'};
globals.ipemProcParams.glob.force_recalc = {'rp'};
globals.ipemProcParams.glob.save_calc = {'rp'};
globals.ipemProcParams.glob.process = {'rp'};
globals.ipemProcParams.glob.insigFs = globals.input.Fs;
globals.ipemProcParams.glob.matVarName = 'aud_st';
globals.ipemProcParams.glob.outputType = 'filepath';
globals.ipemProcParams.rp = rp_paramGroups('param_group',...
				   'reson_filterQSpacing_periodBasedDecay',...
				   'input_type','aud','gain_type','beta_distribution',...
				   'perform_mulawCompression',0);
globals.ipemProcParams.rp.resonatorBank.peakFinder.minPeakHeight = 0.05;
globals.ipemProcParams.rp.resonatorBank.peakFinder.ratioVals = ...
    [ 1/8 1/6 1/5 1/4 1/3 3/8 2/5 1/2 3/5 5/8 2/3 3/4 4/5 5/6 7/8 1 5/4 4/3 ...
      3/2 5/3 2 5/2 3:8];
  
globals.ipemProcParams.rp.resonatorBank.peakFinder.ratioLabels = ...
    { '1/8' '1/6' '1/5' '1/4' '1/3' '3/8' '2/5' '1/2' '3/5' '5/8' '2/3' '3/4' ...
      '4/5' '5/6' '7/8' '1' '5/4' '4/3' '3/2' '5/3' '2' '5/2' '3' '4' '5' '6' '7' '8' };
 
globals.nnet.adaptFcn = 'trainc';
globals.nnet.trainParams.epochs = 300;
globals.nnet.trainParams.show = 25;
globals.nnet.percentTrain = 0.80;
globals.nnet.nRuns=100;

globals.plotExemplarRatios.plotPath = projectPath;
globals.plotExemplarRatios.plotFname = 'exemplarRatioHist.ps';
