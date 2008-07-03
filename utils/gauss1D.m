function E = gauss1D(x, x0, FWHM, order)
%GAUSS: Creates a gaussian function.
%
%   E = gauss(x, FWHM, order)
%     = exp(-log(2)*(2*(x-x0)./FWHM).^(2*floor(abs(order))));
%
%	x		= Domain
%	x0		= Centre position
%	FWHM	= Full width half max
%	order	= Gaussian order
%
%	v1.0

E = exp(-log(2)*(2*(x-x0)./FWHM).^(2*floor(abs(order))));