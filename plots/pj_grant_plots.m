LOAD_RP = 0;
SUMMARY_STATS = 1;
RP_PATH =  '/nfs/torus2/rhythm_grant/RP';
num_inst = 4;
num_metrics = 6;
num_measures = 20;
num_channels = 40;

dir_contents = dir(fullfile(RP_PATH,'*mat'));
rp_mat_files = cell(1,length(dir_contents));
[rp_mat_files{:}] = deal(dir_contents.name);


entropy_mat = zeros(num_inst,num_metrics);
entropy_by_measure = zeros(num_inst,num_metrics,num_measures);
ent_measure_channel = zeros(num_inst,num_metrics,num_channels,num_measures);

nfiles = length(rp_mat_files);

if LOAD_RP
  for ifile = 1:nfiles

    if(~exist('rp'))
      % rp=init_rp;
    else
      % rp(ifile) = init_rp;
    end

    rp_fname = fullfile(RP_PATH,rp_mat_files{ifile});
    fprintf('Loading data from file: %s\n', rp_fname);
    load(rp_fname);
    rp(ifile) = rp_save;
  end % for ifile
end % if LOAD_RP

% Get indices into the output matrices
for ifile = 1:nfiles
  rp_params = sscanf(rp(ifile).filename,'parts_%d_levels_%d_m_%d.wav');

  %extract the number of instruments and number of metrics for this rp
  %number of metrics is the number of digits in the code (i.e. 432 means three
  %levels. The value of each digit specifies which level was used.)
  rp(ifile).ninst = rp_params(1);
  rp(ifile).nlevels = length(num2str(rp_params(2)));
end

% Spit out some summary statistics
if SUMMARY_STATS
  total_rms = zeros(num_inst,num_metrics);
  total_combOut = zeros(num_inst,num_metrics);
  num_filtOutPeaks = zeros(num_inst,num_metrics);
  
  fprintf('\nCalculating overall energy statistics ...\n');
  
  for cf=1:nfiles
    fprintf('\t%s\n', rp(cf).filename);
    ci = rp(cf).ninst;
    cl = rp(cf).nlevels;
    
    total_rms(ci,cl) = sum(rp(cf).rms(:));
    total_combOut(ci,cl) = sum(rp(cf).combOut(:));
    num_filtOutPeaks(ci,cl) = sum(rp(cf).filtOutPeaks(:));
  end % for ifile=1:nfiles
  
end % if SUMMARY_STATS

return

  %entropy_mat(current_inst,current_metric) = rp(ifile).H3;
  entropy_by_measure(current_inst,current_metric,:) = rp(ifile).H;
  
  ent_measure_channel(current_inst,current_metric,:,:) = rp(ifile).H2;
