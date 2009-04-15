function eyeLengthMM = EyeLength(species,source)
% eyeLengthMM = EyeLength(species,source)
%
% Return the length of the eye in mm.  Length is taken as distance
% between nodal point and fovea.  For foveal stimuli, this length
% may be used to convert between degrees of visual angle and mm/um
% of retina.  Since the nodal point isn't at the center of eye,
% the same conversion doesn't work for extrafoveal stimuli.
%
% Supported species:
%		Human (Default), Rhesus, Dog
%
% Supported sources:
%   LeGrand (Human, Default)
%   Rodieck (Human)
%   PerryCowey (Rhesus)
%   Packer (Rhesus)
%   PennDog (Dog)
%   None
%
% Passing a numeric value as source returns that value as the
% estimate, independent of species.  This is a hack that allows
% some debugging.
%
% Passing None is appropriate as an error check -- if a calculation
% uses the eye length when none is passed, NaN's will show up in
% the answer.
%
% 7/15/03  dhb  Wrote it.
% 

% Fill in defaults
if (nargin < 1 | isempty(species))
	species = 'Human';
end
if (nargin < 2 | isempty(source))
	source = 'LeGrand';
end

% Handle case where a number is passed.
if (~isstr(source))
	eyeLengthMM = source;
	return;
end

% Handle case where 'None' is passed.
if (streq(source,'None'))
	eyeLengthMM = NaN;
	return;
end

% Fill in length according to species, source
switch (source)
  % I took the LeGrand number from Wyszecki and Stiles' description of
  % his model eye.
	case {'LeGrand'}
		switch (species)
			case {'Human'}
				eyeLengthMM = 16.6832;
			otherwise,
				error(sprintf('%s estimates not available for species %s',source,species));
			end

	% Rodieck's standard observer, from Appendix B, The First Steps of Seeing.
	case {'Rodieck'}
		switch (species)
			case {'Human'}
				eyeLengthMM = 16.1;
			otherwise,
				error(sprintf('%s estimates not available for species %s',source,species));
			end

	% Orin Packer provided me with this information:
    % Monkey eye size varies a lot, so any particular number
    % is bound to be in error most of the time, sometimes substantially.
    % That said, I usually reference Perry & Cowey (1985) (Vis Res 25, 1795-1810).
    % For rhesus they report an eye diameter of 20 mm and a posterior nodal
    % distance of 12.8 mm.
	case {'PerryCowey'}
		switch (species)
			case {'Rhesus'}
				eyeLengthMM = 12.8;
			otherwise,
				error(sprintf('%s estimates not available for species %s',source,species));
			end

	% Orin Packer also said: For the fovea I usually use a conversion factor of
    % 210 um/degree which is the average of Perry & Cowey, Rolls & Cowey (1970)
    % (exp Br. Res., 10, 298) and deMonasterio et al (1985) (IOVS 26, 289-302).
    % This corresponds to 12.0324 mm.
	case {'Packer'}
		switch (species)
			case {'Rhesus'}
				mmPerDegree = 210*1e-3;
				eyeLengthMM = 0.5*mmPerDegree/atan((pi/180)*0.5);
			otherwise,
				error(sprintf('%s estimates not available for species %s',source,species));
        end

    % PennDog
    case {'PennDog'}
		switch (species)
			case {'Dog'}
				eyeLengthMM = 15;
			otherwise,
				error(sprintf('%s estimates not available for species %s',source,species));
        end
        
	otherwise
		error(sprintf('Unknown source %s for eye length estimates',source));
end
