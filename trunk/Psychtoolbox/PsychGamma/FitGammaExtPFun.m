function [err,con] = FitGammaExtPFun(x,values,measurements)
% [err,con] = FitGammaExtPFun(x,values,measurements)
% 
% Error function for power function fit.
%
% 9/21/93  DHB  Added positivity constraint.

predict = ComputeGammaExtP(x,values);
err = ComputeRMSE(measurements,predict);
con = [-x];
