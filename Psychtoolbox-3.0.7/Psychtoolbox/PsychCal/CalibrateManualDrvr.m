% CalibrateManualDrvr
%
% Get some manual measurements from radiometer/photometer.

% 3/8/02  dhb, ly  Wrote it.
% 2/21/03 dhb, ly  Specify input units.

if (USERPROMPT)
	if (cal.describe.whichScreen == 0)
		fprintf('Hit any key to proceed past this message and display a box.\n');
		fprintf('Insert manual photometer/radiometer.\n');
		fprintf('Once meter is set up, hit any key to proceed\n');
		GetChar;
	else
		fprintf('Insert manual photometer/radiometer.\n');
		fprintf('Once meter is set up, hit any key to proceed\n');
	end
end

% Blank other screen
if blankOtherScreen
	[window,screenRect] = OpenWindow(cal.describe.whichBlankScreen,0,[],32);
	SetColor(window,0,[0 0 0]');
end

% Blank screen to be measured
[window,screenRect] = OpenWindow(cal.describe.whichScreen,0,[],32);
if (cal.describe.whichScreen == 0)
	HideCursor;
else
	Screen('MatlabToFront');
end
SetColor(window,0,[0 0 0]');

% Draw a box in the center of the screen
boxRect = [0 0 cal.describe.boxSize cal.describe.boxSize];
boxRect = CenterRect(boxRect,screenRect);
Screen(window,'FillRect',1,boxRect);
SetColor(window,1,[nInputLevels-1 nInputLevels-1 nInputLevels-1]');

% Wait for user
if (USERPROMPT == 1)
  GetChar;
end

% Put correct surround for measurements.
SetColor(window,0,cal.bgColor);

% Put up white
SetColor(window,1,[nInputLevels-1 nInputLevels-1 nInputLevels-1]');
cal.manual.white = [];
while (isempty(cal.manual.white))
	if (cal.manual.photometer)
		cal.manual.white = input('Enter photometer reading (cd/m2): ');
	else
		cal.manual.white = 1e-6*input('Enter radiometer reading (micro Watts): ');
	end
end

SetColor(window,1,[0 0 0]');
cal.manual.black = [];
while (isempty(cal.manual.black))
	if (cal.manual.photometer)
		cal.manual.black = input('Enter photometer reading (cd/m2): ');
	else
		cal.manual.black = 1e-6*input('Enter radiometer reading (micro Watts): ');
	end
end
cal.manual.increment = cal.manual.white - cal.manual.black;

% Close window
CloseWindow(window);
