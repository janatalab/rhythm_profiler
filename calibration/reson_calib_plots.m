%testing the responses of reson filters of varying frequencies from
%one impulse

warning off

TEST_MODEL = 'reson_filterQSpacing_periodBasedDecay';
%TEST_MODEL = 'comb';
INPUT_TYPE = 'impulse';
GRAPHTYPE = '';%'magnitude_response';
PLOT_GAIN_CURVE = 1;
PLOT_BW = 0;
DBSCALE = 1;
NORMALIZE = 0;
RESON_FREQ_SCALE = 1;
params = rp_paramGroups('param_group',TEST_MODEL,...
	       'input_type','aud','gain_type','prenorm_beta_distribution',...
	       'perform_mulawCompression',0,...
			'filt_type','filter');
params.resonatorBank.gainFunction.maxGain = 1;
params.resonatorBank.gainFunction.minGain = 0.25;
params.resonatorBank.gainFunction.betaDistribution.alpha = 2;%1.5;
params.resonatorBank.gainFunction.betaDistribution.beta = 5;%5.5;
params.resonatorBank.resonType = 'reson';
plot_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/btb';

%for plotting only one particular reson.
%will plot the closest reson to this freq. in Hz.
%If 0, plots all resons
plotFreqMagResp = 0;

Fs = params.Fs;

lengthSecs = 30;
timeVector = 1/Fs:1/Fs:lengthSecs;
params.resonatorBank.Fs = Fs;

switch(INPUT_TYPE)  
 case 'impulse'
  %feeding unit impulse
  inputSignal = [1 zeros(1,lengthSecs*Fs-1)];
  
 case 'impulse_train'
  freq = 2;
  inputSignal = zeros(1,lengthSecs*Fs);
  inputSignal(1:ceil(Fs/freq):end) = 1;
  
 case 'sine'
  %feeding sine wav
  t = [1:lengthSecs*Fs];
  freq = 1;
  inputSignal = sin(freq*t./Fs*2*pi);
  
 case 'noise'
  noiseLength = 1;
  inputSignal = [2*(rand(1,noiseLength*Fs)-.5) zeros(1,(lengthSecs - noiseLength)*Fs)];
  
end

rbankMethod = resonatorBanks(params.resonatorBank.method);
[outputSignal,resonFreqs,BList,AList,QList,Rlist] = rbankMethod(inputSignal,params.resonatorBank);

rp = init_rp_struct('resonatorOut',outputSignal,'resonatorFreqs',resonFreqs);
rpCols = set_var_col_const(rp.vars);
rp.data{rpCols.Fs} = params.Fs;
rp.data{rpCols.resonatorEnergy} = resonatorEnergy(rp,params.resonatorBank);

