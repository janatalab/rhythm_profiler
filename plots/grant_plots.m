LOAD_RP = 1;
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

for(ifile = 1:length(rp_mat_files));

  if(LOAD_RP)
    if(~exist('rp'))
      rp=init_rp;
    else
      rp(ifile) = init_rp;
    end

    load(fullfile(RP_PATH,rp_mat_files{ifile}));
    rp(ifile) = rp_save;
  end

  rp_params = sscanf(rp(ifile).filename,'parts_%d_levels_%d_m_%d.wav');

  %extract the number of instruments and number of metrics for this rp
  %number of metrics is the number of digits in the code (i.e. 432 means three
  %levels. The value of each digit specifies which level was used.)
  current_inst = rp_params(1);
  current_metric = length(num2str(rp_params(2)));


  %entropy_mat(current_inst,current_metric) = rp(ifile).H3;
  entropy_by_measure(current_inst,current_metric,:) = rp(ifile).H;
  
  ent_measure_channel(current_inst,current_metric,:,:) = rp(ifile).H2;
  

end
