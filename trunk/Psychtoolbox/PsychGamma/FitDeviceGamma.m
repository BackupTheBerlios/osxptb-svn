function [gammaFit,gammaInputFit,fitComment] = ...
  FitDeviceGamma(gammaRaw,gammaInputRaw,fitType)
% function [gammaFit,gammaInputFit,fitComment] = ...
%   FitDeviceGamma(gammaRaw,gammaInputRaw,[fitType])
%
% Fit the measured gamma function.  Appends 0 measurement,
% arranges data for fit, etc.
% 
% The returned gamma functions are normalized to a maximum of 1.
%
% If present, argument fitType is passed on to FitGamma.

% Extract device characteristics
[n,m] = size(gammaRaw);
nDevices = m;
nInputLevels = gammaInputRaw(n)+1;

% Fit gamma curve
gammaInputFit = (0:nInputLevels-1)';
if (gammaInputRaw(1) ~= 0)
  gammaInputRaw = [0 ; gammaInputRaw];
  gammaRaw = [zeros(1,nDevices) ; gammaRaw];
end
gammaRawN = NormalizeGamma(gammaRaw);
if (nargin == 3)
  [gammaFit,xFit,fitComment] = FitGamma(gammaInputRaw,gammaRawN,...
                                 gammaInputFit,fitType);
else
  [gammaFit,xFit,fitComment] = FitGamma(gammaInputRaw,gammaRawN,...
                                 gammaInputFit);
end

