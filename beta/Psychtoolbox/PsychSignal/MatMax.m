function [maxval] = MatMax(image)
% [maxval] = MatMax(image)
% Find the maximum value in a matrix.

maxval = max(max(image)');
