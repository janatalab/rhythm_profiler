%plotPath = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/calibration/';
%plotPath = '/data2/rhythm/rhythm_profiler/plots/meter_prediction';
plotPath = '/data2/groove/rmgc/plots';
globals = rhythmTap_globals;

filtType = 'reson';

PLOT_PERIODICITY_SURF = 1;
PLOT_VMFULFILL = 0;
PLOT_SUMRESONS = 0;
WRITE2TABLE = 1;
PLOT_KTEST = 0;
%if this is set to 1, barFreq will be used rather than pulseFreq
%bar freq determines the frequency of pulses based on the length of
%the bar rather than duration between pulses
USEBARFREQ = 1;

pulseFreq = 6; %pulse frequency in Hz.
barFreq = 0.5;

%seed the random number generator, used for note occurrence, below
rand('state',sum(100*clock));

if(strcmp(filtType,'comb'))
  globals.respIPEMParams.rp = rp_paramGroups('param_group',...
					     'comb',...
					     'input_type','aud','gain_type','constant',...
					     'perform_mulawCompression',0);
elseif(strcmp(filtType,'reson'))  
  globals.respIPEMParams.rp = rp_paramGroups('param_group',...
				   'reson_filterQSpacing_periodBasedDecay',...
				   'input_type','aud','gain_type','beta_distribution',...
				   'perform_mulawCompression',0);
end

dur = 30.01;
Fs = 100;

%theoretical predictions of note counts for places on a bar
%for different meters (3/4, 4/4, and 6/8). If you want all notes to
%be equally occurring, just use [1]
noteOccurrence = {[4 0 2 0 3 0 2 0 3 0 2 0],...
		  [5 0 2 0 3 0 2 0 4 0 2 0 3 0 2 0],...
		  [4 0 2 0 2 0 3 0 2 0 2 0]};

gaussFWHMms = 50;
gaussFWHMsamps = floor(gaussFWHMms/1000*Fs);

gaussian = gauss1D([1:Fs-1]-Fs/2,0,gaussFWHMsamps,1);

%standard deviations in ms
%stdDevsMs = [0 20 40 60 80];
stdDevsMs = [0 20 40 80];
%stdDevsMs = 0;

metricLabels = {'meter = 6/8','isochronous','isofast','meter = 3/4','meter = 4/4','accent every other','alternate23'};
%'meter = 3/4','accent every other','alternate23'
%metricLabels = {'hpbwReson_8thpower_morefilts'};
%accentPatterns = {[1]};
 
accentPatterns = {[1  0 .33  0 .66  0 .33   0  .66  0 .33  0],...
		  [1 0 0 0 0 0 0 0],...
		  [1 0 1 0 1 0 1 0 1 0 1 0],...
		  [1  0 .33  0 .33  0 .66   0  .33  0 .33  0],...
		  [1  0 .25  0 .5   0 .25   0  .75  0  .25 0 .5  0 .25 0],...
		  [1 0 0 0 .5 0 0 0],... 
		  [1 .66 1  .66  .66  ] };
 

vmFields = {'scaleByMag','kMethod'};
vmModes = {'no','k=4';...
	   'no','width';...
	   'no','area';...
	   'yes','k=4';...
	   'yes','width';...
	   'yes','area'};

nVmModes = size(vmModes,1);

useAccentIdxs = [3];
metricLabels = metricLabels(useAccentIdxs);
accentPatterns = accentPatterns(useAccentIdxs);

nStd = length(stdDevsMs);
nAccent = length(accentPatterns);

if(WRITE2TABLE)
  tablefile = '/data2/groove/rmgc/mean_results_rmspeaksfulltime_fwhm.txt';
  if(~exist(tablefile,'file'))
    writeHeader = true;
  else
    writeHeader = false;
  end
  fid = fopen(tablefile,'a');
  if(writeHeader)
    fprintf(fid,'%13s %8s %4s %5s %5s %5s\n','meter','barFreq','dev','pred','viol','td');
  end
end

