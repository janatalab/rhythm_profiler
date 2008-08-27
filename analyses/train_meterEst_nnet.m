globals = train_meterEst_globals; 

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
an{na}.params.variances = globals.input.variances;
an{na}.params.varianceQuant = globals.input.varianceQuant;
an{na}.params.classes = globals.input.classes;
an{na}.params.plotPatterns = 0;


na=na+1;
an{na}.name = 'ipem_proc_series';
an{na}.fun = @ipem_proc_series;
an{na}.params = globals.ipemProcParams;
an{na}.requires = {struct('name','gen_accent_impulses','vars','aud')};

params = [];
params.run_analyses = [1 2];
an = ensemble_jobman(an,params);
return
