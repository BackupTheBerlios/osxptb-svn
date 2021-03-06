function [output] = Trunc(input)
% [output] = Trunc(input)
% Truncate to range [0-1].

output = input;
index = find( input < 0 );
if (length(index) > 0);
  output(index) = zeros(length(index),1);
end
index = find( input > 1 );
if (length(index) > 0)
  output(index) = ones(length(index),1);
end

