function [coneInc] = DKLToConeInc(dkl,bg)
% [coneInc] = DKLToConeInc(dkl,bg)
%
% Convert from DKL to incremental cone coordinates.
%
% The code follows that published by Brainard
% as an appendix to Human Color Vision by Kaiser
% and Boynton.
%
% 8/30/96	dhb		Converted this from script.

% Compute conversion matrix
M = ComputeDKL_M(bg);

% Multiply the vectors we wish to
% convert by M to obtain its DKL coordinates.
coneInc = inv(M)*dkl;




						 

