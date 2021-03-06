function [pol] = SettingsToPolar(cData,settings)
% [pol] = SettingsToPolar(cData,settings)
%
% Convert from device setting coordinates to
% linear color space coordinates.
%
% INPUTS:
%   settings -- device settings
%
% SettingsToPolar is obsolete.  Instead, use a combination
% of SettingsToSensor and SensorToPolar to achieve the same
% result.  For example, instead of: 
%
% pol = SettingsToPolar(cData,settings);
%
% use:
%
% linear = SettingsToSensor(cData,settings);
% pol = SensorToPolar(cData,linear);
%
% See Also: PsychCal, PsychCalObsolete, SettingsToSensor, SensorToPolar

%
% 9/26/93    dhb   Added calData argument.
% 2/6/93     jms   Changed 'polar' to pol
% 4/11/02    awi   Added help comment to use SettingsToSensor+SensorToPolar instead.
%                 Added "See Also"


linear = SettingsToLinear(cData,settings);
pol = LinearToPolar(cData,linear);
