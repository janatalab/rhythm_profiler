%test rp performance with data from ISMIR 2004 beat induction contest

CALC_TEMPO_ESTIMATES = 1;
RESAMPLE_MEAN_ENERGY = 0;

CALC_ERROR_CURVE = 1;
PLOT_ERROR_HISTOGRAM = 1;
PLOT_PERF_VS_TEMPI = 1;
SAVE_PLOTS = 1;


plotDir = '/home/petr/data/rhythm/rhythm_profiler/tempo_induction_competition/plots';

rp_dir_list = {'/data2/rhythm/rhythm_profiler/tempo_induction_competition/Songs_Data_annotations_Results'...
	       '/data2/rhythm/rhythm_profiler/tempo_induction_competition/BallroomData',...
	       
	      };

annotation_dirs = {'<path>/Fabien''s annotations/<fstub> beat.bpm',...
		   '/data2/rhythm/rhythm_profiler/tempo_induction_competition/BallroomAnnotations/ballroomGroundTruth/<fstub>.bpm'};
		   
filetype = '.wav';

if(CALC_TEMPO_ESTIMATES)
  tolerancePercent = 0.04;  
  comparison_matrix = {};
  resampCorrection = [];

  %for dir_idx = 1:length(rp_dir_list)
   for dir_idx = 2:2 
    rp_test_dir = rp_dir_list{dir_idx};
    cd(rp_test_dir);
    fnames = dirrec('.',filetype);
    %exclude files that are in wav subdirectories (these were previously symlinked)
    symlinked_files = regexp(fnames,'.*/wav/.+');
    for idx = 1:length(symlinked_files)
      symlinked_files_idxs(idx) = ~isempty(symlinked_files{idx});
    end
    fnames = fnames(~symlinked_files_idxs);
    flist = check_stim_dirs(fnames,'srcroot',rp_test_dir,'destroot',rp_test_dir);
    
    params.ipem.glob.process = {'ani','rp'};
    params.ipem.glob.force_recalc = {};
    params.ipem.glob.save_calc = {'ani'};
    params.ipem.ani = ani_paramGroups;
    %set normalization maxval a little lower than our stims to avoid
    %clipping during resampling
    params.ipem.ani.normalize_maxVal = 0.9;
    params.ipem.rp = rp_paramGroups('param_group',...
				    'reson_filterQSpacing_periodBasedDecay',...
				    'input_type','ani','gain_type','prenorm_beta_distribution',...
				    'perform_mulawCompression',0);
    
    params.ipem.rp.resonatorBank.spacingFactor = 0.5;
    %params.ipem.rp.resonatorBank.gainFunction.betaDistribution.flattenAt = 1.25;
    %params.ipem.rp.resonatorBank.gainFunction.maxGain = 0.004;
    %params.ipem.rp.resonatorBank.gainFunction.minGain = 0.001;
    params.peakFinder.thresh = 0.25;
    params.peakFinder.perform = {};
 
    %for fidx = 1:length(flist)
     for fidx = 562:562 
      disp(sprintf('Processing set %d, clip %d of %d',dir_idx,fidx,length(flist)));
      %retrieve the rp
      disp(sprintf('Retrieving RP for %s...',flist{fidx}));
      ipemOut = ipem_proc_series(flist{fidx},params.ipem);
      ipemOutCols = set_var_col_const(ipemOut.vars);
      rp = ipemOut.data{ipemOutCols.rp};
      if(iscell(rp))
	rp = rp{1};
      end
      
      rpCols = set_var_col_const(rp.vars);
      rpParams = rp.data{rpCols.params}.rp;
      resonatorFreqs = rp.data{rpCols.resonatorFreqs};
      freqLimits = [resonatorFreqs(1) resonatorFreqs(end)];
  
      %obtain the peak Frequencies      
      meanEnergy = rp.data{rpCols.meanResonatorEnergy};

      peakIdxs = find_peaks(meanEnergy,params.peakFinder);
      peakAmplitudes = meanEnergy(peakIdxs); 
      peakFreqs = resonatorFreqs(peakIdxs);
      
      %transpose peakAmplitudes if it is not a row vector
      %this is essential for the sort
      if(size(peakAmplitudes,1) < size(peakAmplitudes,2))
	peakAmplitudes = peakAmplitudes';
      end
      
      [peakAmplitudesSorted,sortIdx] = sort(peakAmplitudes,1,'descend');
      peakFreqsSorted = peakFreqs(sortIdx);
      
      if(RESAMPLE_MEAN_ENERGY)      
	%resample the filter vals to obtain a finer sampling
	%new Q value is just used for obtaining a samping for
        %interpolation. Decay time is not affected.
	Q = rpParams.resonatorBank.numPeriodDecay.*4;
	freqIdx = 1;
	resonatorResampFreqs(freqIdx) = freqLimits(1);
	while(resonatorResampFreqs(freqIdx) <= freqLimits(2))
	  freqIdx = freqIdx + 1;
	  lastBW = resonatorResampFreqs(freqIdx-1)./Q;
	  resonatorResampFreqs(freqIdx) = resonatorResampFreqs(freqIdx-1) + 0.5*lastBW;
	end
	numResampFreqs= length(resonatorResampFreqs);
	meanEnergyResamp = spline(resonatorFreqs,meanEnergy,resonatorResampFreqs)';

	peakIdxs = find_peaks(meanEnergyResamp,params.peakFinder);
	peakAmplitudesResamp = meanEnergyResamp(peakIdxs); 
	peakFreqsResamp = resonatorResampFreqs(peakIdxs);
      
	%transpose peakAmplitudes if it is not a row vector
	%this is essential for the sort
	if(size(peakAmplitudesResamp,1) < size(peakAmplitudesResamp,2))
	  peakAmplitudesResamp = peakAmplitudesResamp';
	end
	
	[peakAmplitudesResampSorted,sortIdx] = sort(peakAmplitudesResamp,1,'descend');
	peakFreqsResampSorted = peakFreqsResamp(sortIdx);

	resampCorrection(end+1,1) = peakFreqsResampSorted(1) - peakFreqsSorted(1);
	
	%assign sorted peakFreqs to the resampled version 
	peakFreqsSorted = peakFreqsResampSorted;
	
      end      
        
      %obtain the annotated tempo
      [p,fstub,ext] = fileparts(flist{fidx});
      
      annotation_dir = annotation_dirs{dir_idx};
      
      regexp_struct = regexp(flist{fidx},'(?<stim_base_path>.+)/.+/wav/.+','names');
      stim_base_path = regexp_struct.stim_base_path;
      annotation_dir = regexprep(annotation_dir,'<path>',stim_base_path);
      tempo_file = regexprep(annotation_dir,'<fstub>',fstub);
      
      fid = fopen(tempo_file,'rt');
      tempo_bpm = fscanf(fid,'%f');
      fclose(fid);
      tempo_sec = tempo_bpm./60;
      
      %filename, list of peak frequencies, the highest peak, the
      %annotated tempo in beats per second
      comparison_matrix(end+1,:) = {flist{fidx},peakFreqsSorted,peakFreqsSorted(1),tempo_sec};
      
    end %for fidx
    
  end %for rp_test_dir = rp_dir_list
  
  %Accuracy1
  peakVals = [comparison_matrix{:,3}]';
  annotatedTempos =  [comparison_matrix{:,4}]';
  lowerLimits = [comparison_matrix{:,4}]' - [comparison_matrix{:,4}]'.* tolerancePercent;
  upperLimits = [comparison_matrix{:,4}]' + [comparison_matrix{:,4}]'.* tolerancePercent;
  withinToleranceMask1 = (peakVals >= lowerLimits & peakVals <= upperLimits);
  accuracyMeasurement1 = sum(withinToleranceMask1)./length(withinToleranceMask1);
  
  %Accuracy2
  withinToleranceMask2 =(    (peakVals >= lowerLimits & peakVals <= upperLimits) | ...
			     (peakVals./2 >= lowerLimits & peakVals./2 <= upperLimits) | ...
			     (peakVals.*2 >= lowerLimits & peakVals.*2 <= upperLimits) | ...
			     (peakVals./3 >= lowerLimits & peakVals./3 <= upperLimits) | ...
			     (peakVals.*3 >= lowerLimits & peakVals.*3 <= upperLimits) );
  accuracyMeasurement2 = sum(withinToleranceMask2)./length(withinToleranceMask2);
