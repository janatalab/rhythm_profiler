% Wrapper script for plot_dir_rhythm_profile
%
% This script calls plot_dir_rhythm_profile, which loops through
% all of the files for processing with BTB and plots them. 
% See ipem_proc_series.m and rhythm_profiler.m for further details on how
% the algorithm works. For details on the plotting, see plot_rhythmProfile.m
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author:
% Stefan Tomic

%SET TO PATH TO LOCATION OF AUDIO OR MIDI FILES
%AND SET input_file_pattern TO EITHER *.wav or *.mid
%Currently, only one type (wav or mid) can be processed during each
%run, since they require different parameters to the model and
%parameters are set at the top level.
rp_proc_dir = '/home/stefan/btb_analysis_dir/';
input_file_pattern = '*.csv';

%Remove the comment marks on the following two lines
%and set your path if you are running btb on midi files instead of
%wav files
%rp_proc_dir = '/home/stefan/midi_files/';
%input_file_pattern = '*.mid';

[pth,fn,ext] = fileparts(input_file_pattern);

dirStruct = dir(fullfile(rp_proc_dir,input_file_pattern));
fnames = {dirStruct.name};
mapped_audioFileList = check_stim_dirs(fnames,'srcroot',rp_proc_dir,'destroot',rp_proc_dir);

params.ipem.ani  = ani_paramGroups;

switch lower(ext)
 case {'.wav','.mp3'}
  params.ipem.rp   = rp_paramGroups('param_group',...
				    'reson_filterQSpacing_periodBasedDecay',...
				    'input_type','ani','gain_type','beta_distribution',...
				    'perform_mulawCompression',0);
  params.ipem.glob.process = {'ani','rp'};
  %note that the peak ratio bargraph plot is disabled for audio
  %files since the automated procedure for finding peak ratios was mainly
  %tested and used with MIDI files. In order to use the peak ratio
  %plotter, simply add 'peakRatios' to params.plot.perform.
  params.plot.perform = {'plotBands','plotBandEnergies', 'resonEnergy','meanEnergy','stdEnergy','findPeaks'};
  params.plot.inputSigType = 'wvf'; 
 
 case {'.mid','.midi'}
  params.ipem.rp   = rp_paramGroups('param_group',...
				    'reson_filterQSpacing_periodBasedDecay',...
				    'input_type','aud','gain_type','beta_distribution',...
				    'perform_mulawCompression',0);
  params.ipem.glob.process = {'rp'};

  params.plot.perform = {'resonOutput','resonEnergy','meanEnergy','stdEnergy','findPeaks','peakRatios','showInput'};
  params.plot.inputSigType = 'impulse';
  
 case {'.csv'}
  params.Fs = 30; %make sure to set this to the appropriate Fs for your csv file
  params.ipem.rp = rp_paramGroups('param_group',...
				    'reson_filterQSpacing_periodBasedDecay',...
				    'input_type','aud','gain_type','beta_distribution',...
				    'perform_mulawCompression',0,...
				    'Fs',params.Fs);
  params.ipem.rp.invertInputSig = 0;
  params.ipem.glob.process = {'rp'};
  params.plot.perform = {'resonOutput','resonEnergy','meanEnergy','stdEnergy','findPeaks','peakRatios','showInput'};
  params.plot.inputSigType = 'wvf';
  params.plot.inputPlot.normalize = 1; %only normalizes the plot,not the input signal
  params.csvDelim = '\t';
  
end

%set this to a list of calculations you wish to force recalculation
%(saved calculations with identical parameters will be overwritten)
params.ipem.glob.force_recalc = {'ani','rp'};

%list of calculations that will be saved. Currently set to all
%processed calculations
params.ipem.glob.save_calc = params.ipem.glob.process;

params.n2a_params.timingColumn = 'onset_beats';
params.n2a_params.beatsPerSec = 2;
params.n2a_params.ioiThresh = 0.050; %IOI threshold below which to remove double strikes
params.n2a_params.scaleByVelocity = 1;
params.separatePlotFiles = 1;
params.plot.freqLegend = 1;
params.plot.legendParams.minHz = 1.5;
params.plot.legendParams.maxHz = 5;
params.plot.legendParams.numKeys = 7;
params.plot.colorbar = 1;
params.plot.savePath = rp_proc_dir;
params.plot.timeTickRes = 2.0;
params.plot.timeLim = [0 15];
params.plot.numResonTicks = 15;
params.plot.maxResonFreqPlot = 10;
params.plot.plotMeans = 1;
params.plot.color = 1;
params.plot.separatePages = 0;
params.plot.savePlot = 1;
params.plot.peakFinder.thresh = 0.25;
params.plot.peakFinder.perform = {};
params.plot.peakFinder.ratioLabels = params.ipem.rp.resonatorBank.peakFinder.ratioLabels;
params.plot.peakFinder.ratioVals = params.ipem.rp.resonatorBank.peakFinder.ratioVals;
params.plot.meanEnergy.numticks = 4;
params.plot.plotFname = 'btb.ps';

plot_dir_rhythm_profile(mapped_audioFileList,params);


