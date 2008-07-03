function previousCalcFname = findRP(params)
% finds a rhythm profile with specified parameters

ensemble_globals;

%fill in missing ipem params with defaults
ipemDefaultParams = ipem_proc_series('getDefaultParams');
missingAniFields = setdiff(fieldnames(ipemDefaultParams.ani),fieldnames(params.ani));
missingRpFields  = setdiff(fieldnames(ipemDefaultParams.rp),fieldnames(params.rp));

for iField = 1:length(missingAniFields)
  params.ani.(missingAniFields{iField}) = ipemDefaultParams.ani.(missingAniFields{iField});
end
for iField = 1:length(missingRpFields)
  params.rp.(missingRpFields{iField}) = ipemDefaultParams.rp.(missingRpFields{iField});
end

[path,fstub,ext] = fileparts(params.stimLocation);
ipem_path = fullfile(stimulus_ipem_analysis_root,path,fstub);
rpPath = fullfile(ipem_path,'rp');

fprintf('Looking for rp match....');
clear matchParams;
matchParams.varName = 'rp';
matchParams.paramFind.ani = params.ani;
matchParams.paramFind.rp  = params.rp;
matchParams.ignore = {'ani.aniPath'};  
previousCalcFname = check_anal_exist(rpPath,matchParams);
if(previousCalcFname)
  fprintf('Found.\n');
else
  fprintf('Not Found.\n');
end
