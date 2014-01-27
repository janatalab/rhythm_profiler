function [metricOnly_resEnergy metricNonmetric_resEnergy_ratio metricReson_mask] = isolate_peak_resons(varargin)

% outData = isolate_RP_resons('stimRP',stimRP_st,'targetRP',targRP)
% 
% Isolates frequency bands from reson energy matrix that correspond to a set 
% of frequency peaks, as produced by Rhythm Profiler. Allows one to assess 
% energy at periodicities corresponding to a stimulus' metric structure. Also 
% allows one to assess the ratio of metric to non-metric energy (useful for
% mocap data, which often contain a considerable amount of energy unrelated 
% to a stimulus).
%
% Input
%   'stimRP': rp struct for rhythm profile from which peaks will be extracted
%   'targetRP': rp struct that will be pared down based on stimRP peaks
%   'calcRatio': set to 1 if metric/nonmetric energy ratio calculation is desired. Set to 0 otherwise.
% Output
%   metricOnly_resEnergy: reson energy matrix with containing only the energy from metric (peak) resonators
%   tactusOnly_resEnergy: reson energy matrix containing only the energy from 
%                         the tactus (highest peak) resonator (and the surrounding
%                         resonators, depending on peak width)
%   metricNonmetric_resEnergy_ratio: ratio of metric to non-metric energy.
%                         This variable is empty if calcRatio set to 0.
%
% Oct 28, 2012 BH - created function
% Dec 05, 2012 BH - added option to calculate metric to non-metric energy ratio

for iarg = 1:2:length(varargin)
    
    switch(varargin{iarg})
        case 'stimRP'
            stimRP_st = varargin{iarg+1};
        case 'targetRP'
            targRP = varargin{iarg+1};
        case 'calcRatio'
            calcRatio = varargin{iarg+1};
    end
    
end

% Get freq peak info from stimRP
stimRP_cols = set_var_col_const(stimRP_st.vars);
stimResonFreqs = stimRP_st.data{stimRP_cols.resonatorFreqs};
nresons = length(stimResonFreqs);
stimPeakInfo = stimRP_st.data{stimRP_cols.peakInfo};
stimPeak_cols = set_var_col_const(stimPeakInfo.vars);
stimPeak_freqs = stimPeakInfo.data{stimPeak_cols.peakFreq};
npeaks = length(stimPeak_freqs);
stimPeakIdx = stimPeakInfo.data{stimPeak_cols.peakIdxs};
% find peak corresponding to tactus (highest peak should be tactus, which gives approxRatio of 1)
stim_tactusPeakIdx = strmatch('1',stimPeakInfo.data{stimPeak_cols.approxRatio},'exact');
stimPeakWidth = stimPeakInfo.data{stimPeak_cols.width}; 

% Use peak width to determine whether more than one resonator should be
% included for each peak. Useful if width of some peaks overlap multiple 
% resonators.

isolateResonIdxs = [];
for ipeak = 1:npeaks
    curr_peakFreq = stimPeak_freqs(ipeak);
    curr_peakWidth = stimPeakWidth(ipeak);
    peakRange = [-1 1]*curr_peakWidth/2 + curr_peakFreq;
    
    % catch situations in which first or last value of peakRange is beyond the range of stimResonFreqs
    if peakRange(1) < stimResonFreqs(1)
        peakRange(1) = stimResonFreqs(1);
    elseif peakRange(2) > stimResonFreqs(end)
        peakRange(2) = stimResonFreqs(end);
    end
    idxs = find(stimResonFreqs <= min(peakRange),1,'last'):find(stimResonFreqs >= max(peakRange),1,'first');
    isolateResonIdxs = union(isolateResonIdxs, idxs);
    % if current peak is tactus, get corresponding reson indices
    if ipeak == stim_tactusPeakIdx
        stim_tactusResonIdxs = idxs;
    end
    
end

% logical mask for metric resonators
metricReson_mask = ismember(1:nresons,isolateResonIdxs);

% Now, reduce target average periodicity surface matrix down to reson_Idx
% resonators
targRP_cols = set_var_col_const(targRP.vars);
targResEnergy = targRP.data{targRP_cols.resonatorEnergy};
metricOnly_resEnergy = targResEnergy(isolateResonIdxs,:);
% metricOnly_APS = zeros(size(targResEnergy));
% metricOnly_APS(isolateResonIdxs,:) = targResEnergy(isolateResonIdxs,:); % zeroing out rows corresponding to non-peak resons rather than removing rows altogether
% tactusOnly_resEnergy = targResEnergy(stim_tactusResonIdxs,:);

% If desired, calculate ratio of metric to nonmetric energy
if calcRatio
    %calculate ratio here
    nonMetricEnergy = targResEnergy;
    nonMetricEnergy(isolateResonIdxs,:) = [];
    metricNonmetric_resEnergy_ratio = mean(metricOnly_resEnergy)./mean(nonMetricEnergy);
    
%     % for plotting APS minus non-metric reson energy
%     nonMetricAPS = targResEnergy;
%     nonMetricAPS(isolateResonIdxs,:) = -(maxResEnergy/6);
    
else
    metricNonmetric_resEnergy_ratio = [];
end

return