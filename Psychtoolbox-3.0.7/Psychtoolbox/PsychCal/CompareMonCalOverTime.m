% CompareMonCalOverTime
%
% Compare two most recent calibrations of a monitor.
%
% 1/20/05	dhb, bx		Wrote it.

% Enter load code
fprintf(1,'\nLoad codes:\n\t0 - screenX.mat\n\t1 - string.mat\n\t2 - default.mat\n');
loadCode = input('	Enter load code [1]: ');
if (isempty(loadCode))
	loadCode = 1;
end
if (loadCode == 1)
	defaultFileName = 'BitsPlusScreen1';
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
	[cal,cals] = LoadCalFile(whichScreen);
	fprintf('Calibration file read for screen %g\n\n',whichScreen);
elseif (loadCode == 1)
	fprintf(1,'\nLoading from %s.mat\n',newFileName);
	[cal,cals] = LoadCalFile(newFileName);
	fprintf('Calibration file %s read\n\n',newFileName);
elseif (loadCode == 2)
	fprintf(1,'\nLoading from default.mat\n');
	[cal,cals] = LoadCalFile;
	fprintf('Read default calibration file %s read\n\n',newFileName);
else
	error('Illegal value for save code entered');
end

if (length(cals) == 1)
	fprintf('Only one calibration in the file.  Exiting.\n');
end

calNow = cals{end};
calThen = cals{end-1};

fprintf('Comparing calibrations\n');
fprintf('\t%s\n',calThen.describe.date);
fprintf('\t%s\n',calNow.describe.date);

% Plot spectral power distributions
figure; clf; hold on
plot(SToWls(calThen.S_device),calThen.P_device,'r');
plot(SToWls(calNow.S_device),calNow.P_device,'g-');

% Explicitly compute and report ratio of R, G, and B full on spectra
rRatio = calThen.P_device(:,1)\calNow.P_device(:,1);
gRatio = calThen.P_device(:,2)\calNow.P_device(:,2);
bRatio = calThen.P_device(:,3)\calNow.P_device(:,3);
fprintf('Phosphor intensity ratios (now/then): %0.3g, %0.3g, %0.3g\n', ...
	rRatio,gRatio,bRatio);

% Plot gamma functions
figure; clf; hold on
plot(calThen.gammaInput,calThen.gammaTable,'r');
plot(calNow.gammaInput,calNow.gammaTable,'g-');

% Let's print some luminance information
load T_xyzJuddVos;
T_xyz = SplineCmf(S_xyzJuddVos,683*T_xyzJuddVos,calThen.S_device);
lumsThen = T_xyz(2,:)*calThen.P_device;
maxLumThen = sum(lumsThen);
lumsNow = T_xyz(2,:)*calNow.P_device;
maxLumNow = sum(lumsNow);
fprintf('Maximum luminance: then %0.3g; now %0.3g\n',maxLumThen,maxLumNow);
minLumThen = T_xyz(2,:)*calThen.P_ambient;
minLumNow = T_xyz(2,:)*calNow.P_ambient;
fprintf('Minimum luminance: then %0.3g; now %0.3g\n',minLumThen,minLumNow);
