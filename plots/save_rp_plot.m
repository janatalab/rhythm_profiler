% script to save any rp plot to file
%
%
% Copyright (c) 2008 The Regents of the University of California
% All Rights Reserved
%
%
% Author:
% 12/11/2008 First Version, Stefan Tomic

[pth,fstub,ext] = fileparts(params.plotFname);
if(params.separatePages)
  pfname = [fstub fstubTag ext];
  print(params.format,fullfile(params.savePath,pfname));
else
  pfname = [fstub ext];
  print(params.format,'-append',fullfile(params.savePath,pfname));
end
disp(sprintf('Writing new plots to %s\n\n',fullfile(params.savePath,pfname)));      
