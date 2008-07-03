plotPath = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/calibration/iso_var_accent';
globals = rhythmTap_globals;

filtType = 'comb';

if(strcmp(filtType,'comb'))
  globals.respIPEMParams.rp = rp_paramGroups('param_group',...
					     'comb',...
					     'input_type','aud','gain_type','constant',...
					     'perform_mulawCompression',0);
elseif(strcmp(filtType,'reson'))  
  globals.respIPEMParams.rp = rp_paramGroups('param_group',...
				   'reson_filterQSpacing_periodBasedDecay',...
				   'input_type','aud','gain_type','constant',...
				   'perform_mulawCompression',0);
end

dur = 30.01;
Fs = 100;

gaussFWHMms = 200;
gaussFWHMsamps = floor(gaussFWHMms/1000*Fs);

gaussian = gauss1D([1:Fs-1]-Fs/2,0,gaussFWHMsamps,1);


%standard deviations in ms
%stdDevsMs = [0 20 40 80];
stdDevsMs = 0;

%accents = {[1],[2],[3],[4],[5],[2 3]};
accents = {[0],[2],[3],[2 3]};
%accents = {[1]};

%pulse frequency in Hz.
pulseFreq = 1;


pulsePeriod = 1./pulseFreq;
pulsePeriodSamps = round(pulsePeriod*Fs);

for istd = 1:length(stdDevsMs)
  for iaccent = 1:length(accents)
    devMs = stdDevsMs(istd);
    
    sigLen = round(dur*Fs);
    sig = zeros(sigLen,1);
    
    onsetTimesSamps = [1:pulsePeriodSamps:sigLen];
    numOnsets = length(onsetTimesSamps);

    if(devMs ~= 0)
      onsetDevsMs = randn(1,numOnsets-1).*devMs;
      onsetDevsSamps = round(onsetDevsMs./1000.*Fs);
    else
      onsetDevsSamps = zeros(1,numOnsets-1);
    end
  
    onsetTimesSamps(2:end) = onsetTimesSamps(2:end) + onsetDevsSamps;
    onsetTimesSamps(find(onsetTimesSamps > sigLen)) = [];

    accentStruct = accents{iaccent};
    
    if(length(accentStruct) == 1)
      sig(onsetTimesSamps) = 0.5;
      sig(onsetTimesSamps(1:accentStruct:end)) = 1;
    else
      sig(onsetTimesSamps) = 0.5;
      accLen = sum(accentStruct);
      sig(onsetTimesSamps(1:accLen:end)) = 1;
      sig(onsetTimesSamps(1+accentStruct(1):accLen:end)) = 1;
    end

    %CONVOLVING WITH GAUSSIAN
    sig = conv(sig,gaussian);

    aud_st = init_aud('Fs',Fs,'nchan',1,'wvf',sig);
    
    params{1}.ipem = globals.respIPEMParams;
       
    ipemOut = ipem_proc_series(aud_st,params{1}.ipem);
    ipemOutCols = set_var_col_const(ipemOut.vars);
    rp = ipemOut.data{ipemOutCols.rp};
    
    params{2}.perform = {'resonEnergy','meanEnergy','stdEnergy', ...
		    'findPeaks','showInput'}; %'resonOutput',
    params{2}.freqLegend = 1;
    params{2}.legendParams.minHz = 1;
    params{2}.legendParams.maxHz = 5;
    params{2}.legendParams.numKeys = 8;
    params{2}.colorbar = 1;
    params{2}.savePath = plotPath;
    params{2}.timeTickRes = 2.0;
    params{2}.numResonTicks = 15;
    params{2}.maxResonFreqPlot = 10;
    params{2}.inputSigType = 'wvf';
    params{2}.plotMeans = 1;
    params{2}.color = 0;
    params{2}.savePlot = 0;
    params{2}.separatePages = 1;
    params{2}.peakFinder.thresh = 0.1;
    params{2}.peakFinder.perform = {};
    %params{2}.resonOut.clim = [-7 7]*10^-3;
    %params{2}.resEnergy.clim = [0 3]*10^-3;
    %params{2}.meanEnergy.ylim = [0 3.5]*10^-3;
  
    params{2}.meanEnergy.numticks = 4;
    params{2}.meanEnergy.yTickLabelFmt = '%.3f';
    accentString = sprintf('acc=%d%d',accentStruct);
    
    if(devMs ~= 0)
      params{2}.fig.title = sprintf('iso variability test (%.1f Hz, std = %2d ms) %s',pulseFreq,devMs,accentString);
    else
      params{2}.fig.title = sprintf('iso variability test (%.1f Hz, no deviation) %s',pulseFreq,accentString);
    end
    params{2}.plotFname = sprintf('iso_variability_test_gaussInput_%s_%.1f_Hz_%dms_dev_%s.ps',filtType,pulseFreq,devMs,accentString);
    
    inData{1} = rp{1};
    inData{2} = aud_st;
    
    plot_rhythmProfile(inData,params{2});
    
  end
end
