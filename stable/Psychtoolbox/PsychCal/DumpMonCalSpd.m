% DumpMonCalSpd
%
% This program reads a standard calibration file and
% reports what is in it.
%
% This version assumes that the calibration file contains
% measured spectral data.  It needs to be made more generic
% so that it can handle tristimulus and luminance calibrations.
%
% 8/22/97  dhb  Wrote it.
% 2/25/98  dhb  Postpend Spd to the name.
% 8/20/00  dhb  Change name to dump.
% 3/1/02   dhb  Arbitrary file names.
% 5/1/02   dhb  Add DUMPALL flag.

% Flags
DUMPALL = 1;

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
	cal_CT = LoadCalFile(whichScreen);
	fprintf('Calibration file read for screen %g\n\n',whichScreen);
elseif (loadCode == 1)
	fprintf(1,'\nLoading from %s.mat\n',newFileName);
	cal_CT = LoadCalFile(newFileName);
	fprintf('Calibration file %s read\n\n',newFileName);
elseif (loadCode == 2)
	fprintf(1,'\nLoading from default.mat\n');
	cal_CT = LoadCalFile;
	fprintf('Read default calibration file %s read\n\n',newFileName);
else
	error('Illegal value for save code entered');
end

% Print out some information from the calibration.
DescribeMonCal(cal_CT);

% Provide information about gamma measurements
% This is probably not method-independent.
fprintf('Gamma measurements were made at %g levels\n',...
	size(cal_CT.rawdata.rawGammaInput,1));
fprintf('Gamma table available at %g levels\n',...
	size(cal_CT.gammaInput,1));
	
% Put up a plot of the essential data
figure(1)
subplot(1,2,1);
plot(SToWls(cal_CT.S_device),cal_CT.P_device);
xlabel('Wavelength (nm)', 'Fontweight', 'bold');
ylabel('Power', 'Fontweight', 'bold');
title('Phosphor spectra', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
axis([380,780,-Inf,Inf]);

subplot(1,2,2);
plot(cal_CT.rawdata.rawGammaInput,cal_CT.rawdata.rawGammaTable,'+');
xlabel('Input value', 'Fontweight', 'bold');
ylabel('Normalized output', 'Fontweight', 'bold');
title('Gamma functions', 'Fontsize', 13, 'Fontname', 'helvetica', 'Fontweight', 'bold');
hold on
plot(cal_CT.gammaInput,cal_CT.gammaTable);
hold off
figure(gcf);
drawnow;

% Plot full spectral data for each phosphor
if (DUMPALL)
	figure(2); clf; 
	figure(3); clf;
	figure(4); clf; hold on
	load T_xyz1931
	ignore = 3;
	T_xyz1931 = SplineCmf(S_xyz1931,T_xyz1931,cal_CT.describe.S);
	
	for i = 1:cal_CT.nDevices
		% Get channel measurements into columns of a matrix from raw data in calibration file.
	  tempMon = reshape(cal_CT.rawdata.mon(:,i),cal_CT.describe.S(3),cal_CT.describe.nMeas);
		
		% Scale each measurement to the maximum spectrum to allow us to compare shapes visually.
		maxSpectrum = tempMon(:,end);
		scaledMon = tempMon;
		for i = 1:cal_CT.describe.nMeas
			scaledMon(:,i) = scaledMon(:,i)*(scaledMon(:,i)\maxSpectrum);
		end
		
		% Compute phosphor chromaticities
		xyYMon = XYZToxyY(T_xyz1931*tempMon);
		
		% Plot raw spectra
		figure(2); clf
		plot(tempMon);
		
		% Plot scaled spectra
		figure(3); clf
		plot(scaledMon(:,ignore+1:end));
		drawnow;
	  monSVs(:,i) = svd(tempMon);
		
		% Plot chromaticities
		figure(4);
		plot(xyYMon(1,ignore+1:end)',xyYMon(2,ignore+1:end)','+');
		
		% Pause to allow look for this channel
		pause;
	end
end

return


