function [gamut, badIndex] = DeviceToGamut(cal,device)
% [gamut, badIndex] = DeviceToGamut(cal,device)
%
% Check that device coordinates are in range [0,1].
% Force them to be so if not.  The indices of the
% out of gamut device settings are returned as 'badIndex'.
%
% DeviceToGamut has been renamed "PrimaryToGamut".  The old
% name, "DeviceToGamut", is still provided for compatability 
% with existing scripts but will disappear from future releases 
% of the Psychtoolbox.  Please use PrimaryToGamut instead.
%
% See Also: PsychCal, PsychCalObsolete, PrimaryToGamut

% 9/8/93    jms   Set global flag if there was a gamut problem.
% 9/13/93   jms   Took out the global flag and instead return
%                 a flag vector for the ones that were changed.
% 9/26/93	  dhb   Added calData argument.  It is not used, but
%                 I want to pass it through these routines generally
% 9/27/93   jms   Commented out the messages for going out of gamut.
%	3/7/94		dhb		Modified so that badIndex return respects tolerance.
% 4/5/02    dhb   Call through new naming convention.
% 4/11/02   awi   Added help comment to use PrimaryToGamut instead.
%                 Added "See Also"

[gamut,badIndex] = PrimaryToGamut(cal,device);
