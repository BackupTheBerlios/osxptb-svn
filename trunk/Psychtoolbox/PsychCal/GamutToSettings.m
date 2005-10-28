function [settings,values] = GamutToSettings(cal,gamut)
% [settings,values] = GamutToSettings(cal,gamut)
%
% Find the best integer device settings to produce
% the passed linear device coordinates.
% 
% The passed coordinates should be in the range [0,1].
% The returned settings run from [0,nlevels-1], where nlevels
% is the number of quantized levels available on the device.
%
% The returned argument values is what you actually should
% get after quantization error.
%
% The routine depends on the calibration globals.

% 9/26/93    dhb   Added calData argument.
% 10/19/93   dhb   Allow gamma table dimensions to exceed device settings.
% 11/11/93   dhb   Update for new calData routines.
% 8/4/96     dhb   Update for stuff bag routines.
% 8/21/97    dhb   Update for structures.
% 4/13/02	 awi   Replaced SettingsToDevice with new name SettingsToPrimary

% Get gamma table
gammaTable = cal.gammaTable;
gammaMode = cal.gammaMode;
if isempty(gammaTable)
	error('No gamma table present in calibration structure');
end
if isempty(gammaMode)
	error('SetGamma has not been called on calibration structure');
end

if gammaMode==0
	[settings,values] = GamutToSettingsSch(gammaTable,gamut);
elseif gammaMode==1
	iGammaTable = cal.iGammaTable;
	if isempty(iGammaTable)
		error('Inverse gamma table not present for gammaMode == 1');
	end
	settings = GamutToSettingsTbl(iGammaTable,gamut);
	if nargin==2
		values = SettingsToPrimary(cal,settings);
	end
else
	error(sprintf('Requested gamma inversion mode %g is not yet implemented',gammaMode));
end
