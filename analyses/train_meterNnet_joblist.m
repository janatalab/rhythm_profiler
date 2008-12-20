globals = train_meterNnet_globals; 

%if(~exist('an','var'))
  %load(fullfile(globals.paths.datapath,''),'an');
%end

% Create an array of analysis structures
%clear an;
na = 0;

na=na+1;
an{na}.name = 'gen_accent_impulses';
an{na}.fun  = @gen_accent_impulses;
an{na}.params.barFreq = globals.input.barFreq;
an{na}.params.dur = globals.input.dur;
an{na}.params.Fs = globals.input.Fs;
an{na}.params.gaussFWHMms = globals.input.gaussFWHMms;
an{na}.params.accentPatterns = globals.input.accentPatterns;
an{na}.params.varianceMethod = 'random'; %'quant'
an{na}.params.variances = globals.input.variances;
an{na}.params.varianceQuant = globals.input.varianceQuant;
an{na}.params.exemplarsPerClass = globals.input.exemplarsPerClass;
an{na}.params.classes = globals.input.classes;
an{na}.params.plotPatterns = 1;
an{na}.params.savePath = globals.paths.dataPath;

na=na+1;
an{na}.name = 'ipem_proc_series';
an{na}.fun = @ipem_proc_series;
an{na}.requires = {struct('name','gen_accent_impulses','vars','audFileList')};
an{na}.params = globals.ipemProcParams;
an{na}.params.plot.process = {'rp'};
an{na}.params.plot.rp.peakFinder.ratioVals = an{na}.params.rp.resonatorBank.peakFinder.ratioVals;
an{na}.params.plot.rp.peakFinder.ratioLabels = an{na}.params.rp.resonatorBank.peakFinder.ratioLabels;
an{na}.params.plot.rp.freqLegend = 0;
an{na}.params.plot.rp.inputSigType = 'wvf';
an{na}.params.plot.rp.perform = {'resonEnergy','meanEnergy','stdEnergy','findPeaks','plotMeanEnergy','showInput','ratioProb'};
an{na}.params.plot.rp.colorbar = 1;
an{na}.params.plot.rp.color = 0;
an{na}.params.plot.rp.separatePages = 0;
an{na}.params.plot.rp.savePlot = 1;
an{na}.params.plot.rp.savePath = globals.paths.plotPath;
an{na}.params.plot.rp.timeTickRes = 2.0;
an{na}.params.plot.rp.xminortick = 'off';
an{na}.params.plot.rp.numResonTicks = 8;
an{na}.params.plot.rp.meanEnergy.numticks = 4;
an{na}.params.plot.rp.plotFname = 'meter_exemplar_plots';
an{na}.params.plot.addInputFname = 1;

na=na+1;
an{na}.name = 'train_meterEstimator';
an{na}.fun = @train_meterEstimator;
an{na}.requires = {struct('name','ipem_proc_series'),struct('name','gen_accent_impulses')};
an{na}.params.perform = {}; %{'plotFailedTests'};
an{na}.params.nnet.percentTrain = globals.nnet.percentTrain;
an{na}.params.nnet.adaptFcn = globals.nnet.adaptFcn;
an{na}.params.nnet.trainParams.epochs = globals.nnet.trainParams.epochs;
an{na}.params.nnet.trainParams.show = globals.nnet.trainParams.show;
an{na}.params.nnet.nRuns = globals.nnet.nRuns;
an{na}.params.ratioLabels = globals.ipemProcParams.rp.resonatorBank.peakFinder.ratioLabels;
an{na}.params.plot = an{2}.params.plot.rp;
an{na}.params.plot.plotFname = 'meter_exemplar_failed_tests';

na=na+1;
an{na}.name = 'plot_exemplarPeakRatioStats';
an{na}.fun = @plot_exemplarPeakRatioStats;
an{na}.requires = {struct('name','ipem_proc_series'),struct('name','gen_accent_impulses')};
an{na}.params.ratioLabels = globals.ipemProcParams.rp.resonatorBank.peakFinder.ratioLabels;
an{na}.params.plotPath = globals.plotExemplarRatios.plotPath;
an{na}.params.plotFname = globals.plotExemplarRatios.plotFname;

params = [];
params.run_analyses = [3];
an = ensemble_jobman(an,params);
return
