function [minval] = MatMin(image)
% [minval] = MatMin(image)
% Find the minumum value in a matrix.

minval = min(min(image)');
