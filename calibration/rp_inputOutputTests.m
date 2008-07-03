
plotPath = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/calibration/iso_var_accent';

input_type = 'pulse_train';%'single_pulse';
%resonator_type = 'reson_filterQSpacing_periodBasedDecay';
resonator_type = 'comb';


if(strcmp(resonator_type,'comb'))
  gain_type = 'constant';
else
  gain_type = 'weighted_partialHanning';
end



dur = 30.0;
Fs = 100;
sigFreq = 1; 
sigLen = round(dur*Fs);

switch input_type

 case 'pulse_train'
  pulsePeriod = 1./sigFreq;
  pulsePeriodSamps = round(pulsePeriod*Fs);
  
  sig = zeros(sigLen,1);
  
  onsetTimesSamps = [1:pulsePeriodSamps:sigLen];
  sig(onsetTimesSamps) = 1;
  
 case 'sine'
  
  sig = sin([1:sigLen].*sigFreq./Fs.*2.*pi)';
  
 case 'single_pulse'
  
  sig = [1;  zeros(sigLen-1,1)];
  
end

aud_st = init_aud('Fs',Fs,'nchan',1,'wvf',sig);

%process the aud_st through ipem_proc_series
params{1}.glob.process = {'rp'};
params{1}.glob.force_recalc = params{1}.glob.process;
params{1}.glob.save_calc = {};
params{1}.ani = ani_paramGroups;
params{1}.rp = rp_paramGroups('param_group',...
			      resonator_type,...
			      'input_type','aud','gain_type',gain_type,...
			      'perform_mulawCompression',0);

ipemOut = ipem_proc_series(aud_st,params{1});
ipemOutCols = set_var_col_const(ipemOut.vars);
rp = ipemOut.data{ipemOutCols.rp};

params{2}.perform = {'resonOutput','resonEnergy','meanEnergy','stdEnergy','findPeaks','showInput'};
params{2}.freqLegend = 1;
params{2}.legendParams.minHz = 1;
params{2}.legendParams.maxHz = 5;
params{2}.legendParams.numKeys = 8;
params{2}.colorbar = 1;
params{2}.savePath = plotPath;
params{2}.timeTickRes = 2.0;
params{2}.numResonTicks = 15;
params{2}.maxResonFreqPlot = 10;
params{2}.inputSigType = 'impulse';
%params{2}.inputSigType = 'wvf';
params{2}.plotMeans = 1;
params{2}.color = 1;
params{2}.savePlot = 0;
params{2}.separatePages = 1;
params{2}.peakFinder.thresh = 0.1;
params{2}.peakFinder.perform = {};
params{2}.resonOut.clim = [-1 1]*10^-3;
%params{2}.resEnergy.clim = [0 5]*10^-3;
%params{2}.meanEnergy.ylim = [0 5]*10^-3;

params{2}.meanEnergy.numticks = 4;
params{2}.meanEnergy.yTickLabelFmt = '%.3f';

title = sprintf('%s_%s',input_type,resonator_type);

params{2}.fig.title = title;

params{2}.plotFname = [title '.ps'];

inData{1} = rp{1};
inData{2} = aud_st;

plot_rhythmProfile(inData,params{2});


