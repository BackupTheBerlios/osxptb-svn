% RefitCalLinMod
%
% Refit the calibration linear model.
%
% 3/27/02  dhb  Wrote it.

% Enter load code
fprintf(1,'\nLoad codes:\n\t0 - screenX.mat\n\t1 - string.mat\n\t2 - default.mat\n');
loadCode = input('	Enter load code [0]: ');
if (isempty(loadCode))
	loadCode = 0;
end
if (loadCode == 1)
	defaultFileName = 'monitor';
	thePrompt = sprintf('Enter calibration filename [%s]: ',defaultFileName);
	newFileName = input(thePrompt,'s');
	if (isempty(newFileName))
  	newFileName = defaultFileName;
	end
end

% Load the structure
if (loadCode == 0)
	defaultScreen = 1;
	whichScreen = input(sprintf('Which screen to calibrate [%g]: ',defaultScreen));
	if (isempty(whichScreen))
		whichScreen = defaultScreen;
	end
	fprintf(1,'\nLoading for screen%g.mat\n',whichScreen);
	cal = LoadCalFile(whichScreen);
	fprintf('Calibration file read for screen %g\n\n',whichScreen);
elseif (loadCode == 1)
	fprintf(1,'\nLoading from %s.mat\n',newFileName);
	cal = LoadCalFile(newFileName);
	fprintf('Calibration file %s read\n\n',newFileName);
elseif (loadCode == 2)
	fprintf(1,'\nLoading from default.mat\n');
	cal = LoadCalFile;
	fprintf('Read default calibration file %s read\n\n',newFileName);
else
	error('Illegal value for save code entered');
end

% Print out some information from the calibration.
DescribeMonCal(cal);

% Provide information about gamma measurements
% This is probably not method-independent.
fprintf('Gamma measurements were made at %g levels\n',...
	size(cal.rawdata.rawGammaInput,1));
fprintf('Gamma table available at %g levels\n',...
	size(cal.gammaInput,1));

% Get new fit type
fprintf('Old linear model fit was with %g components\n',cal.nPrimaryBases);
oldN = cal.nPrimaryBases;
cal.nPrimaryBases = input('Enter new number of components: ');
if (isempty(cal.nPrimaryBases))
	cal.nPrimaryBases = oldN;
end
cal = CalibrateFitLinMod(cal);
cal = CalibrateFitGamma(cal);

% Put up a plot of the essential data
figure(1); clf;
plot(SToWls(cal.S_device),cal.P_device);
xlabel('Wavelength (nm)', 'Fontweight', 'bold');
ylabel('Power', 'Fontweight', 'bold');
title('Phosphor spectra', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
axis([380,780,-Inf,Inf]);

figure(2); clf;
plot(cal.rawdata.rawGammaInput,cal.rawdata.rawGammaTable(:,1:cal.nDevices),'+');
xlabel('Input value', 'Fontweight', 'bold');
ylabel('Normalized output', 'Fontweight', 'bold');
title('Gamma functions', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
hold on
plot(cal.gammaInput,cal.gammaTable(:,1:cal.nDevices));
hold off
figure(gcf);
drawnow;

% Option to save the refit file
saveIt = input('Save new fit data? [0]: ');
if (isempty(saveIt))
	saveIt = 0;
end
if (saveIt)
	saveCode = loadCode;
	if (saveCode == 0)
		screenNumber = cal.describe.whichScreen;
		fprintf(1,'\nSaving to screen%g.mat\n',screenNumber);
		SaveCalFile(cal,screenNumber);
	elseif (saveCode == 1)
		fprintf(1,'\nSaving to %s.mat\n',newFileName);
		SaveCalFile(cal,newFileName);
	elseif (saveCode == 2)
		fprintf(1,'\nSaving to default.mat\n');
		SaveCalFile(cal);
	else
		error('Illegal value for save code entered');
	end
end



