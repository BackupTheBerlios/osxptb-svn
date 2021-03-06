function input = InvertGammaExpP(x,maxInput,output)
% output = InvertGammaExpP(x,input)
%
% Invert the gamma table using an extended power function.
% See Brainard, Pelli, & Robson (2001).
%
% Parameter x are the function parameters as returned
% by FitGamma/FitGammaExtP.  See ComputeGammaExtP.
%
% Parameter maxInput is the maximum device input
% value (255 for 8-bit hardware).
%
% 8/7/00   dhb      Wrote it.

thePow = x(1);
theOffset = x(2);

input = round( ((maxInput-theOffset)*(output.^(1/thePow))) + theOffset);

