%testing the responses of reson filters of varying frequencies from
%one impulse

warning off

TEST_MODEL = 'reson_filterQSpacing_periodBasedDecay';
%TEST_MODEL = 'reson_linearSpacing_constantBandwidth';
%TEST_MODEL = 'comb';
INPUT_TYPE = 'sine';
GRAPHTYPE = 'magnitude_response';
PLOT_BW = 1;
DBSCALE = 1;
NORMALIZE = 0;
params = rp_paramGroups('param_group',TEST_MODEL,...
	       'input_type','aud','gain_type','beta_distribution',...
	       'perform_mulawCompression',0,...
			'filt_type','filter');

plot_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/btb';

%for plotting only one particular reson.
%will plot the closest reson to this freq. in Hz.
%If 0, plots all resons
plotFreqMagResp = 0;

Fs = params.Fs;

lengthSecs = 8;
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
[outputSignal,resonFreqs,BList,AList,QList] = rbankMethod(inputSignal,params.resonatorBank);

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
  
  
  for iReson = 1:size(magResp,2);

      
    thisMagResp = magResp(:,iReson);
    
    logMagResp = 20*log10(thisMagResp);

    hold on
    
    if(DBSCALE)
      plot(F,logMagResp,'color',cmap(mod(iReson,numColors)+1,:));
    else
      plot(F,thisMagResp(:,iReson),'color',cmap(mod(iReson,numColors)+1,:));
    end

    peakMag = max(thisMagResp);
    peakMagIdx = find(thisMagResp == peakMag);    
    actualFreq(iReson) = F(peakMagIdx);
    
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
  %set(gca,'xlim',[0 max(actualFreq)+0.5]);
  %set(gca,'ylim',[-25 0]);
  
  %set(gca,'xlim',[1 2]);
  %set(gca,'ylim',[-6 -1]);
  
  
  %set(gca,'ylim',[-60 5]);
  xlabel('Frequency (Hz)');
  ylabel('Magnitude Response (dB)');
  %print(fullfile(plot_dir,'resonFiltBank_response_closeup.ps'),'-dpsc');
  
  
end
  
