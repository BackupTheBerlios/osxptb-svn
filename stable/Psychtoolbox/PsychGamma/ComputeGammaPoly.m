function output = ComputeGammaPoly(x,input)
% output = ComputeGammaPoly(x,input)
%
% Compute gamma table using polynomial function.
% Relies on Matlab's built-in polyeval
%
% 10/3/93  dhb,jms  Normalize output to max of 1.
%                   Better be sure that last value is max setting.
% 10/4/93  dhb      Force monotonicity

% Create entire input stream.  Assumes last value of input is 
% maximum intensity, which is true in our gamma routines.
[m,n] = size(input);
maxVal = input(m);
fullInput = (0:maxVal)';

% Compute output on full range, make it monotonic.
xP = [x ; 0];
fullOutput = MakeMonotonic(HalfRect(polyval(xP',fullInput)));
if (max(fullOutput) ~= 0)
  fullOutput = NormalizeGamma(fullOutput);
end

% Select out just what was requested
output = fullOutput(input+1);
