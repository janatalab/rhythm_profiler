function H = rp_entropy(data)
% 

ntrials = length(data);
H = zeros(ntrials,1)+NaN;
for itrial=1:ntrials
  curr_rp = data{itrial};
  if isempty(curr_rp)
    continue
  end
  
  nfilt = length(curr_rp);
  
  % Subtract the min of the data
  curr_rp = curr_rp - min(curr_rp);
  
  % Scale by sum of the energy in the profile to get the proportion in each
  % band.
  curr_rp = curr_rp/sum(curr_rp);

  % Remove any values that went to zero
  curr_rp(curr_rp == 0) = [];
  
  % Calculate the entropy
  H(itrial) = -sum(curr_rp.*log(curr_rp));
  
  % Normalize by the amount maximum entropy for output from this many filters
  H(itrial) = H(itrial)/log(nfilt);

end % for itrial

