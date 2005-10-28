function [settings,badIndex] = LinearToSettings(cal,linear)
% [settings,badIndex] = LinearToSettings(cal,linear)
%
% Convert from linear color space coordinates to device
% setting coordinates.
%
% This depends on the standard calibration globals.
%
% LinearToSettings has been renamed "SensorToSettings".  The old
% name, "LinearToSettings", is still provided for compatability 
% with existing scripts but will disappear from future releases 
% of the Psychtoolbox.  Please use SensorToSettings instead.
%
% See Also: PsychCal, PsychCalObsolete, SensorToSettings

% 9/26/93    dhb   Added calData argument, badIndex return.
% 4/5/02     dhb, ly  Call through new interface.
% 4/11/02    awi   Added help comment to use SensorToSettings instead.
%                  Added "See Also"

[settings,badIndex] = SensorToSettings(cal,linear);


