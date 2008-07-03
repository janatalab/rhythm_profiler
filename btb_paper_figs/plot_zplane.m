plot_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/btb';

TEST_MODEL = 'reson_linearSpacing_constantBandwidth';

params = rp_paramGroups('param_group',TEST_MODEL,...
	       'input_type','aud','gain_type','weighted_partialHanning',...
	       'perform_mulawCompression',0,...
			'filt_type','filter');

lengthSecs = 1;
Fs = 100;
inputSignal = zeros(1,lengthSecs*Fs);
rbankMethod = resonatorBanks(params.resonatorBank.method);
[outputSignal,resonFreqs,BList,AList,QList] = rbankMethod(inputSignal,params.resonatorBank);

plotResonFreq = 2.0;
resonidx = find(abs(resonFreqs - plotResonFreq) == min(abs(resonFreqs - plotResonFreq)));
  
  
zplane(BList{resonidx},AList{resonidx});
axch = get(gca,'children');
set(axch(2),'linestyle',':','linewidth',1,'color','k');
set(axch(3:4),'color','r','markersize',10,'linewidth',2);
print(fullfile(plot_dir,'zplane_reson.ps'),'-dpsc');
