function outData = plot_dir_rhythm_profile(inData,params)
% Runs the BTB algorithm and plots the resulting periodicity surfaces
%
% outData = plot_dir_rhythm_profile(inData,params)
%
% Cycles through a list of wav or midi files and plots resonator
% outputs, average periodicity surfaces, band periodicity surfaces,
% and mean periodicity profiles. Any subset of these will be plotted
% depending on how the params are set. This function calls
% ipem_proc_series to either find an existing saved calculation or
% to calculate new ANI and rp, so this function may be used to
% perform the calculations as well as plotting.
%
% INPUT/PARAMS 
%  inData: cell array of files to cycle through. Expects the full
%          paths of the files
%  params.plot.savePath:     directory where the plot(s) should be saved
%  params.plot.plotFname:    filename where the plot(s) should be saved
%  params.separatePlotFiles: flag (0 or 1) that determines whether
%                            or not an extra filename should be 
%                            tagged to the plot name (for
%                            separating plots for each input wav 
%                            or midi file)
%  params.ipem:              parameter structure for
%                            ipem_proc_series. The data structures
%                            for ani and rp calculations will
%                            either be searched for and found, or
%                            will be calculated. params.ipem.glob,
%                            params.ipem.ani, params.ipem.rp each
%                            should be populated with the desired
%                            ipem parameters (see ipem_proc_series)
%
% Copyright (c) 2007 The Regents of the University of California
% All Rights Reserved
%
% Author(s):
% Stefan Tomic 8/07

if(~isfield(params,'separatePlotFiles'))
  params.separatePlotFiles = 0;
end

plotFile = fullfile(params.plot.savePath,params.plot.plotFname);
[p,plotFStub,plotext] = fileparts(plotFile);
if(params.plot.savePlot  & exist(plotFile))
    
  confirmOverwrite = '';
  while(~ismember(confirmOverwrite,{'y','n'}))
    confirmOverwrite = input(sprintf('File %s exists, overwrite? (y/n): ',plotFile),'s');
  end
  
  if(strcmp(confirmOverwrite,'y'))
    delete(plotFile);
  else
    disp('OK, not saving the plot. It will be displayed on the screen.');
    params.plot.savePlot = 0;
  end
  
end
  

fList = inData;
nFiles = length(fList);

for iFile = 1:nFiles;
 
  thisLocation = fList{iFile};
  [path,fstub,ext] = fileparts(thisLocation);
  
  rpPath = fullfile(path,fstub,'rp');
  
  params.plot.fig.title = sprintf('%s',[fstub ext]);
  params.plot.inDataPath = fullfile(path,fstub);

  clear inputPlotData;
  clear audStruct;

  switch(ext)
   case '.wav'

    pa = params_aud('path',path,'filename',[fstub ext]);
    audStruct = new_aud(pa);
    inputPlotData = {audStruct};
   case {'.mid','*.midi'}
    
    params.n2a_params.Fs = params.ipem.rp.Fs;
    nmat_cols = nmat_columns;
    tr = javamidi2tr(thisLocation);
    %unique midi notes are used to differentiate left and right hands in
    %our current tapping trials
    unique_midi_notes = unique(tr.nmat(:,nmat_cols.midi_pitch));
    trialSets = [];
    %separate left and right hands for plotting the input
    for inote = 1:length(unique_midi_notes)
      params.n2a_params.extractNotes = unique_midi_notes(inote);
      inputPlotData{inote} = nmat2aud(tr.nmat,params.n2a_params);
      trialSets = [trialSets;inote mod(inote-1,2)+1];
      params.plot.trialSets = trialSets;
    end
    %create an aud struct for inputting to a resonator bank (both hands)
    params.n2a_params.extractNotes = unique_midi_notes;
    audStruct = nmat2aud(tr.nmat,params.n2a_params);
    audStructCols = set_var_col_const(audStruct.vars);
    audStruct.data{audStructCols.path} = path;
    audStruct.data{audStructCols.filename} = [fstub ext];
  end

  %params.ipem.glob.force_recalc = {};
  %params.ipem.glob.save_calc = params.ipem.glob.process;
  disp('Running ipem_proc_series...');
  ipemOut = ipem_proc_series(audStruct,params.ipem);
  disp('Finished ipem_proc_series...');
  ipemOutCols = set_var_col_const(ipemOut.vars);
  
  rp = ipemOut.data{ipemOutCols.rp}{1};
  
  clear plotData;
  plotData{1} = rp;
  plotData(2:length(inputPlotData)+1) = inputPlotData;
  
  if(params.separatePlotFiles)
    params.plot.plotFname = [plotFStub '_' fstub plotext];
  else
    params.plot.appendToPlot = 1;
  end
  
  plot_rhythmProfile(plotData,params.plot);
  
end

outData = plotFile;

return

