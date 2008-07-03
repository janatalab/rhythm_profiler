%function comb_filter_harmonics

globals = rhythmTap_globals;

RESON_BANK_TYPE = 'reson';

params = rp_paramGroups('param_group',...
				  'reson_filterQSpacing_periodBasedDecay',...
				  'input_type','aud','gain_type','weighted_partialHanning',...
				  'perform_mulawCompression',0,...
				  'filt_type','filter');

imp_freq = 1;
imp_period = 1./imp_freq;
Fs = 100;
imp_period_samps = imp_period*Fs;
dur = 20;
halfEnergyTime = 1.5;
tSamps = halfEnergyTime*Fs;
resonatorFreq = 4;

resonatorPeriod = 1./resonatorFreq;
resonatorPeriodSamps = floor(resonatorPeriod*Fs);
alpha = 0.5.^(resonatorPeriodSamps./tSamps);

impulse_train = repmat([1 zeros(1,imp_period_samps-1)],1,floor(dur/imp_period))';

%switch('input
%input_wvf
aud_st = init_aud('wvf',impulse_train,'Fs',Fs);


switch(RESON_BANK_TYPE)
  case 'comb'

   A = [1 zeros(1,resonatorPeriodSamps-1) -1*alpha];
   B = 1;
   combout = filter(B,A,impulse_train);
   max(combout)
   figure;
   
   subplot(3,1,1);
   plot(impulse_train);
   title(sprintf('%.1f Hz impulse train, Comb Freq %.1f, Tau = %.1f',imp_freq,resonatorFreq,halfEnergyTime));
   subplot(3,1,2);
   plot(combout);
   subplot(3,1,3);
   [H,F] = freqz(B,A,4096,Fs);
   plot(F,20*log10(abs(H)));
 case 'reson'
  %hfunc_resonatorBanks = resonatorBanks(params.resonatorBank.method);
  
  %[resonOut,resonFreqs] = ...
  %  hfunc_resonatorBanks(impulse_train,params.resonatorBank);
  
  %rp = init_rp_struct('resonatorOut',resonOut,'Fs',Fs);
  %rpCols = set_var_col_const(rp.vars);
  %rp.data{rpCols.resonatorEnergy} = resonatorEnergy(rp,params.resonatorBank);
  
  rp = rhythm_profiler(aud_st,params);
  
  
end


plotParams.numResonTicks = 15;
plotParams.perform = {'resonOutput','resonEnergy','meanEnergy','stdEnergy','findPeaks','showInput'};
plotParams.peakFinder.thresh = 0.25;
plotParams.timeTickRes = 2.0;
plotParams.colorbar = 1;
plotParams.inputSigType = 'impulse';
plotParams.savePlot = 0;
plotParams.savePath = globals.paths.stim_rp_plotPath;
plotParams.plotFname = 'impulses_filter.ps';
plotParams.separatePages = 0;
in{1} = rp;
in{2} = aud_st;
plot_rhythmProfile(in,plotParams);