end %if(CALC_TEMPO_ESTIMATES)
  
if(CALC_ERROR_CURVE)
  
  annotatedTempos =  [comparison_matrix{:,4}]';
  errorMatrix = [abs(peakVals - annotatedTempos)./annotatedTempos ...
		 abs(peakVals./2 - annotatedTempos)./annotatedTempos ...
		 abs(peakVals.*2 - annotatedTempos)./annotatedTempos ...
		 abs(peakVals./3 - annotatedTempos)./annotatedTempos ...
		 abs(peakVals.*3 - annotatedTempos)./annotatedTempos ];
  
  errors = min(errorMatrix,[],2);
  
  precisionWindowWidth = [0:.005:.20];
  for(pidx = 1:length(precisionWindowWidth))
    windowAccuracy(pidx) = sum(errors < precisionWindowWidth(pidx))./length(errors);
  end
  
  figure(1);
  plot(precisionWindowWidth*100,windowAccuracy*100);
  set(gca,'xtick',[0:2:20]);
  set(gca,'xminortick','on');
  set(gca,'yminortick','on');
  title('Accuracy2 vs. precision window width','FontSize',12,'FontWeight','Bold');
  xlabel('Precision window Width (in % of correct tempo)');
  ylabel('Accuracy2 ( % )');
  
  if(SAVE_PLOTS)
    fig1Path = fullfile(plotDir,'acc2_vs_window_width_psitest.jpg');
    print(1,'-djpeg',fig1Path);
  end
  
end

if(PLOT_ERROR_HISTOGRAM)
  figure(2);
  hist(log2(peakVals./annotatedTempos),100);
  title('Histogram of ratio between estimated tempo and correct tempo','FontSize',12,'FontWeight','Bold');
  xlabel('log2(Computed Tempo/Correct Tempo)');
  ylabel('Number of instances');
  
  if(SAVE_PLOTS)
    fig2Path = fullfile(plotDir,'histogram_est_tempo_vs_correct_psitest.jpg');
    print(2,'-djpeg',fig2Path);
  end

end


if(PLOT_PERF_VS_TEMPI)
  figure(3);
  plot(annotatedTempos*60,log2(peakVals./annotatedTempos),'*');
  title(['Ratio between estimated tempo and correct tempo vs. tempo' ...
	 ' value'],'FontSize',12,'FontWeight','Bold');
  xlabel('Correct tempo');
  ylabel('log2(computed tempo/correct tempo)');
  
  if(SAVE_PLOTS)
    fig3Path = fullfile(plotDir,'performance_ratio_vs_tempi_psitest.jpg');
    print(3,'-djpeg',fig3Path);
  end
  
end
