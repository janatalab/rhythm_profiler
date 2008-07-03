
  if(0)
    thresh = 5.8;
    disp(sprintf('finding filter peaks for rp %d',ifile));
    %find peaks of filter outputs (not summed across channels)
    [dxFilt,dyFilt,dzFilt] = gradient(rp.resonatorOut);
    dxFilt(find(dxFilt >= 0)) = 1;
    dxFilt(find(dxFilt < 0)) = 0;
    diffDxFilt = zeros(size(rp.resonatorOut));
    diffDxFilt(:,2:end,:) = diff(dxFilt,1,2);
    rp.filtOutPeaks =  (diffDxFilt == -1) & (rp.resonatorOut > thresh);
    
  
  
   if(FIND_FILT_PEAKS)
    thresh = 5.8;
    disp(sprintf('finding filter peaks for rp %d',ifile));
    %find peaks of filter outputs (not summed across channels)
    %[dxFilt] = gradient(rp.combOut);
    dxFilt = zeros(size(rp.resonatorOut));
    dxFilt(:,2:end,:) = diff(rp.resonatorOut,1,2);
    dxFilt(find(dxFilt > 0)) = 1;
    dxFilt(find(dxFilt <= 0)) = 0;
    diffDxFilt = zeros(size(rp.resonatorOut));
    diffDxFilt(:,1:end-1,:) = diff(dxFilt,1,2);
    %clear dxFilt;
    tempFiltOutPeaks = (diffDxFilt == -1) & (rp.resonatorOut > thresh);
    %clear diffDxFilt;
  end
  
  if(CALC_3D_ENTROPY)
    disp(sprintf('Calculating 3D Entropy for rp %d',ifile));
    
    for(imeasure = 1:num_measures)
    
      measure_tsamps = [(imeasure -1)*samps_per_measure+1:(imeasure)*samps_per_measure];
      m_peaks = rp.filtOutPeaks(:,:,measure_tsamps);
      npts_total = prod(size(m_peaks));
      norm_peaks = m_peaks/npts_total;
      ent = norm_peaks.*log10(norm_peaks);
      rp.H(imeasure) = -nansum(ent(:));
    
      for(ichannel = 1:size(rp.filtOutPeaks,1))
	mc_peaks = rp.filtOutPeaks(ichannel,:,measure_tsamps);
	npts_total = prod(size(mc_peaks));
	norm_peaks = mc_peaks/npts_total;
	ent = norm_peaks.*log10(norm_peaks);
	rp.H2(ichannel,imeasure) = -nansum(ent(:));	
      end
     
    end
    
    
  end
  
  
  if(PLOT_TEMPO_ANALYSIS)    
    tLengthSecs = size(rp.rms,2)./rp.rmsFs;
    tticks = [0:2:tLengthSecs].*rp.rmsFs;
    tLabels = tticks./rp.rmsFs;
    resonTicks = [1:20:length(resonFreq)];
    resonLabels = resonFreq(resonTicks);
    figure;
    subplot(3,1,1);
    title(gca,'Attacks Across Channels');
    imagesc(denv);
    set(gca,'xtick',tticks,'xticklabel',sprintf('%.1f|',tLabels));
    subplot(3,1,2);
    title(gca,'Comb Filter Output (summed across channels)');
    imagesc(squeeze(sum(rp.resonatorOut,1)));
    set(gca,'xtick',tticks,'xticklabel',sprintf('%.1f|',tLabels),'ytick',resonTicks,'yticklabel',sprintf('%.3f|',resonLabels),'ylim',[1 length(resonFreq)]);
    xlabel('Time(s)');
    ylabel('Comb Filter (Hz)');

    subplot(3,1,3);
    title(gca,'Comb Filter with Maximum Energy Output');

    plot(rp.maxFilt);
    set(gca,'ydir','reverse','xlim',[tticks(1) tticks(end)],'xtick',tticks,'xticklabel',sprintf('%.1f|',tLabels),'ytick',resonTicks,'yticklabel',sprintf('%.3f|',resonLabels),'ylim',[1 length(resonFreq)]);
															   %xlabel('Time(s)');
  end
end  
  
