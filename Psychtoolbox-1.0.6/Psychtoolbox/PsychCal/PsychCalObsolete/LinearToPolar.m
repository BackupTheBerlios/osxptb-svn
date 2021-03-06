function [pol] = LinearToPolar(cal,linear)
% [pol] = LinearToPolar(cal,[linear])
%
% Converts from linear rectangular coordinates to polar
% coordinates.
%
% Polar coordinates are defined as radius, azimuth, and elevation.
%
% LinearToPolar has been renamed "SensorToPolar".  The old
% name, "LinearToPolar", is still provided for compatability 
% with existing scripts but will disappear from future releases 
% of the Psychtoolbox.  Please use SensorToPolar instead.
%
% See Also: PsychCal, PsychCalObsolete, SensorToPolar

% 9/9/93			jms		It didn't work for matrix inputs, because a 
%										matrix '^' needed to be a by-element '.^'
% 9/26/93			dhb   Added calData argument.
% 2/6/94			jms   Changed 'polar' to 'pol'
% 2/20/94			jms   Added single argument case to avoid cData
% 4/6/96			dhb		Fixed bug noted by ccc.  Need to use four quadrant
%										arctangent atan2().
% 5/20/98     dhb   Fix little bug, make sure index is not empty.
% 4/5/02      dhb, ly  Call through new interface.
% 4/11/02     awi   Added help comment to use SensorToPolar instead.
%                   Added "See Also"
% 4/25/02     dhb   Fixed typo introduced in conversion.


if (nargin==1)
  pol = SensorToPolar(cal);
else
	pol = SensorToPolar(cal,linear);
end
