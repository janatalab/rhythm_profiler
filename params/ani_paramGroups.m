function ani = ani_paramGroups
% Returns ani parameter structure commonly used for BTB algorithm
%
% Copyright (c) 2007-2012 The Regents of the University of California
% All Rights Reserved

% Author(s):
% Stefan Tomic
% 08Jan2014 PJ - added call to calc_ani to get default parameters

ani = calc_ani('getDefaultParams');

ani.PlotFlag = 0;
ani.DownSampleFactor = 5;
ani.normalize_wav = 1;
ani.start_time_sec = [];
ani.dur_sec = [];