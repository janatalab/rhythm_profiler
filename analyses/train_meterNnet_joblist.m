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
an{na}.params.savePath = globals.input.savePath;


na=na+1;
an{na}.name = 'ipem_proc_series';
an{na}.fun = @ipem_proc_series;
an{na}.params = globals.ipemProcParams;
an{na}.requires = {struct('name','gen_accent_impulses','vars','audFileList')};

na=na+1;
an{na}.name = 'train_meterEstimator';
an{na}.fun = @train_meterEstimator;
an{na}.requires = {struct('name','ipem_proc_series'),struct('name','gen_accent_impulses')};
an{na}.params.nnet.percentTrain = globals.nnet.percentTrain;
an{na}.params.nnet.adaptFcn = globals.nnet.adaptFcn;
an{na}.params.nnet.trainParams.epochs = globals.nnet.trainParams.epochs;
an{na}.params.nnet.trainParams.show = globals.nnet.trainParams.show;




params = [];
params.run_analyses = [3];
an = ensemble_jobman(an,params);
return
