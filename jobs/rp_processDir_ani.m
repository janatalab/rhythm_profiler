%test script for beat algorithm

globals = rhythmTap_globals;


CALC_RP = 0;
PLOT_RP = 1;
PLOT_RPSTAGES = 0;

params = cell(0);
filetype = '.wav';

%directory with files to analyze
%rp_test_dir = '/data2/rhythm/rhythm_profiler/tests/audio_files/meter_tests2';
%rp_test_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/groove_sequencer_tests';
%rp_dir_list = {'/afs/cmb.ucdavis.edu/share/petrlab/rhythm_profiler/plots/groove_seq_presets_90bpm'};
rp_dir_list = {'/data2/rhythm/rhythm_profiler/martens_sq_study_audio'};
for rp_test_dir = rp_dir_list

  rp_test_dir = rp_test_dir{1};
  dirStruct = dir(fullfile(rp_test_dir,'*.wav'));
  fnames = {dirStruct.name};
  flist = check_stim_dirs(fnames,'srcroot',rp_test_dir,'destroot',rp_test_dir);
  params{1}.ipem = globals.stimIPEMParams;
  %CHANGED MAXVAL FOR ISMIR STIMS (PROBABLY NOT TOO IMPORTANT)
  %params{1}.ipem.ani.normalize_maxVal = 0.9;
  params{1}.ipem.rp.resonatorBank.peakFinder.errorTolerance = .15;
  params{1}.ipem.rp.resonatorBank.peakFinder.ratioVals = ...
      [ 1/16 1/10 1/8 1/6 1/5 1/4 1/3 3/8 2/5 1/2 3/5 5/8 2/3 3/4 4/5 5/6 7/8 1 5/4 4/3 ...
	3/2 5/3 2 5/2 3:8];
  params{1}.ipem.rp.resonatorBank.peakFinder.ratioLabels = ...
      { '1/16' '1/10' '1/8' '1/6' '1/5' '1/4' '1/3' '3/8' '2/5' '1/2' '3/5' '5/8' '2/3' '3/4' ...
	'4/5' '5/6' '7/8' '1' '5/4' '4/3' '3/2' '5/3' '2' '5/2' '3' '4' '5' '6' '7' '8' };
  
  
  if(CALC_RP)
    ipemOut = ipem_proc_series(flist,params{1}.ipem);
    ipemOutCols = set_var_col_const(ipemOut.vars);
    aniList = ipemOut.data{ipemOutCols.ani};
    rpList = ipemOut.data{ipemOutCols.rp};
  end
  
  for iFile = 1:length(fnames)
    [p,fname,ext] = fileparts(fnames{iFile});
    flistPath{iFile} = fullfile(rp_test_dir,[fname '.wav']);
  end
  
  if(PLOT_RP)
    params{2}.ipem.glob = params{1}.ipem.glob;
    params{2}.ipem.ani  = params{1}.ipem.ani;
    params{2}.ipem.rp   = params{1}.ipem.rp;
    params{2}.n2a_params.timingColumn = 'onset_beats';
    params{2}.n2a_params.beatsPerSec = 2;
    params{2}.separatePlotFiles = 1;
    params{2}.plot.freqLegend = 1;
    params{2}.plot.legendParams.minHz = 1.5;
    params{2}.plot.legendParams.maxHz = 5;
    params{2}.plot.legendParams.numKeys = 7;
    params{2}.plot.colorbar = 1;
    params{2}.plot.savePath = rp_test_dir;
    params{2}.plot.timeTickRes = 2.0;
    params{2}.plot.numResonTicks = 15;
    params{2}.plot.maxResonFreqPlot = 10;
    params{2}.plot.plotMeans = 1;
    params{2}.plot.color = 1;
    params{2}.plot.separatePages = 1;
    params{2}.plot.savePlot = 1;
    params{2}.plot.showInput = 0;
    params{2}.plot.timeLim = [2 10];
    params{2}.plot.inputSigType = 'impulse';
    params{2}.plot.peakFinder.thresh = 0.25;
    params{2}.plot.peakFinder.thresh = 0;
    params{2}.plot.peakFinder.perform = {};
    params{2}.plot.peakFinder.minPeakHeight = 0.1;
    params{2}.plot.peakFinder.errorTolerance = .15;
    params{2}.plot.peakFinder.ratioVals = params{1}.ipem.rp.resonatorBank.peakFinder.ratioVals;
    params{2}.plot.peakFinder.ratioLabels = params{1}.ipem.rp.resonatorBank.peakFinder.ratioLabels;
    params{2}.plot.peakFinder.perform = {};
    params{2}.plot.meanEnergy.numticks = 4;
    params{2}.plot.perform = {'resonEnergy','meanEnergy','stdEnergy','findPeaks','ratioProb'};
    params{2}.plot.plotFname = 'metric_profiles.ps';
    plot_dir_rhythm_profile(flist,params{2});
  end

  if(PLOT_RPSTAGES)
    for irp = 1:length(rpList)
      inData{1} = aniList{irp};
      inData{2} = rpList{irp};
      rpStagesParams.fpath = fullfile(rp_test_dir,'rpStages_bw.ps');
      plot_rpStages2(inData,rpStagesParams);
    end
  end
  
end %for rp_test_dir = rp_dir_list
