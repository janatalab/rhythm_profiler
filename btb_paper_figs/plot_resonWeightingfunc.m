
params = rp_paramGroups('param_group','reson_filterQSpacing_periodBasedDecay',...
	       'input_type','aud','gain_type','weighted_partialHanning',...
	       'perform_mulawCompression',0,...
			'filt_type','filter');

plot_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/btb';

inputSignal = zeros(1,500);

rbankMethod = resonatorBanks(params.resonatorBank.method);
[outputSignal,resonatorFreqs,BList,AList,QList] = rbankMethod(inputSignal,params.resonatorBank);


minGain = 0.1;
maxGain = 0.4;
maxFreq = 1.66;
nTicks = 5;

gainVector = zeros(size(resonatorFreqs));
gainVector(find(resonatorFreqs >= maxFreq)) = maxGain;  
gainCurveLength = sum(resonatorFreqs < maxFreq);
hanningCurve = hanning(gainCurveLength*2);
gainVector(find(resonatorFreqs < maxFreq)) = minGain + (maxGain-minGain).*hanningCurve(1:gainCurveLength);
  
figure;
plot(resonatorFreqs,gainVector,'k');

tickVector = [1:floor(length(gainVector)/nTicks): ...
	      length(gainVector)];

tickLocs = [0 0.5 1.0 2.0 4.0 8.0];
tickLabels = num2str(tickLocs,'%.1f|');

set(gca,'xtick',tickLocs);
set(gca,'xticklabel',tickLabels);
set(gca,'xscale','log');
set(gca,'xlim',[0 max(tickLocs)]);
xlabel('Resonator Frequency (Hz)');
ylabel('Gain');

print(fullfile(plot_dir,'resonWeightFunc.ps'),'-dpsc');
