function globals = train_meterNnet_globals;

globals.input.barFreq = .6;
globals.input.dur = 30;
globals.input.Fs = 300;
globals.input.gaussFWHMms = 10;
globals.input.accentPatterns = {[1 .33 .66 .33 .66 .33 ],...
		    [1 .25 .5 .25 .75 .25 .5 .25],...
		    [1 .33 .33 .66 .33 .33],...
		    [1 .66 1 .66 .66] };
globals.input.varianceMethod = 'random';
globals.input.variances = [.12 .10 .12 .12];
globals.input.varianceQuant = 3;
globals.input.exemplarsPerClass = 100;
globals.input.classes = {'meter = 3/4','meter = 4/4','meter = 6/8','alternate23'};
globals.input.savePath = '/data2/rhythm/rhythm_profiler/meter_est/exemplars';

globals.ipemProcParams.glob.process = {'rp'};
globals.ipemProcParams.glob.force_recalc = {};
globals.ipemProcParams.glob.save_calc = {'rp'};
globals.ipemProcParams.glob.process = {'rp'};
globals.ipemProcParams.glob.insigFs = globals.input.Fs;
globals.ipemProcParams.glob.matVarName = 'aud_st';
globals.ipemProcParams.glob.outputType = 'filepath';
globals.ipemProcParams.rp = rp_paramGroups('param_group',...
				   'reson_filterQSpacing_periodBasedDecay',...
				   'input_type','aud','gain_type','beta_distribution',...
				   'perform_mulawCompression',0);


globals.nnet.adaptFcn = 'trainc';
globals.nnet.trainParams.epochs = 300;
globals.nnet.trainParams.show = 25;
globals.nnet.percentTrain = 0.80;