for iaccent = 1:nAccent
  %for ivmMode = 1:nVmModes
  ivmMode = 1;
    for istd = 1:nStd

    
      useVmModes = vmModes(ivmMode,:);
      vmParams = cell2struct(useVmModes,vmFields,2);
      
      
      
    accentStruct = accentPatterns{iaccent};
    accentStructLen = length(accentStruct);
    
    devMs = stdDevsMs(istd);
    
    sigLen = round(dur*Fs);
    sig = zeros(sigLen,1);

    if(USEBARFREQ)
      pulsePeriod = 1./(barFreq*accentStructLen);
    else
      pulsePeriod = 1./pulseFreq;
    end
    pulsePeriodSamps = round(pulsePeriod*Fs);    
    
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
    
    numOnsets = length(onsetTimesSamps);
    accentIndices = mod([0:numOnsets-1],accentStructLen)+1;
    sig(onsetTimesSamps) = accentStruct(accentIndices);
    

    %CONVOLVING WITH GAUSSIAN
    sig = conv(sig,gaussian);
    
    aud_st = init_aud('Fs',Fs,'nchan',1,'wvf',sig);
    
    params{1}.ipem = globals.respIPEMParams;
    params{1}.ipem.glob.save_calc = {};
    
    params{1}.ipem.rp.resonatorBank.peakFinder.thresh = 0;
    params{1}.ipem.rp.resonatorBank.peakFinder.perform = {};
    params{1}.ipem.rp.resonatorBank.peakFinder.minPeakHeight = 0.1;
    %params{1}.ipem.rp.resonatorBank.resonFreqSpacing = 'linear';
    %params{1}.ipem.rp.resonatorBank.spacingHz = .1;
    params{1}.ipem.rp.resonatorBank.freqLimits = [0.25 10.0];
    %params{1}.ipem.rp.resonatorBank.spacingFactor =0.125;
    params{1}.ipem.rp.Fs = Fs;
    params{1}.ipem.rp.vmExpect = vmParams;
    
    
    
    ipemOut = ipem_proc_series(aud_st,params{1}.ipem);
    ipemOutCols = set_var_col_const(ipemOut.vars);
    rp = ipemOut.data{ipemOutCols.rp};

    %add von Mises calculations to the rp struct
    %vmExpectData = rp_vonMisesExpectCalc(rp,params{1}.ipem.rp);
    %rp = rp_phaseCoherenceByPeak(rp,params{1});
    
    
    %params{2}.perform = {'resonEnergy','meanEnergy','stdEnergy', ...
    %	    'findPeaks','ratioProb','showInput'};
    %	    %'resonOutput',
    params{2}.perform = {'resonOutput','resonEnergy','meanEnergy','stdEnergy', ...
    	    'findPeaks','showInput','expectProbByOnset'};
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
    params{2}.savePlot = 1;
    params{2}.separatePages = 0;
    params{2}.peakFinder.thresh = 0;
    params{2}.peakFinder.perform = {};
    params{2}.peakFinder.minPeakHeight = 0;
    %params{2}.resonOut.clim = [-7 7]*10^-3;
    %params{2}.resEnergy.clim = [0 3]*10^-3;
    %params{2}.meanEnergy.ylim = [0 3.5]*10^-3;
    
    params{2}.meanEnergy.numticks = 4;
    params{2}.meanEnergy.yTickLabelFmt = '%.3f';
    
    actualStructLen = length(find(accentStruct > 0));
    startOnsetToPlot = actualStructLen*5+1;
    endOnsetToPlot = startOnsetToPlot+actualStructLen*5-1;
    params{2}.expectProbByOnset.onsetsToPlot = [startOnsetToPlot:endOnsetToPlot];
    %params{2}.expectProbByOnset.onsetsToPlot = [1:(length(find(sig > 0))-1)];
 
    if(USEBARFREQ)
      freqString = sprintf('Bar=%.1f Hz',barFreq);
    else
      freqString = sprintf('Pulse=%.1f Hz',pulseFreq);
    end
    
    metricFileLabels = regexprep(metricLabels,'[\s=/]','');
    freqFileLabel = regexprep(freqString,'[\s=/]','');
    titlestub = 'metric exemplars rmspeaksfulltime fwhm';
    fstub = strrep(titlestub,' ','_');
    
    if(devMs ~= 0)
      params{2}.fig.title = sprintf('%s (%s, std = %2d ms) %s',titlestub,freqString,devMs,metricLabels{iaccent});
    else
      params{2}.fig.title = sprintf('%s (%s, no deviation) %s',titlestub,freqString,metricLabels{iaccent});
    end
    params{2}.plotFname = sprintf('%s_%s_%dms_dev_%s.ps',fstub,freqFileLabel,devMs,metricFileLabels{iaccent});
    
    if(iscell(rp))
      inData{1} = rp{1};
    else
      inData{1} = rp;
    end
    inData{2} = aud_st;
    
    if(PLOT_PERIODICITY_SURF)
      plot_rhythmProfile(inData,params{2});
    end
    
    if(PLOT_VMFULFILL)
      vmParams.subplotNum = (istd-1)*(length(accentPatterns)) + iaccent;
      vmParams.savePlot = 1;
      if( (istd == nStd) && (iaccent == nAccent))
	vmParams.lastPlot = 1;
      else
	vmParams.lastPlot = 0;
      end
      
      vmParams.path = plotPath;
      vmParams.fname = sprintf('metric_fulfillment_timeseries.ps');
      vmParams.title = sprintf('(%s, std = %2d ms) %s',freqString,devMs,metricLabels{iaccent});
      plot_vmMetricFulfillment(inData,vmParams);
    end
    
    if(PLOT_SUMRESONS)
      vmParams.subplotNum = (istd-1)*(length(accentPatterns)) + iaccent;
      vmParams.title = sprintf('(%s, std = %2d ms) %s',freqString,devMs,metricLabels{iaccent});
      if( (istd == nStd) && (iaccent == nAccent))
	vmParams.lastPlot = 1;
      else
	vmParams.lastPlot = 0;
      end
      
      vmParams.fname = 'sum_resonOut.ps';
      plot_sumPeakResons(inData,vmParams);
    end
    
    if(WRITE2TABLE)
      
      rpstruct = ensemble_datastruct2tree(rp{1});
      predictionPerOnset = rpstruct.vmExpect.vmPredictionPerOnset{1};
      violationPerOnset = rpstruct.vmExpect.vmViolationPerOnset{1};
      timingdevPerOnset = rpstruct.vmExpect.vmTimingDev{1};
      
      mfulfill = mean(predictionPerOnset);
      madjviol = mean(violationPerOnset);
      mTD = mean(timingdevPerOnset);
      
      fprintf(fid,'%13s %8.2f %4d %6.2f %6.2f %6.2f\n',metricLabels{iaccent},barFreq,devMs,mfulfill,madjviol,mTD);
    end
      
    
    if(PLOT_KTEST)
      kt_params.plotFname = params{2}.plotFname;
      kt_params.plotPath = plotPath;
      rmgc_plot_ktest(rp,kt_params);
      
      
    end

    
    end
  %end
end

if(WRITE2TABLE)
  fclose(fid);
end
