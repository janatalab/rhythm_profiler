plot_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/btb';


Fs = 100;
SAVE_PLOT = 0;

lengthSecs = 8;
timeVector = 1/Fs:1/Fs:lengthSecs+1/Fs;
params.resonatorBank.Fs = Fs;

impFreq = 1.00625;
impPeriod = 1./impFreq;
impPeriod2 = 0.25;
anti_phase_dur = impPeriod/2;

plotResonFreq = 2.5;;


%regular impulses
imp_times = [0:impPeriod:8];



%anti-phase impulse
imp_times2 = [imp_times imp_times(end)+anti_phase_dur];

%anti-phase set of impulses
imp_times3 = [imp_times imp_times(end) + [anti_phase_dur:impPeriod:4-impPeriod]];

%new freq after 4s
imp_times4 = [imp_times imp_times(end) + [impPeriod2:impPeriod2:4-impPeriod2]];


sig{1} = zeros(1,lengthSecs*Fs+1);
sig{2} = zeros(1,lengthSecs*Fs+1);
sig{3} = zeros(1,lengthSecs*Fs+1);
sig{4} = zeros(1,lengthSecs*Fs+1);

sig{1}(floor(imp_times*Fs+1)) = 1;
sig{1}(floor(imp_times(1:2:end)*Fs+1)) = .5;
sig{2}(floor(imp_times2*Fs+1)) = 1;
sig{3}(floor(imp_times3*Fs+1)) = 1;
sig{4}(floor(imp_times4*Fs+1)) = 1;


isig = 1;


figure('PaperPosition',[.25 .25 8 10.5]);
set(gcf,'position',[200 200 560 800]);

%PLOT INPUT
subplot(3,1,1);
plot(timeVector,sig{isig},'k');
title(sprintf('Input at %.2f Hz',1./impPeriod));
xlabel('Time (s)','FontSize',14);
ylabel('Amplitude','FontSize',14);
set(gca,'xminortick','on','FontSize',14);
set(gca,'xlim',[0 lengthSecs]);
ylims = get(gca,'ylim');
set(gca,'ytick',[ylims(1):(ylims(2)-ylims(1))/4:ylims(2)]);
axpos = get(gca,'position');


%PLOT COMB
params = rp_paramGroups('param_group','comb',...
			'input_type','aud','gain_type','constant',...
			'perform_mulawCompression',0,...
			'filt_type','filter');
params.resonatorBank.freqLimits = [plotResonFreq plotResonFreq];
params.resonatorBank.numFilters = 1;
inputSignal = sig{isig};
  
rbankMethod = resonatorBanks(params.resonatorBank.method);
[outputSignal,resonFreqs,BList,AList,QList] = rbankMethod(inputSignal,params.resonatorBank);

rp = init_rp_struct('resonatorOut',outputSignal,'resonatorFreqs',resonFreqs);
rpCols = set_var_col_const(rp.vars);
rp.data{rpCols.Fs} = params.Fs;
%rp.data{rpCols.resonatorEnergy} = resonatorEnergy(rp,params.resonatorBank);

resonFreqs = rp.data{rpCols.resonatorFreqs};

resonidx = find(abs(resonFreqs - plotResonFreq) == min(abs(resonFreqs - plotResonFreq)));

pl_output = squeeze(outputSignal);
subplot(3,1,2);
plot(timeVector,pl_output,'k');
title(sprintf('Comb filter %.3f Hz',resonFreqs(resonidx)));
set(gca,'xminortick','on','FontSize',14);
set(gca,'xlim',[0 lengthSecs]);
ylims = get(gca,'ylim');
set(gca,'ytick',[ylims(1):(ylims(2)-ylims(1))/4:ylims(2)]);
axpos = get(gca,'position');



%PLOT RESON
params = rp_paramGroups('param_group','reson_linearSpacing_constantBandwidth',...
	       'input_type','aud','gain_type','constant',...
	       'perform_mulawCompression',0,...
			'filt_type','filter');
params.resonatorBank.freqLimits = [plotResonFreq plotResonFreq];
inputSignal = sig{isig};
  
rbankMethod = resonatorBanks(params.resonatorBank.method);
[outputSignal,resonFreqs,BList,AList,QList] = rbankMethod(inputSignal,params.resonatorBank);

rp = init_rp_struct('resonatorOut',outputSignal,'resonatorFreqs',resonFreqs);
rpCols = set_var_col_const(rp.vars);
rp.data{rpCols.Fs} = params.Fs;
%rp.data{rpCols.resonatorEnergy} = resonatorEnergy(rp,params.resonatorBank);

resonFreqs = rp.data{rpCols.resonatorFreqs};
resonidx = find(abs(resonFreqs - plotResonFreq) == min(abs(resonFreqs - plotResonFreq)),1,'first');

pl_output = squeeze(outputSignal);
subplot(3,1,3);
plot(timeVector,pl_output,'k');
title(sprintf('Reson filter %.3f Hz',resonFreqs(resonidx)));
ylims = get(gca,'ylim');
set(gca,'ytick',[ylims(1):(ylims(2)-ylims(1))/4:ylims(2)]);
set(gca,'xlim',[0 lengthSecs]);
set(gca,'xminortick','on','FontSize',14);
axpos = get(gca,'position');

if(SAVE_PLOT)
  print(fullfile(plot_dir,['reson_vs_comb_input_' num2str(isig) '.ps']),'-dpsc');
  close(gcf);
end

