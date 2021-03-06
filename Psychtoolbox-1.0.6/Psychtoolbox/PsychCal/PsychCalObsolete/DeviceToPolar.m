function [pol] = DeviceToPolar(cal,device)
% [pol] = DeviceToPolar(cal,device)
%
% Convert from linear device coordinates to polar color 
% space coordinates.  The ambient lighting is added to
% the color space coordinates of the device.
%
% This depends on the standard calibration globals.
%
% DeviceToPolar is obsolete.  Instead, use a combination
% of PrimaryToSensor and SensorToPolar to achieve the same
% result.  For example, instead of: 
%
% pol = DeviceToPolar(cal,device);
%
% use:
%
% linear = PrimaryToSensor(cal,device);
% pol = SensorToPolar(cal,linear);
%
% See Also: PsychCal, PsychCalObsolete, PrimaryToSensor, SensorToPolar

%
% 9/26/93    dhb   Added calData argument.
% 2/6/94     jms   Changed 'polar' to 'pol'
% 4/11/02   awi   Added help comment to use PrimaryToSensor +  SensorToPolar instead.
%                 Added "See Also"


linear = DeviceToLinear(cal,device);
pol = LinearToPolar(cal,linear);