switch(GRAPHTYPE)
  
 case 'impulse_response'
  
  numResonTicks = 15;
  resonFreqTick = [1:floor(length(resonFreqs)/numResonTicks):length(resonFreqs)];
  resonFreqLabel = num2str(resonFreqs(resonFreqTick)','%.2f');
  
  load new_seismic;
  figure;
  imagesc(timeVector,[1:length(resonFreqs)],squeeze(outputSignal));
  set(gca,'Ytick',resonFreqTick);
  set(gca,'YtickLabel',resonFreqLabel);
  colormap(new_seismic);
  figure;
  plot(resonFreqs,mean(abs(squeeze(outputSignal)),2));
  figure;
  imagesc(timeVector,[1:length(resonFreqs)],rp.data{rpCols.resonatorEnergy});
  set(gca,'Ytick',resonFreqTick);
  set(gca,'YtickLabel',resonFreqLabel);
  colormap(hot);
  figure;
  numTimeDecayPlots = 6;
  
  
  subplot(numTimeDecayPlots+1,1,1);
  plot(inputSignal);
  for iPlot = 1:numTimeDecayPlots
    subplot(numTimeDecayPlots+1,1,iPlot+1);
    nFreqs = length(resonFreqs);
    freqIdx = ceil(nFreqs*iPlot/numTimeDecayPlots);
    plotFreq = resonFreqs(freqIdx);
    
    if(DBSCALE)
      plot(20*log10(abs(squeeze(outputSignal(1,freqIdx,:)))));
      set(gca,'ylim',[-60 0],'xlim',[1 length(inputSignal)]);
    else
      plot(abs(squeeze(outputSignal(1,freqIdx,:))));
    end
    

    title([num2str(plotFreq) ' Hz']);
  end
  

 case 'magnitude_response'
  figure;
  numColors = 10;
  cmap = hsv(numColors);
  for iReson = 1:length(BList)
  
    [H(:,iReson),F(:,iReson)] = freqz(BList{iReson},AList{iReson},8092,Fs);

    magResp(:,iReson) = abs(H(:,iReson));
 
  end

  
  if(NORMALIZE)
    maxMag = max(magResp(:));
    magResp = magResp./maxMag;
  end
  
  if(plotFreqMagResp ~= 0)
    magRespIdx = find(abs(resonFreqs - plotFreqMagResp) == min(abs(resonFreqs-plotFreqMagResp)));
    magResp = magResp(:,magRespIdx);
  end
  
  yMax = 0;
  for iReson = 1:size(magResp,2);

      
    thisMagResp = magResp(:,iReson);
    
    logMagResp = 20*log10(thisMagResp);

    hold on
    
    if(DBSCALE)
      plot(F,logMagResp,'color',cmap(mod(iReson,numColors)+1,:));
    else
      plot(F,thisMagResp,'color',cmap(mod(iReson,numColors)+1,:));
    end

    peakMag = max(thisMagResp);
    peakMagIdx = find(thisMagResp == peakMag);    
    actualFreq(iReson) = F(peakMagIdx);
    
    yMax = max(peakMag,yMax);
    
    
    if(PLOT_BW)
      %find half-power points and plot them
      leftHPIdx = find(thisMagResp >= peakMag*1/sqrt(2),1,'first');
      rightHPIdx = find(thisMagResp >= peakMag*1/sqrt(2),1,'last');
      plot(F(leftHPIdx),logMagResp(leftHPIdx),'o','color',cmap(mod(iReson,numColors)+1,:));
      plot(F(rightHPIdx),logMagResp(rightHPIdx),'o','color',cmap(mod(iReson,numColors)+1,:));
      estBw = F(rightHPIdx) - F(leftHPIdx);
      text(F(peakMagIdx),logMagResp(peakMagIdx) - 5,num2str(estBw,'%.2f'));  
    end
    
  end

  if(DBSCALE)
    logYMax = 20*log10(yMax);
    set(gca,'ylim',[logYMax-40 logYMax+3]);
  end
  
  

  
  set(gca,'xlim',[0 10.5]);
  
  xlabel('Frequency (Hz)');
  ylabel('Magnitude Response (dB)');

 otherwise
  figure;

end
  
if(PLOT_GAIN_CURVE)
  betaFunc = resonatorBanks('betaDistribution');
  gainParams =  params.resonatorBank.gainFunction;
  gainParams.resonatorFreqs = resonFreqs;
  gainVector = betaFunc(gainParams);
  PLOT_BETA = 1;
  RESON_FREQ_SCALE = 1;
  if(PLOT_BETA)
    plotFunc = 20*log10(gainVector);    
  else
    plotFunc = 20*log10(1.*2./(1-Rlist.^2));
  end
  if(RESON_FREQ_SCALE)
    plot(plotFunc,'k');
    tickLabels = num2str(resonFreqs','%.2f');
    set(gca,'xtick',[1:10:99]);
    set(gca,'xticklabel',tickLabels(1:10:99,:));
  else
    plot(resonFreqs,plotFunc,'k');
  end

  if(PLOT_BETA == 1)
    titleStr = 'Reson gain normalized, then shaped by beta function';
  else
    titleStr = 'Reson gain (unshaped)';
  end
  
  if(RESON_FREQ_SCALE)
    titleStr = [titleStr ', freq scaled by reson spacing'];
  else
    titleStr = [titleStr ', freq linearly scaled'];
  end
  title(titleStr);
  
  xlabel('Frequency (Hz)');
  ylabel('Magnitude Response (dB)');

end
  
